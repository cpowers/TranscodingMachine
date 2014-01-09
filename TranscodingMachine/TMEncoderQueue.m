//
//  TMEncoderQueue.m
//  TranscodingMachine
//
//  Created by Cory Powers on 4/21/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import "TMEncoderQueue.h"
#import "TMEncodeTaskModel.h"
#import "TMEncodeOperation.h"
#import "TMMediaItem.h"

@interface TMEncoderQueue ()
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;
@property (nonatomic, strong) TMEncodeOperation *runningEncode;

@end

@implementation TMEncoderQueue
@synthesize suspended = _suspended;

- (id)init {
	self = [super init];
	if (self) {
		self.dispatchQueue = dispatch_queue_create("TMEncoderqueue", DISPATCH_QUEUE_CONCURRENT);
		self.suspended = YES;
	}
	
	return self;
}

- (void) runQueue {
	dispatch_async(self.dispatchQueue, ^{
		[self runNextEncode];
	});
}

- (void) stopQueue {	
	if (self.runningEncode) {
		[self.runningEncode cancel];
	}
}

- (void) runNextEncode {
	if (self.runningEncode && [self.runningEncode isExecuting]) {
		return;
	}
	
	__block TMEncodeOperation *anOperation;
	dispatch_sync(dispatch_get_main_queue(), ^{
		// Go to the main thread to pull the CD object and populate into thread safe TMEncodeOperation
		NSManagedObjectContext *moc = [TMMediaItem mainQueueContext];
		NSFetchRequest *request = [[NSFetchRequest alloc] init] ;
		NSEntityDescription *entity = [TMMediaItem entity];

		[request setEntity: entity];
		NSPredicate *condition = [NSPredicate predicateWithFormat:@"encodeTask.status = 0"];
		[request setPredicate:condition];
//		[request setFetchLimit:1];
		NSSortDescriptor *sortOrder = [[NSSortDescriptor alloc]
									   initWithKey: @"encodeTask.sortOrder" ascending:YES] ;
		NSArray *sortDescriptors = @[sortOrder];
		[request setSortDescriptors: sortDescriptors];
		NSError *anyError;
		NSArray *fetchedObjects = [moc executeFetchRequest: request
													 error: &anyError] ;
		
		for (TMMediaItem *mediaItem in fetchedObjects) {
			if (mediaItem.input && mediaItem.output) {
				anOperation = [[TMEncodeOperation alloc] initWithEncodeTask:mediaItem.encodeTask andDelegate:self.delegate];
				break;
			}else{
				// Some jacked up media item
				mediaItem.encodeTask.status = @(255);
			}
		}
	});
	
	if (!anOperation) {
		// Nothing to do
		return;
	}
	
	// Kick off the operation
	if (![self startEncodeOperation:anOperation]) {
		// Run a different operation
		[self runNextEncode];
	}
}

- (BOOL) startEncodeOperation: (TMEncodeOperation *)anOperation{
	BOOL ranIt = NO;
	
	
	if ([anOperation isReady] && ![anOperation isCancelled]) {
		self.runningEncode = anOperation;
		[self.runningEncode addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionInitial context:nil];
		
		dispatch_async(self.dispatchQueue, ^{
			[anOperation start];
		});
		ranIt = YES;
	}
	
	return ranIt;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == self.runningEncode && [keyPath isEqualToString:@"isFinished"]) {
		if ([self.runningEncode isFinished]) {
			self.runningEncode = nil;
			if (!self.suspended) {
				[self runQueue];
			}
		}
	}
}
@end
