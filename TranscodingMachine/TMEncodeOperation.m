//
//  TMEncodeOperation.m
//  TranscodingMachine
//
//  Created by Cory Powers on 4/19/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import "TMEncodeOperation.h"
#import "TMAppController.h"
#import "TMTaskManager.h"

NS_ENUM(NSUInteger, TMEncodeOperationState){
	TMEncodeOperationStateInitial,
	TMEncodeOperationStateRunning,
	TMEncodeOperationStateCompleted,
	TMEncodeOperationStateCancelled
};


@interface TMEncodeOperation () 
@property (nonatomic, strong) NSManagedObjectID *taskModelID;
@property (nonatomic, strong) NSManagedObjectID *mediaItemModelID;
@property (nonatomic, strong) NSString *inputFile;
@property (nonatomic, strong) NSString *outputFile;
@property (nonatomic, strong) NSString *statusFile;
@property (nonatomic, strong) NSTask *encodingTask;
@property (nonatomic, strong) NSTimer *encodeTimer;
@property (nonatomic, strong) NSFileHandle *statusFileHandle;
@property (nonatomic, assign) enum TMEncodeOperationState state;

@property (nonatomic, weak) id<TMEncodeOperationDelegate> delegate;
@property (nonatomic, assign) CGFloat encodeProgress;
@property (nonatomic, strong) NSString *encodeETA;

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) BOOL keepRunning;

- (void) setTaskStatus: (NSInteger)statusCode;
- (void) removeStatusFile;
- (void) encodeTimerFired:(NSTimer*)theTimer;
- (void) taskEnded: (NSTask *)theTask;
- (void) setMediaItemLog: (NSString *)message;
- (void) endOperationWithStatus: (NSInteger)statusCode;
@end

@implementation TMEncodeOperation
- (id)initWithEncodeTask:(TMEncodeTaskModel *)aTask {
	return [self initWithEncodeTask:aTask andDelegate:nil];
}

- (id)initWithEncodeTask: (TMEncodeTaskModel *)aTask andDelegate: (id<TMEncodeOperationDelegate>)aDelegate{
	self = [super init];
	
	if (self) {
		self.delegate = aDelegate;
		self.inputFile = aTask.mediaItem.input;
		self.outputFile = aTask.mediaItem.output;
		self.taskModelID = [aTask permanentObjectID];
		self.mediaItemModelID = [aTask.mediaItem permanentObjectID];
		self.state = TMEncodeOperationStateInitial;
		self.keepRunning = YES;
	}
	
	return self;
}

- (void)start {
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isReady"];
	self.state = TMEncodeOperationStateRunning;
	[self didChangeValueForKey:@"isReady"];
	[self didChangeValueForKey:@"isExecuting"];
	
	[self setTaskStatus:1];
	
	self.operationQueue = [NSOperationQueue currentQueue];
	
	NSString *tempPattern = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TMEncode.XXXXXX"];
	char *tempCString = mktemp((char *)[tempPattern cStringUsingEncoding:NSUTF8StringEncoding]);
	self.statusFile = [NSString stringWithCString:tempCString encoding:NSUTF8StringEncoding];
	
	NSLog(@"Creating status file at %@", self.statusFile);

	if (![[NSFileManager defaultManager] createFileAtPath:self.statusFile contents:nil attributes:nil]) {
		NSLog(@"Could not create file at %@", self.statusFile);
		[self endOperationWithStatus:-5];
		return;
	}
	
	self.encodeProgress = 0.0;
	
	// make task object
	self.encodingTask = [[NSTask alloc] init];
	// make stdout file
	NSFileHandle *taskStdout = [NSFileHandle fileHandleForWritingAtPath:self.statusFile];
	
	[self.encodingTask setStandardOutput:taskStdout];
	[self.encodingTask setStandardError:taskStdout];
	
	
    // set arguments
	NSString *argString = [[NSUserDefaults standardUserDefaults] stringForKey:@"transcoderArgs"];
	NSArray *argArray = [argString componentsSeparatedByString:@" "];
    NSMutableArray *taskArgs = [NSMutableArray array];
	for(NSString *inputArg in argArray){
		if ([inputArg isEqual:@"|INPUT|"]) {
			[taskArgs addObject: self.inputFile];
		}else if ([inputArg isEqual:@"|OUTPUT|"]) {
			[taskArgs addObject: self.outputFile];
		}else{
			[taskArgs addObject:inputArg];
		}
	}
	NSLog(@"Starting encode task with arguments: %@", [taskArgs componentsJoinedByString:@" "]);
    [self.encodingTask setArguments:taskArgs];
	
	__weak TMEncodeOperation *weakSelf = self;
	[self.encodingTask setTerminationHandler:^(NSTask *aTask) {
		[weakSelf taskEnded: aTask];
	}];
	
	// launch
    [self.encodingTask setLaunchPath:[[NSUserDefaults standardUserDefaults] stringForKey:@"transcoderPath"]];
    [self.encodingTask launch];

	// Check to make sure there wasn't an immediate failure
	if (self.encodingTask && [self.encodingTask isRunning]) {
		// Store the pid in case we die
		NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
		[standardDefaults setObject:@([self.encodingTask processIdentifier]) forKey:@"encodePid"];
		
//		[queueController updateEncodeProgress:0.0 withEta:nil ofItem:[self encodingItem]];
//		// Setup the timer and status file
		self.encodeTimer = [NSTimer timerWithTimeInterval:2 target:self selector:@selector(encodeTimerFired:) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:self.encodeTimer forMode:NSRunLoopCommonModes];

		self.statusFileHandle = [NSFileHandle fileHandleForReadingAtPath:self.statusFile];
		
	}

//	NSRunLoop *theRL = [NSRunLoop currentRunLoop];
//	while (self.keepRunning && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void) encodeTimerFired:(NSTimer*)theTimer {
	NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
		// Read the last line
		NSLog(@"Output read timer fired");
		NSString *fileData = [[NSString alloc] initWithData:[self.statusFileHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
		NSArray *lines = [fileData componentsSeparatedByString:@"\r"];
		NSLog(@"Found %ld lines", (unsigned long)[lines count]);
		NSString *lastLine = lines[[lines count] - 1];
		NSLog(@"Last line: %@", lastLine);
		
		// Extract required info from last line
		NSString *encodeProgressString;
		NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
		
		NSString* regexString = @".*, (\\d+.\\d+) %.*ETA ([\\dhms]+).*";
		NSRegularExpressionOptions options = NSRegularExpressionCaseInsensitive;
		NSMatchingOptions matchOptions = NSMatchingReportCompletion;
		NSError* error;
		
		NSRegularExpression* progressRegex = [NSRegularExpression regularExpressionWithPattern:regexString options:options error:&error];
		if (error) {
			NSLog(@"Error setting up regex: %@", error.localizedDescription);
		}
		
		self.encodeProgress = 0.0;
		self.encodeETA = @"--h--m--s";
		NSTextCheckingResult *firstMatch = [progressRegex firstMatchInString:lastLine options:matchOptions range:NSMakeRange(0, lastLine.length)];
		if (firstMatch.range.location != NSNotFound) {
			NSRange progressStringRange = [firstMatch rangeAtIndex:1];
			NSRange encodeETARange = [firstMatch rangeAtIndex:2];
			if (progressStringRange.location != NSNotFound && encodeETARange.location != NSNotFound) {
				encodeProgressString = [lastLine substringWithRange:progressStringRange];
				self.encodeProgress = [[formatter numberFromString:encodeProgressString] doubleValue];
				self.encodeETA = [lastLine substringWithRange:encodeETARange];
//				[queueController updateEncodeProgress:encodeProgress withEta:encodeETA ofItem:[self encodingItem]];
				NSLog(@"Current progress %f, eta %@", self.encodeProgress, self.encodeETA);
			}else{
				NSLog(@"Could not determine progress from line: %@", lastLine);
			}
		}else{
			NSLog(@"Could not determine progress from line: %@", lastLine);
		}
		
		if(self.delegate){
			dispatch_async(dispatch_get_main_queue(), ^{
				TMMediaItem *mediaItem = (TMMediaItem *)[[TMMediaItem mainQueueContext] existingObjectWithID:self.mediaItemModelID error:nil];
				[self.delegate encodeOperation:self updateProgress:self.encodeProgress withETA:self.encodeETA ofItem:mediaItem];
			});
		}
	}];
	
	[[TMTaskManager sharedManager] runSecondaryOperation:blockOperation];
}

- (void) taskEnded: (NSTask *)theTask {
	int status = [self.encodingTask terminationStatus];
	
//	TMEncodeTaskModel *currentItem = [self encodingItem];
	NSLog(@"The encoding task has stopped");
	BOOL encodeSucceeded = NO;
	if (status == 0){
		// See if output file exists. Sometimes handbrake exits with 0 code without working
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if ([fileManager fileExistsAtPath: self.outputFile]){
			encodeSucceeded = YES;
			NSLog(@"Task succeeded.");
		}
	}
	
	// Clear out our cached encode pid
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
	[standardDefaults setObject:@0 forKey:@"encodePid"];
	
	
	// Update the queue item's status
	//		[queueController encodeEnded];
	
	// Clean up
	[self.encodeTimer invalidate];
	self.encodeTimer = nil;
	
	if (encodeSucceeded == YES) {
		dispatch_async(dispatch_get_main_queue(), ^{
			TMMediaItem *mediaItem = (TMMediaItem *)[[TMMediaItem mainQueueContext] existingObjectWithID:self.mediaItemModelID error:nil];
			[[TMTaskManager sharedManager] tagMediaItem:mediaItem];
		});
		[self setTaskStatus:255];
	}else {
		NSFileHandle *logHandle = [NSFileHandle fileHandleForReadingAtPath:self.statusFile];
		NSString *fileData = [[NSString alloc] initWithData:[logHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];

		[self setTaskStatus:3];
		
		[self setMediaItemLog:fileData];
	}

	[self removeStatusFile];
	
	if (self.delegate) {
		dispatch_async(dispatch_get_main_queue(), ^{
			TMMediaItem *mediaItem = (TMMediaItem *)[[TMMediaItem mainQueueContext] existingObjectWithID:self.mediaItemModelID error:nil];
			[self.delegate encodeOperationFinished:self forItem:mediaItem];
		});
	}
	
	[self willChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	self.state = TMEncodeOperationStateCompleted;
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isFinished {
	return self.state == TMEncodeOperationStateCompleted || self.state == TMEncodeOperationStateCancelled;
}

- (BOOL)isExecuting {
	return self.state == TMEncodeOperationStateRunning;
}

- (BOOL)isCancelled {
	return self.state == TMEncodeOperationStateCancelled;
}

- (BOOL)isReady {
	return self.state == TMEncodeOperationStateInitial && [super isReady];;
}

- (void)cancel {
	[self endOperationWithStatus:-4];
}

- (void) endOperationWithStatus: (NSInteger)statusCode {
	if (self.encodingTask && [self.encodingTask isRunning]) {
		[self.encodingTask terminate];
	}
	
	if (self.encodeTimer) {
		[self.encodeTimer invalidate];
		self.encodeTimer = nil;
	}
	
	[self setTaskStatus:statusCode];
	
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isReady"];
	self.state = TMEncodeOperationStateCompleted;
	[self didChangeValueForKey:@"isReady"];
	[self didChangeValueForKey:@"isExecuting"];
}

- (void) removeStatusFile {
	NSError *error;
	// Clean up old status file
	NSFileManager *defaultManger = [NSFileManager defaultManager];
	if ([defaultManger fileExistsAtPath:self.statusFile]) {
		[defaultManger removeItemAtPath:self.statusFile error:&error];
	}
}

- (void) setTaskStatus: (NSInteger)statusCode {
	if (self.taskModelID) {
		// Set the task status
		dispatch_async(dispatch_get_main_queue(), ^{
			TMEncodeTaskModel *taskModel = (TMEncodeTaskModel *)[[TMEncodeTaskModel mainQueueContext] existingObjectWithID:self.taskModelID error:nil];
			taskModel.status = @(statusCode);
		});
	}
}

- (void) setMediaItemLog: (NSString *)message {
	if (self.mediaItemModelID) {
		// Set the task status
		dispatch_async(dispatch_get_main_queue(), ^{
			TMMediaItem *mediaItem = (TMMediaItem *)[[TMMediaItem mainQueueContext] existingObjectWithID:self.mediaItemModelID error:nil];
			mediaItem.message = message;
		});
	}
}

@end
