//
//  AppWindowController.m
//  QueueManager
//
//  Created by Cory Powers on 12/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TMWindowController.h"
#import "TMAppController.h"

@interface TMWindowController ()
@property (nonatomic, strong) TMAppController *appController;

@end

@implementation TMWindowController
- (id)initWithController: (TMAppController *)controller withNibName: (NSString *)nibName {
	if (self = [super initWithWindowNibName:nibName]){
		self.appController = controller;
	}
	return self;
}

- (id)initWithController: (TMAppController *)controller {
	if (self = [super init]){
		self.appController = controller;
	}
	return self;
}

- (NSManagedObjectContext *)managedObjectContext{
	return [self.appController managedObjectContext];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window{
	return [[self.appController managedObjectContext] undoManager];
}
@end
