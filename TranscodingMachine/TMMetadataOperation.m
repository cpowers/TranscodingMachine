//
//  TMMetadataOperation.m
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/17/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import "TMMetadataOperation.h"
#import "TMAppController.h"
#import "TMTaskManager.h"

NS_ENUM(NSUInteger, TMMetadataOperationState){
	TMMetadataOperationStateInitial,
	TMMetadataOperationStateRunning,
	TMMetadataOperationStateLoadingImage,
	TMMetadataOperationStateCompleted,
	TMMetadataOperationStateCancelled
};


@interface TMMetadataOperation ()
@property (nonatomic, strong) NSManagedObjectID *taskModelID;
@property (nonatomic, strong) NSManagedObjectID *mediaItemModelID;
@property (nonatomic, strong) NSString *showName;
@property (nonatomic, strong) NSNumber *season;
@property (nonatomic, strong) NSNumber *episode;
@property (nonatomic, assign) enum TMMetadataOperationState state;
@property (nonatomic, strong) MFPInfoProvider *provider;

- (void) setTaskStatus: (NSInteger)statusCode;
- (void) populateShowDetails: (MFPTVShow *)aShow;
- (void) populateEpisodeDetailsFromShow: (MFPTVShow *)aShow andEpisode: (MFPTVShowEpisode *)anEpisode;
@end


@implementation TMMetadataOperation

- (id)initWithMetadataTask: (TMMetadataTaskModel *)aTask andProvider: (MFPInfoProvider *)aProvider {
	self = [super init];
	
	if (self) {
		self.provider = aProvider;
		self.showName = aTask.mediaItem.showName;
		self.season = aTask.mediaItem.season;
		self.episode = aTask.mediaItem.episode;
		self.taskModelID = [aTask permanentObjectID];
		self.mediaItemModelID = [aTask.mediaItem permanentObjectID];
		self.state = TMMetadataOperationStateInitial;
	}
	
	return self;	
}

- (void)start {
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isReady"];
	self.state = TMMetadataOperationStateRunning;
	[self didChangeValueForKey:@"isReady"];
	[self didChangeValueForKey:@"isExecuting"];
	
	[self setTaskStatus:1];
	
	NSLog(@"Downloading show %@ S%@ E%@", self.showName, self.season, self.episode);
	
	if (self.showName == nil || self.season == nil || self.episode == nil) {
		[self setTaskStatus:-10];
		
		[self willChangeValueForKey:@"isFinished"];
		[self willChangeValueForKey:@"isExecuting"];
		self.state = TMMetadataOperationStateCompleted;
		[self didChangeValueForKey:@"isExecuting"];
		[self didChangeValueForKey:@"isFinished"];
		
		return;
	}
	
	[self.provider searchTVShows:self.showName withCompletionHandler:^(MFPInfoProvider *aProvider, NSString *searchTerm, NSArray *matchingShows) {
		if (matchingShows.count == 0) {
			[self setTaskStatus:-10];
			
			[self willChangeValueForKey:@"isFinished"];
			[self willChangeValueForKey:@"isExecuting"];
			self.state = TMMetadataOperationStateCompleted;
			[self didChangeValueForKey:@"isExecuting"];
			[self didChangeValueForKey:@"isFinished"];

			return;
		}
		MFPTVShow *aShow = [matchingShows objectAtIndex:0];
		NSLog(@"Found Show for search %@: %@", searchTerm, aShow);
		[self populateShowDetails:aShow];
		
		[self.provider loadEpisodeForShow:aShow seasonNumber:[self.season integerValue] episodeNumber:[self.episode integerValue] withCompletionHandler:^(MFPInfoProvider *aProvider, NSInteger seasonNumber, NSInteger episodeNumber, MFPTVShow *aShow, MFPTVShowEpisode *anEpisode) {
			
			if (!anEpisode) {
				[self setTaskStatus:-11];
				
				[self willChangeValueForKey:@"isFinished"];
				[self willChangeValueForKey:@"isExecuting"];
				self.state = TMMetadataOperationStateCompleted;
				[self didChangeValueForKey:@"isExecuting"];
				[self didChangeValueForKey:@"isFinished"];

				return;
			}
            
            NSAssert(anEpisode.season != nil, @"Season should not be nil");
			
            [self populateEpisodeDetailsFromShow:aShow andEpisode:anEpisode];

			NSLog(@"Found episode for season %ld and episode %ld: %@", seasonNumber, episodeNumber, anEpisode);
			
			if (self.state == TMMetadataOperationStateRunning) {
				[self setTaskStatus:255];
				
				// We didn't have to load the image from the network so finish up right here
				[self willChangeValueForKey:@"isFinished"];
				[self willChangeValueForKey:@"isExecuting"];
				self.state = TMMetadataOperationStateCompleted;
				[self didChangeValueForKey:@"isExecuting"];
				[self didChangeValueForKey:@"isFinished"];
			}

		}];
	}];
}

- (BOOL)isConcurrent {
	return YES;
}

- (BOOL)isFinished {
	return self.state == TMMetadataOperationStateCompleted || self.state == TMMetadataOperationStateCancelled;
}

- (BOOL)isExecuting {
	return self.state == TMMetadataOperationStateRunning;
}

- (BOOL)isCancelled {
	return self.state == TMMetadataOperationStateCancelled;
}

- (BOOL)isReady {
	return self.state == TMMetadataOperationStateInitial && [super isReady];;
}

- (void) setTaskStatus: (NSInteger)statusCode {
	if (self.taskModelID) {
		// Set the task status
		dispatch_async(dispatch_get_main_queue(), ^{
			TMMetadataTaskModel *taskModel = (TMMetadataTaskModel *)[[TMMetadataTaskModel mainQueueContext] existingObjectWithID:self.taskModelID error:nil];
			taskModel.status = @(statusCode);
		});
	}
}

- (void) populateShowDetails: (MFPTVShow *)aShow {
	if (self.mediaItemModelID) {
		// Set the task status
		dispatch_async(dispatch_get_main_queue(), ^{
			TMMediaItem *mediaItem = (TMMediaItem *)[[TMMediaItem mainQueueContext] existingObjectWithID:self.mediaItemModelID error:nil];
			mediaItem.showName = aShow.name;
			mediaItem.longDescription = aShow.overview;
			mediaItem.genre = aShow.genre;
		});
	}
}

- (void) populateEpisodeDetailsFromShow: (MFPTVShow *)aShow andEpisode: (MFPTVShowEpisode *)anEpisode {
	if (self.mediaItemModelID) {
		// Set the task status
		dispatch_async(dispatch_get_main_queue(), ^{
			TMMediaItem *mediaItem = (TMMediaItem *)[[TMMediaItem mainQueueContext] existingObjectWithID:self.mediaItemModelID error:nil];
			mediaItem.episode = anEpisode.number;
			mediaItem.season = anEpisode.season.number;
			mediaItem.summary = anEpisode.summary;
			mediaItem.releaseDate = anEpisode.firstAired;
			mediaItem.title = anEpisode.title;

            // need to hold a reference to aShow so set this here too.
            mediaItem.showName = aShow.name;

            NSAssert(mediaItem.season != nil, @"Season number should not be nil");
            NSAssert([mediaItem.season integerValue] != 0, @"Season number should not be 0");

			if (anEpisode.art.hasImage) {
				mediaItem.coverArt = [anEpisode.art.image TIFFRepresentation];
			}else{
				// Since we have to go to the network for the image we will handle finishing this operation when its done
				self.state = TMMetadataOperationStateLoadingImage;
				
				[[TMTaskManager sharedManager] loadImageForProxy:anEpisode.art withCompletionHandler:^(MFPImageProxy *aProxy) {
					mediaItem.coverArt = [aProxy.image TIFFRepresentation];
					
					[self setTaskStatus:255];
					
					[self willChangeValueForKey:@"isFinished"];
					[self willChangeValueForKey:@"isExecuting"];
					self.state = TMMetadataOperationStateCompleted;
					[self didChangeValueForKey:@"isExecuting"];
					[self didChangeValueForKey:@"isFinished"];
				}];
			}
		});
	}	
}

@end
