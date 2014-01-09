//
//  ManagedObjectSenTestCase.m
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/12/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import "ManagedObjectSenTestCase.h"

@implementation ManagedObjectSenTestCase
@synthesize coordinator;
@synthesize context;
@synthesize model;

-(void) setUp {
	@try
	{
		
		NSBundle* bundle = [NSBundle bundleWithIdentifier:@"com.avici.TranscodingMachine"];
		NSLog(@"bundle: %@", bundle);
		NSString* path = [bundle pathForResource:@"TranscodingMachine" ofType:@"momd"];
		NSLog(@"path: %@", path);
		NSURL* modelURL = [NSURL URLWithString:path];
		self.model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
		
		self.coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
		
		NSLog(@"create persistent store");
		// create persistent store
		NSString* tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TranscodingMachine"];
		
		NSFileManager  * fileManager = [NSFileManager defaultManager];
		NSError* error = nil;
		if (![fileManager fileExistsAtPath:tempFilePath]) {
            STAssertTrue([fileManager createDirectoryAtPath:tempFilePath withIntermediateDirectories: YES attributes:nil error:&error], @"error creating temp dir: %@", error);
        }
		
		
		NSString *persistentStoreFileString = [tempFilePath stringByAppendingPathComponent:@"test.sqlite"];
		if ([fileManager fileExistsAtPath:persistentStoreFileString]) {
			[fileManager removeItemAtPath:persistentStoreFileString error:&error];
		}
		
		
		[self.coordinator addPersistentStoreWithType:NSSQLiteStoreType
									   configuration:nil
												 URL:[NSURL fileURLWithPath:persistentStoreFileString]
											 options:nil
											   error:&error];
		
		NSLog(@"create context");
		NSManagedObjectContext* tempContext = [[NSManagedObjectContext alloc] init];
		
		
		[tempContext setPersistentStoreCoordinator:coordinator];
		
//		[tempContext prepareDependentProperties];
		
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		tempContext.undoManager = [[[NSUndoManager alloc] init] autorelease];
#endif
		
		self.context = tempContext;
	}
	@catch (NSException * e)
	{
		STAssertTrue(e == nil, @"error - %@", e);
	}
}

-(void) tearDown
{
	NSLog(@"BEGIN: ManagedObjectSenTestCase tearDown");
	@try
	{
		self.context= nil;
		self.model = nil;
		self.coordinator = nil;
	}
	@catch (NSException * e)
	{
		NSLog(@"%@",e);
		//NSLog(@"%@", [e callStackSymbols]);
		NSLog(@"context reset failed!");
		@throw(e);
		
	}
	NSLog(@"END: ManagedObjectSenTestCase tearDown");
}


-(void) testMOCSetup {
	STAssertNotNil(self.model, @"error loading model");
	STAssertNotNil(self.coordinator, @"error loading coordinator");
	STAssertNotNil(self.context, @"error loading context");
	
	NSArray* allEntities = [model entities];
	STAssertTrue(allEntities.count > 0, @"no entities in bundle!");
}
@end
