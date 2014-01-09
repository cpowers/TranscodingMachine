// 
//  TMEncodeTaskModel.m
//  TranscodingMachine
//
//  Created by Cory Powers on 3/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TMEncodeTaskModel.h"
#import "TMAppController.h"
#import "TMMediaItem.h"

@implementation TMEncodeTaskModel

@dynamic status;
@dynamic sortOrder;
@dynamic mediaItem;

- (id)init{
	return [super init];
}

- (NSData *)statusImage{
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

+ (NSSet *)keyPathsForValuesAffectingStatusImage {
    return [NSSet setWithObjects:@"status", nil];
}

- (NSScriptObjectSpecifier *)objectSpecifier{
	
	NSLog(@"Object specifier was called");
	
	TMAppController *appController = [NSApp delegate];
    NSArray *queueItems = [appController queueItems];
    NSUInteger index = [queueItems indexOfObjectIdenticalTo:self];
	
	NSScriptClassDescription *appClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApp class]];
	
	NSIndexSpecifier *indexSpecifier = [[NSIndexSpecifier alloc] 
										initWithContainerClassDescription:appClassDesc 
										containerSpecifier:nil 
										key:@"queueItems" 
										index:index];
	NSLog(@"Sending specifier: %@", indexSpecifier);
	return indexSpecifier;
	
}

- (NSString *)description {
	return self.mediaItem.shortName;
}
@end
