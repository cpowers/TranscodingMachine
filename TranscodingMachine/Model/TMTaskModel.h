//
//  TMTaskModel.h
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/15/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TMTaskModel : SSManagedObject

@property (nonatomic, retain) NSNumber * sortOrder;
@property (nonatomic, retain) NSNumber * status;

@property (readonly) NSString *description;
@property (readonly) NSData *statusImage;

@end
