//
//  TMUnrarOperation.m
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/16/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import "TMUnrarOperation.h"
#import <RarKit/RarKit.h>
#import "TMAppController.h"

NS_ENUM(NSUInteger, TMUnrarOperationState){
	TMUnrarOperationStateInitial,
	TMUnrarOperationStateRunning,
	TMUnrarOperationStateCompleted,
	TMUnrarOperationStateCancelled
};


@interface TMUnrarOperation () <RKRarArchiveDelegate>
@property (nonatomic, strong) NSManagedObjectID *taskModelID;
@property (nonatomic, assign) enum TMUnrarOperationState state;
@property (nonatomic, strong) NSMutableData *data;

- (void) setTaskStatus: (NSInteger)statusCode;

@end

@implementation TMUnrarOperation

- (id)initWithUnrarTask:(TMUnrarTaskModel *)aTask {
	self = [super init];
	
	if (self) {
		self.rarFilePath = aTask.rarFile;
		self.taskModelID = [aTask permanentObjectID];
		self.state = TMUnrarOperationStateInitial;
	}
	
	return self;
}

- (void)start {
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isReady"];
	self.state = TMUnrarOperationStateRunning;
	[self didChangeValueForKey:@"isReady"];
	[self didChangeValueForKey:@"isExecuting"];
	
	[self setTaskStatus:1];
	
	self.data = [NSMutableData dataWithCapacity:1000];
	
	RKRarArchive *archive = [[RKRarArchive alloc] initWithArchiveFile:self.rarFilePath];
	NSArray *outputFiles = [archive listOutputFiles];
	NSString *outputFile = [outputFiles lastObject];
	
	[archive extractFile:outputFile withDelegate:self];
}

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isFinished {
	return self.state == TMUnrarOperationStateCompleted || self.state == TMUnrarOperationStateCancelled;
}

- (BOOL)isExecuting {
	return self.state == TMUnrarOperationStateRunning;
}

- (BOOL)isCancelled {
	return self.state == TMUnrarOperationStateCancelled;
}

- (BOOL)isReady {
	return self.state == TMUnrarOperationStateInitial && [super isReady];;
}

- (void) setTaskStatus: (NSInteger)statusCode {
	if (self.taskModelID) {
		// Set the task status
		dispatch_async(dispatch_get_main_queue(), ^{
			TMUnrarTaskModel *taskModel = (TMUnrarTaskModel *)[[TMUnrarTaskModel mainQueueContext] existingObjectWithID:self.taskModelID error:nil];
			taskModel.status = @(statusCode);
		});
	}
}

- (void)rarArchive:(RKRarArchive *)anArchive extractFile:(NSString *)aFile extractedBytes:(NSData *)data totalBytesExpected:(long long)totalBytes {
	[self.data appendData:data];
	NSLog(@"Extracted %ld of %lld", (unsigned long)self.data.length, totalBytes);
}

- (void)rarArchive:(RKRarArchive *)anArchive extractFile:(NSString *)aFile failedWithError:(NSError *)anError {
	[self setTaskStatus:-10];

	[self willChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	self.state = TMUnrarOperationStateCompleted;
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
}

- (void)rarArchive:(RKRarArchive *)anArchive completedFile:(NSString *)aFile {
	NSString *outputPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"monitoredFolder"];
	NSString *outputFile = [outputPath stringByAppendingPathComponent:aFile];
	
	if([[NSFileManager defaultManager] createFileAtPath:outputFile contents:self.data attributes:nil]) {
		[self setTaskStatus:255];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			TMAppController *appController = [[NSApplication sharedApplication] delegate];
			[appController addItem:outputFile error:nil];
		});
	}else{
		NSLog(@"Error saving file %@ to %@", aFile, outputPath);
		[self setTaskStatus:-5];
	}

	[self willChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	self.state = TMUnrarOperationStateCompleted;
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
}
@end
