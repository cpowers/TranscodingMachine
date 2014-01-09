//
//  TMTaskModel.m
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/15/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import "TMTaskModel.h"


@implementation TMTaskModel

@dynamic sortOrder;
@dynamic status;

- (NSData *)statusImage{
	//TODO: Add question market image...
	NSString* imageName;
	if([[self status] intValue] == 0){
		imageName = [[NSBundle mainBundle] pathForResource:@"EncodePending" ofType:@"png"];
	}else if ([[self status] intValue] == 1) {
		imageName = [[NSBundle mainBundle] pathForResource:@"EncodeWorking" ofType:@"png"];
	}else if ([[self status] intValue] == 255) {
		imageName = [[NSBundle mainBundle] pathForResource:@"EncodeComplete" ofType:@"png"];
	}else{
		imageName = [[NSBundle mainBundle] pathForResource:@"EncodeCanceled" ofType:@"png"];
	}
	return [NSData dataWithContentsOfFile:imageName];
}

- (NSString *)description {
	return @"Generic Task";
}
@end
