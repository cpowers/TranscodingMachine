//
//  TMQueueWindowController.h
//  QueueManager
//
//  Created by Cory Powers on 12/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TMAppController.h"
#import "TMWindowController.h"
#import "TMEncodeTaskModel.h"
#import "TMMediaItem.h"
#import "TMEncodeOperation.h"

@interface TMQueueWindowController : TMWindowController <TMAppMetadataDelegate, TMEncodeOperationDelegate> {

}

// Progress releated properties
@property (nonatomic, strong) IBOutlet NSView *statusViewHolder;
@property (nonatomic, strong) IBOutlet NSView *statusProgressView;
@property (nonatomic, strong) IBOutlet NSView *statusNoItemView;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *statusProgressField;
@property (nonatomic, strong) IBOutlet NSTextField *statusField;
@property (nonatomic, strong) IBOutlet NSTextField *etaField;

// Queue related properties
@property (nonatomic, strong) IBOutlet NSArrayController *queueItemController;
@property (nonatomic, strong) IBOutlet NSButton *addItemButton;
@property (nonatomic, strong) IBOutlet NSButton *tagFileButton;
@property (nonatomic, strong) IBOutlet NSButton *editItemButton;
@property (nonatomic, strong) IBOutlet NSButton *startEndcodeButton;
@property (nonatomic, strong) IBOutlet NSButton *cancelEncodeButton;
@property (nonatomic, strong) IBOutlet NSTableView *queueItemsTable;

@property (readonly) NSArray *queueItem;
@property (readonly) NSArray *tableSortDescriptors;
@property (readonly) NSArray *genreList;
@property (readonly) NSArray *typeList;

// Item window properties
@property (nonatomic, strong) TMMediaItem *editingItem;
@property (nonatomic, strong) IBOutlet NSWindow *itemWindow;
@property (nonatomic, strong) IBOutlet NSTextField *itemInputField;
@property (nonatomic, strong) IBOutlet NSTextField *itemOutputField;
@property (nonatomic, strong) IBOutlet NSButton *itemSaveButton;
@property (nonatomic, strong) IBOutlet NSButton *itemCancelButton;

// Tag window properties
@property (nonatomic, strong) TMMediaItem *tagItem;
@property (nonatomic, strong) IBOutlet NSWindow *tagFileWindow;
@property (nonatomic, strong) IBOutlet NSButton *tagWriteButton;
@property (nonatomic, strong) IBOutlet NSButton *tagCancelButton;



- (id)initWithController: (TMAppController *)controller;
- (IBAction) browseInput: (id) sender;
- (void) metadataDidComplete: (TMMediaItem *) anItem;


// Item window functions
- (IBAction)showItemWindow: (id)sender;
- (IBAction)updateMetadata: (id)sender;
- (IBAction)closeItemWindow: (id)sender;
- (IBAction)writeMetadata: (id)sender;
- (IBAction) browseOutput: (id) sender;

// Tag window functions
- (IBAction)updateTagMetadata: (id)sender;
- (IBAction)closeTagWindow: (id)sender;

// Queue Window functions
- (IBAction)startEncode: (id)sender;
- (void)encodeEnded;
- (IBAction)stopEncode: (id)sender;
- (void)windowDidBecomeMain:(NSNotification *)notification;
- (void) editRow: (id)sender;
- (void) rearrangeTable;
- (IBAction)moveItemUp: (id)sender;
- (IBAction)moveItemDown: (id)sender;
- (void)setViewTo: (NSView *)view;

// Drag and drop methods
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender;
- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender;
- (void)draggingExited:(id < NSDraggingInfo >)sender;
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender;
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender;
- (void)concludeDragOperation:(id < NSDraggingInfo >)sender;


@end
