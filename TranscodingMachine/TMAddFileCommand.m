//
//  QMAddFileCommand.m
//  QueueManager
//
//  Created by Cory Powers on 1/9/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TMAddFileCommand.h"
#import "TMAppController.h"


@implementation TMAddFileCommand : NSScriptCommand

- (id)performDefaultImplementation {
	TMAppController *appController = [NSApp delegate];
	NSError *anError;
	int	theError = noErr;
	id directParameter = [self directParameter];
	[appController addItem:directParameter error:&anError];
	if(anError){
		theError = (int)[anError code];
	}
	
	NSLog(@"AddFileCommand performDefaultImplementation directParameter = %@",directParameter);
	
	if ( theError != noErr ){
		[self setScriptErrorNumber:theError];
	}
		
	return nil;
}

@end
