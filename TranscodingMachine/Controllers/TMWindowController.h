//
//  AppWindowController.h
//  QueueManager
//
//  Created by Cory Powers on 12/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TMAppController;

@interface TMWindowController : NSWindowController <NSWindowDelegate> {
}
@property (readonly) TMAppController *appController;
@property (readonly) NSManagedObjectContext *managedObjectContext;

- (id)initWithController:(TMAppController *)controller withNibName:(NSString *)nibName;
- (id)initWithController:(TMAppController *)controller;
@end
