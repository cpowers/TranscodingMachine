//
//  ManagedObjectSenTestCase.h
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/12/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#endif

#import <SenTestingKit/SenTestingKit.h>

@interface ManagedObjectSenTestCase : SenTestCase {
	NSPersistentStoreCoordinator *coordinator;
	NSManagedObjectContext *context;
	NSManagedObjectModel *model;
}

@property (retain,nonatomic) NSPersistentStoreCoordinator *coordinator;
@property (retain,nonatomic) NSManagedObjectContext *context;
@property (retain,nonatomic) NSManagedObjectModel *model;


@end
