//
//  TMTaskManager.m
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/16/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import "TMTaskManager.h"
#import "TMUnrarOperation.h"
#import "TMMetadataOperation.h"
#import "TMEncodeOperation.h"
#import "TMAppController.h"
#import "TMEncoderQueue.h"
#import "TMTagTaskModel.h"
#import "TMTagOperation.h"

#import <MediaFinderPlugin/MediaFinderPlugin.h>

@interface TMTaskManager ()
@property (nonatomic, strong) NSOperationQueue *unrarQueue;
@property (nonatomic, strong) NSOperationQueue *metadataQueue;
@property (nonatomic, strong) TMEncoderQueue *encodeQueue;
@property (nonatomic, strong) NSOperationQueue *secondaryQueue;

@end

@implementation TMTaskManager
static TMTaskManager *instance;
- (id)init{
	self = [super init];
	if (self) {
		self.unrarQueue = [[NSOperationQueue alloc] init];
		[self.unrarQueue setMaxConcurrentOperationCount:3];
		self.metadataQueue = [[NSOperationQueue alloc] init];
		[self.metadataQueue setMaxConcurrentOperationCount:NSIntegerMax];
		self.encodeQueue = [[TMEncoderQueue alloc] init];
		self.secondaryQueue = [[NSOperationQueue alloc] init];
		[self.secondaryQueue setMaxConcurrentOperationCount:NSIntegerMax];
	}
	return self;
}

+ (TMTaskManager *)sharedManager {
	static dispatch_once_t pred;
	
	dispatch_once(&pred, ^{
		instance = [[TMTaskManager alloc] init];
	});

	return instance;
}
- (void)setDelegate:(id<TMEncodeOperationDelegate>)delegate {
	if (delegate != _delegate) {
		_delegate = delegate;
		self.encodeQueue.delegate = delegate;
	}
}

- (void) runUnrarTask: (TMUnrarTaskModel *)aTask{
	TMUnrarOperation *anOperation = [[TMUnrarOperation alloc] initWithUnrarTask:aTask];

	[self.unrarQueue addOperation:anOperation];
}

- (void)runMetadataTask:(TMMetadataTaskModel *)aTask {
	TMAppController *appController = (TMAppController *)[[NSApplication sharedApplication] delegate];
	TMMetadataOperation *anOperation = [[TMMetadataOperation alloc] initWithMetadataTask:aTask andProvider:appController.infoProvider];
	
	[self.metadataQueue addOperation:anOperation];
}

- (void) runEncodeTask: (TMEncodeTaskModel *)aTask withDelegate: (id<TMEncodeOperationDelegate>)aDelegate {
//	TMEncodeOperation *anOperation = [[TMEncodeOperation alloc] initWithEncodeTask:aTask andDelegate:aDelegate] ;
//	
//	[self.encodeQueue addOperation:anOperation];
}

- (void) cancelRunningEncodeTask {
	if (self.encodeQueue.runningEncode){
		[self.encodeQueue.runningEncode cancel];
	}
}

- (void) suspendEncoding {
	[self.encodeQueue setSuspended:YES];
	
	[self.encodeQueue stopQueue];
}

- (void) resumeEncoding {
	[self.encodeQueue setSuspended:NO];
	
	[self.encodeQueue runQueue];
}

- (void) tagMediaItem: (TMMediaItem *)anItem {
	TMTagTaskModel *aTagModel = [[TMTagTaskModel alloc] init];
	aTagModel.mediaItem = anItem;
	
	TMTagOperation *anOperation = [[TMTagOperation alloc] initWithTagTask:aTagModel];
	[self runSecondaryOperation:anOperation];
}

- (void) runSecondaryOperation: (NSOperation *)anOperation {
	[self.secondaryQueue addOperation:anOperation];
}

- (void) loadImageForProxy: (MFPImageProxy *)aProxy withCompletionHandler: (TMTaskManagerLoadImageCompleteBlock)completionHandler {
	NSBlockOperation *anOperation = [NSBlockOperation blockOperationWithBlock:^{
		[aProxy loadImageWithCompletionBlock:^(MFPImageProxy *aProxy, NSImage *anImage) {
			dispatch_async(dispatch_get_main_queue(), ^{
				completionHandler(aProxy);
			});
		}];
		
	}];
	
	[self.secondaryQueue addOperation:anOperation];
}
@end
