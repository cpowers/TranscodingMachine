// 
//  MediaItem.m
//  TranscodingMachine
//
//  Created by Cory Powers on 3/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TMMediaItem.h"
#import "TMEncodeTaskModel.h"
#import "TMTagTaskModel.h"
#import "TMMetadataTaskModel.h"

@implementation TMMediaItem 

@dynamic showName;
@dynamic releaseDate;
@dynamic message;
@dynamic output;
@dynamic type;
@dynamic coverArt;
@dynamic episode;
@dynamic season;
@dynamic input;
@dynamic hdVideo;
@dynamic longDescription;
@dynamic summary;
@dynamic network;
@dynamic title;
@dynamic copyright;
@dynamic genre;

@dynamic tagTask;
@dynamic encodeTask;
@dynamic metadataTask;

-(NSString *)shortName{
	NSString *shortName = [[self input] lastPathComponent];
	if ([[self type] intValue] == ItemTypeTV && ![[self showName] isEqualToString:@""]) {
		shortName = [NSString stringWithFormat:@"%@ S%.2dE%.2d", [self showName], [[self season] intValue], [[self episode] intValue]];
	}else if([[self type] intValue] == ItemTypeMovie && ![[self title] isEqualToString:@""]) {
		shortName = [self title];
	}
	
	return shortName;
}

-(NSString *)episodeId{
	if ([self.type isEqualToNumber:@ItemTypeTV]) {
		return [NSString stringWithFormat:@"%d%.2d", [[self season] intValue], [[self episode] intValue]];
	}
	return [NSString string];
}

- (NSImage *)coverArtImage {
	if (self.coverArt) {
		return [[NSImage alloc] initWithData:self.coverArt];
	}
	
	return nil;
}

- (NSString *)releaseDateString {
	if (self.releaseDate) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%b %d %Y" allowNaturalLanguage:YES];
		return [dateFormatter stringFromDate:self.releaseDate];
	}
	
	return @"Uknown release";
}

+ (NSSet *)keyPathsForValuesAffectingShortName {
    return [NSSet setWithObjects:@"season", @"episode", @"showName", @"title", nil];
}

+ (NSSet *)keyPathsForValuesAffectingReleaseDateString {
	return [NSSet setWithObject:@"releaseDate"];
}

+ (NSSet *)keyPathsForValuesAffectingCoverArtImage {
	return [NSSet setWithObject:@"coverArt"];
}
@end
