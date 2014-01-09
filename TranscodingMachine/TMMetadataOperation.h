//
//  TMMetadataOperation.h
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/17/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaFinderPlugin/MediaFinderPlugin.h>

#import "TMMetadataTaskModel.h"

@interface TMMetadataOperation : NSOperation

- (id)initWithMetadataTask: (TMMetadataTaskModel *)aTask andProvider: (MFPInfoProvider *)aProvider;

@end
