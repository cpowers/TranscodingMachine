//
//  TMUnrarTask.h
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/15/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TMTaskModel.h"


@interface TMUnrarTaskModel : TMTaskModel

@property (nonatomic, retain) NSString * rarFile;

@end
