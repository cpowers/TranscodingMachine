//
//  TMMetadataTaskModel.h
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/17/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TMTaskModel.h"

@class TMMediaItem;

@interface TMMetadataTaskModel : TMTaskModel

@property (nonatomic, retain) TMMediaItem *mediaItem;

@end
