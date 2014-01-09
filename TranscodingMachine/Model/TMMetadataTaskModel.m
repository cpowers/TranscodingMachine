//
//  TMMetadataTaskModel.m
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/17/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import "TMMetadataTaskModel.h"
#import "TMMediaItem.h"


@implementation TMMetadataTaskModel

@dynamic mediaItem;

- (NSString *)description {
	if (self.mediaItem && self.mediaItem.shortName) {
		return [@"Downloading metadata for " stringByAppendingString:self.mediaItem.shortName];
	}
	
	return @"Unknown metadata download";
}
@end
