//
//  TMTagTaskModel.m
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/15/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import "TMTagTaskModel.h"
#import "TMMediaItem.h"
#import "TMTaskModel.h"

@implementation TMTagTaskModel

@dynamic mediaItem;

- (NSString *)description {
	return [NSString stringWithFormat:@"Tagging %@", self.mediaItem.shortName];
}

@end
