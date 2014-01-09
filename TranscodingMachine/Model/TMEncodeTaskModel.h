//
//  TMEncodeTaskModel.h
//  TranscodingMachine
//
//  Created by Cory Powers on 3/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TMTaskModel.h"

@class TMMediaItem;

@interface TMEncodeTaskModel :  TMTaskModel

@property (nonatomic, retain) TMMediaItem * mediaItem;

@property (readonly) NSData *statusImage;

- (NSScriptObjectSpecifier *)objectSpecifier;

@end



