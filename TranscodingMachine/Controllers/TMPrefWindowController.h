//
//  TMPrefWindowController.h
//  QueueManager
//
//  Created by Cory Powers on 12/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMWindowController.h"

@interface TMPrefWindowController : TMWindowController {
	NSString *folderActionEnabled;
	IBOutlet NSTextField *enabledLabel;
	IBOutlet NSTextField *monitoredFolderField;
	IBOutlet NSTextField *outputFolderField;
	IBOutlet NSButton *monitoringButton;
	IBOutlet NSTextField *transcoderField;
	IBOutlet NSTextField *transcoderArgsField;
	IBOutlet NSTextField *fileExtensionsField;
	IBOutlet NSButton *browseMonitoredButton;
	IBOutlet NSButton *browseOutputButton;
}

+ (void)registerUserDefaults: (NSString *)appSupportDir;
- (id)initWithController: (TMAppController *)controller;
- (IBAction)savePrefs:(id)sender;
- (IBAction)toggleMonitoring:(id)sender;
- (void)setMonitorFields;
- (void)showWindow;
- (IBAction)closeWindow:(id)sender;
- (IBAction) browseDirectory: (id) sender;
@end
