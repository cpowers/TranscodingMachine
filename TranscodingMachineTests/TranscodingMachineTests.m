//
//  TranscodingMachineTests.m
//  TranscodingMachineTests
//
//  Created by Cory Powers on 4/11/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import "TranscodingMachineTests.h"
#import "TMAppController.h"
#import "TMMediaItem.h"

@interface TranscodingMachineTests (){
	TMAppController *appController;
	TMMediaItem *mediaItem;
}

@end
@implementation TranscodingMachineTests

- (void)setUp {
    [super setUp];
    
    // Set-up code here.
	appController = [[TMAppController alloc] init];
	
	mediaItem = [[TMMediaItem alloc] initWithEntity:[NSEntityDescription entityForName:@"TMMediaItem" inManagedObjectContext:self.context] insertIntoManagedObjectContext:self.context];
}

- (void)tearDown {
    // Tear-down code here.
    appController = nil;
	mediaItem = nil;
	
    [super tearDown];
}

- (void)testFilenameParsingFormat1 {
	mediaItem.input = @"/tmp/TVShow.S01E02.mkv";
	NSError *error;
	
	[appController processFileName:mediaItem error:&error];
	STAssertNil(error, @"Error from processFilename not nil.");
	
	STAssertEqualObjects(mediaItem.showName, @"TVShow", @"Show name not parsed properly");

	STAssertEqualObjects(mediaItem.season, @(1), @"Season number not parsed properly");

	STAssertEqualObjects(mediaItem.episode, @(2), @"Episode number not parsed properly");
}

- (void)testFilenameParsingFormat2 {
	mediaItem.input = @"/tmp/TVShowFormat2-S10E03.mkv";
	NSError *error;
	
	[appController processFileName:mediaItem error:&error];
	STAssertNil(error, @"Error from processFilename not nil.");
	
	STAssertEqualObjects(mediaItem.showName, @"TVShowFormat2", @"Show name not parsed properly");
	
	STAssertEqualObjects(mediaItem.season, @(10), @"Season number not parsed properly");
	
	STAssertEqualObjects(mediaItem.episode, @(3), @"Episode number not parsed properly");
}

@end
