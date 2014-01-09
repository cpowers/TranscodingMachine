//
//  TMUnrarTask.m
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/15/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import "TMUnrarTaskModel.h"


@implementation TMUnrarTaskModel

@dynamic rarFile;

- (NSString *)description {
	return [self.rarFile lastPathComponent];
}
@end
