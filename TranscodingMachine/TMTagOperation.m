//
//  TMTagOperation.m
//  TranscodingMachine
//
//  Created by Cory Powers on 5/10/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import "TMTagOperation.h"
#import "TMMediaItem.h"
#import <TagLibKit/TagLibKit.h>

NS_ENUM(NSUInteger, TMTagOperationState){
	TMTagOperationStateInitial,
	TMTagOperationStateRunning,
	TMTagOperationStateLoadingImage,
	TMTagOperationStateCompleted,
	TMTagOperationStateCancelled
};

@interface TMTagOperation ()
@property (nonatomic, strong) NSManagedObjectID *taskModelID;
@property (nonatomic, strong) NSManagedObjectID *mediaItemModelID;
@property (nonatomic, assign) enum TMTagOperationState state;
@property (nonatomic, strong) TKFile *tagLibFile;
@property (nonatomic, strong) NSString *outputFilePath;

- (void) populateTaglib;
- (void) setTaskStatus: (NSInteger)statusCode;
@end

@implementation TMTagOperation

- (id)initWithTagTask: (TMTagTaskModel *)aTask {
	self = [super init];
	
	if (self) {
		self.taskModelID = [aTask permanentObjectID];
		self.mediaItemModelID = [aTask.mediaItem permanentObjectID];
		self.state = TMTagOperationStateInitial;
		self.outputFilePath = aTask.mediaItem.output;
	}
	
	return self;
}

- (void)start {
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isReady"];
	self.state = TMTagOperationStateRunning;
	[self didChangeValueForKey:@"isReady"];
	[self didChangeValueForKey:@"isExecuting"];
	
	[self setTaskStatus:1];
	
	self.tagLibFile = [[TKFile alloc] initWithFile:self.outputFilePath];
	
	// Read the metadata settings from the media item
	[self populateTaglib];
	
	[self.tagLibFile writeTags];

	[self setTaskStatus:255];
	
	[self willChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	self.state = TMTagOperationStateCompleted;
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];

}

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isFinished {
	return self.state == TMTagOperationStateCompleted || self.state == TMTagOperationStateCancelled;
}

- (BOOL)isExecuting {
	return self.state == TMTagOperationStateRunning;
}

- (BOOL)isCancelled {
	return self.state == TMTagOperationStateCancelled;
}

- (BOOL)isReady {
	return self.state == TMTagOperationStateInitial && [super isReady];;
}

- (void) setTaskStatus: (NSInteger)statusCode {
	if (self.taskModelID) {
		// Set the task status
		dispatch_async(dispatch_get_main_queue(), ^{
			TMTagTaskModel *taskModel = (TMTagTaskModel *)[[TMTagTaskModel mainQueueContext] existingObjectWithID:self.taskModelID error:nil];
			taskModel.status = @(statusCode);
		});
	}
}

- (void) populateTaglib {
	if (self.mediaItemModelID) {
		// Set the task status
		TKFile *blockTaglibFile = self.tagLibFile;
		dispatch_sync(dispatch_get_main_queue(), ^{
			TMMediaItem *mediaItem = (TMMediaItem *)[[TMMediaItem mainQueueContext] existingObjectWithID:self.mediaItemModelID error:nil];
			blockTaglibFile.showName = mediaItem.showName;
			blockTaglibFile.showDescription = mediaItem.longDescription;
			blockTaglibFile.episodeDescription = mediaItem.summary;
			blockTaglibFile.season = [mediaItem.season unsignedIntegerValue];
			blockTaglibFile.episode = [mediaItem.episode unsignedIntegerValue];
			blockTaglibFile.releaseDate = mediaItem.releaseDate;
			blockTaglibFile.hdVideo = [mediaItem.hdVideo boolValue];
			blockTaglibFile.title = mediaItem.title;
			blockTaglibFile.copyright = mediaItem.copyright;
			blockTaglibFile.network = mediaItem.network;
			blockTaglibFile.coverArt = mediaItem.coverArtImage;
			blockTaglibFile.genre = mediaItem.genre;
			blockTaglibFile.episodeID = mediaItem.episodeId;
			if ([mediaItem.type intValue] == ItemTypeTV) {
				blockTaglibFile.mediaType = TKMediaTypeTVShow;
			}else if ([mediaItem.type intValue] == ItemTypeMovie) {
				blockTaglibFile.mediaType = TKMediaTypeMovie;
			}
		});
	}
}
@end
