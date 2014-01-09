//
//  TMQueueWindowController.m
//  QueueManager
//
//  Created by Cory Powers on 12/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TMQueueWindowController.h"
#import "TMAppController.h"
#import "TMTaskManager.h"

@implementation TMQueueWindowController
- (id)init{
	NSLog(@"init called on queue controller");
	return nil;
}

- (id)initWithController:(TMAppController *)controller {
    if (self = [super initWithController: controller withNibName:@"Queue"]){
        NSAssert([self window], @"[TMQueueWindowController init] window outlet is not connected in Preferences.nib");

		controller.delegate = self;
		[self.statusViewHolder addSubview:self.statusNoItemView];
		[[self window] registerForDraggedTypes:@[NSFilenamesPboardType]];
    }
    return self;
}

- (void)awakeFromNib{
	[self.queueItemsTable setDoubleAction:@selector(editRow:)];
}

- (NSArray *)genreList{
	return @[@"Comedy", @"Drama", @"Nonfiction", @"Other", @"Sports"];
}

- (NSArray *)typeList{
	return @[@"TV Show", @"Movie"];
}

- (IBAction) browseInput: (id) sender{
    NSOpenPanel * panel = [NSOpenPanel openPanel];
	panel.allowsMultipleSelection = NO;
	panel.canChooseFiles = YES;
	panel.canChooseDirectories = NO;

	NSString *panelDir = nil;
	if (sender == self.addItemButton) {
		panelDir = [[NSUserDefaults standardUserDefaults] stringForKey:@"monitoredFolder"];
	}else{
		panelDir = [[NSUserDefaults standardUserDefaults] stringForKey:@"tagFileFolder"];
	}

	panel.directoryURL = [NSURL fileURLWithPath:panelDir];
	
	[panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if( result == NSOKButton ){
			NSError *error;
			if (sender == self.addItemButton) {
				[self.appController addVideoFile:[panel.URL path] error:&error];
			}else if (sender == self.tagFileButton) {
				NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
				[standardDefaults setObject:[panel.directoryURL path] forKey:@"tagFileFolder"];
				self.tagItem = [self.appController mediaItemFromFile:[panel.URL path] error:&error];
				if (self.tagItem == nil) {
					[NSApp presentError:error];
				}else {
					[self.appController updateMetadata:self.tagItem error:&error];
					[self.tagFileWindow makeKeyAndOrderFront:nil];
				}
			}
		}
	}];
}

//- (void) browseInputDone: (NSSavePanel *) sheet
//			  returnCode: (int) returnCode
//			 contextInfo: (void *) contextInfo{
//    if( returnCode == NSOKButton ){
//		NSError *error;
//		if (contextInfo == (__bridge void *)(self.addItemButton)) {
//			[self.appController addVideoFile:[sheet filename] error:&error];
//		}else if (contextInfo == (__bridge void *)(self.tagFileButton)) {
//			NSLog(@"browse completed for tag file button");
//			NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
//			[standardDefaults setObject:[sheet directory] forKey:@"tagFileFolder"];
//			self.tagItem = [self.appController mediaItemFromFile:[sheet filename] error:&error];
//			if (self.tagItem == nil) {
//				[NSApp presentError:error];
//			}else {
//				[self.appController updateMetadata:self.tagItem error:&error];
////				[self populateTagWindowFields:self.tagItem];
//				[self.tagFileWindow makeKeyAndOrderFront:nil];
//			}
//		}
//
//    }
//}

- (void) metadataDidComplete: (TMMediaItem *) anItem{
	if (self.tagItem != nil) {
		NSManagedObjectContext *moc = [self.appController managedObjectContext];
		[moc deleteObject:self.tagItem];

		[self.appController saveAction:nil];
		self.tagItem = nil;
	}
	[self.tagFileButton setEnabled:YES];
}

#pragma mark - Item Window Methods
- (IBAction)showItemWindow: (id)sender{
	// Setup fields with selected object
	// Populate item values
	TMMediaItem *selectedItem = [self.queueItemController selectedObjects][0];
	if (!selectedItem) {
		return;
	}
	
	[[[self.appController managedObjectContext] undoManager] beginUndoGrouping];
	[[[self.appController managedObjectContext] undoManager] setActionName:[NSString stringWithFormat:@"Editing of %@", selectedItem.shortName]];
	self.editingItem = selectedItem;
	[self.itemWindow makeKeyAndOrderFront:sender];
}

- (IBAction)closeItemWindow: (id)sender{
	// Setup fields with selected object
	if (sender == self.itemSaveButton) {
		[[[self.appController managedObjectContext] undoManager] endUndoGrouping];
		NSString *input = [self.itemInputField stringValue];
		// Validate the input file
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if (![fileManager fileExistsAtPath:input] || ![fileManager isReadableFileAtPath:input]){
			NSRunAlertPanel(@"Invalid input file", @"Invalid input file, make sure the file exists and is readable", @"Ok", nil, nil);
			[self.itemInputField selectText:sender];
			return;
		}

		// Save the object
		[self.appController saveAction:nil];
	}else if (sender == self.itemCancelButton) {
		[[[self.appController managedObjectContext] undoManager] endUndoGrouping];
		[[[self.appController managedObjectContext] undoManager] undo];

	}

	self.editingItem = nil;
	[self.itemWindow orderOut:sender];
}

- (IBAction) browseOutput: (id) sender{
    NSSavePanel * panel = [NSSavePanel savePanel];
	panel.directoryURL = [NSURL fileURLWithPath:[[self.itemOutputField stringValue] stringByDeletingLastPathComponent]];
	panel.nameFieldStringValue = [[self.itemOutputField stringValue] lastPathComponent];

	[panel beginSheetModalForWindow:self.itemWindow completionHandler:^(NSInteger result) {
		if( result == NSOKButton ){
			self.editingItem.output = [[panel URL] path];
		}
	}];
}

- (IBAction)updateMetadata: (id)sender{
	NSError *anError;
	[self.appController updateMetadata: self.editingItem error:&anError];
}

- (IBAction)writeMetadata: (id)sender{
	[[TMTaskManager sharedManager] tagMediaItem:self.editingItem];
}

#pragma mark - Tag Window Methods
- (IBAction)closeTagWindow: (id)sender{
	NSError *anError;
	if (sender == self.tagWriteButton) {
		[self.appController writeMetadata:self.tagItem error:&anError];
		[self.tagFileButton setEnabled:NO];
	}else if (sender == self.tagCancelButton) {
		// Get rid of transient tagItem in core data
		NSManagedObjectContext *moc = [self.appController managedObjectContext];
		[moc deleteObject:self.tagItem];
		
		[self.appController saveAction:nil];
		self.tagItem = nil;		
	}

	[self.tagFileWindow orderOut:sender];
}

- (IBAction)updateTagMetadata: (id)sender{
	NSError *anError;
	[self.appController updateMetadata: self.tagItem error:&anError];
}


#pragma mark - Queue Window Methods
- (NSArray *)queueItems{
	return [self.appController queueItems];
}

- (void)windowDidBecomeMain:(NSNotification *)notification{
	NSArray *subviews = [self.statusViewHolder subviews];
	if ([subviews count] > 0) {
		NSView *currentView = subviews[0];
		[self.statusViewHolder resizeSubviewsWithOldSize:[currentView bounds].size];
	}
}

- (void)setViewTo:(NSView *)view{
	NSArray *subviews = [self.statusViewHolder subviews];
	NSView *currentView = subviews[0];
	if (currentView != view ) {
		[currentView removeFromSuperview];
		[self.statusViewHolder addSubview:view];
		[self.statusViewHolder resizeSubviewsWithOldSize:[view bounds].size];
	}
}

- (IBAction)startEncode: (id)sender{
	TMMediaItem *selectedItem = [self.queueItemController selectedObjects][0];
	selectedItem.encodeTask.status = @(0);
	[TMTaskManager sharedManager].delegate = self;
	[[TMTaskManager sharedManager] resumeEncoding];
}

- (void) encodeOperation:(TMEncodeOperation *)anOperation updateProgress:(CGFloat)precentage withETA:(NSString *)eta ofItem:(TMMediaItem *)anItem {
	[self setViewTo:self.statusProgressView];
	
	// Refresh table for icon update
	[self.queueItemsTable reloadData];
	[self.queueItemsTable setNeedsDisplay];
	
	// Disable start button if needed
	if ([self.startEndcodeButton isEnabled]) {
		[self.startEndcodeButton setEnabled:FALSE];
	}
	[self.statusField setStringValue:anItem.shortName];
	if (eta == nil) {
		[self.etaField setStringValue:@"--h--m--s"];
	}else{
		[self.etaField setStringValue:eta];
	}
	[self.statusProgressField setDoubleValue:precentage];
}

- (void)encodeOperationFinished:(TMEncodeOperation *)anOperation forItem:(TMMediaItem *)anItem {
	[self.queueItemsTable reloadData];
	[self.queueItemsTable setNeedsDisplay];
	[self setViewTo: self.statusNoItemView];
	[self.startEndcodeButton setEnabled:TRUE];	
}

//- (void)updateEncodeProgress: (double)progress withEta: (NSString *) eta ofItem: (TMEncodeTaskModel *)item{
//	[self setViewTo:self.statusProgressView];
//
//	// Refresh table for icon update
//	[self.queueItemsTable reloadData];
//	[self.queueItemsTable setNeedsDisplay];
//
//	// Disable start button if needed
//	if ([self.startEndcodeButton isEnabled]) {
//		[self.startEndcodeButton setEnabled:FALSE];
//	}
//	[self.statusField setStringValue:item.mediaItem.shortName];
//	if (eta == nil) {
//		[self.etaField setStringValue:@"--h--m--s"];
//	}else{
//		[self.etaField setStringValue:eta];
//	}
//	[self.statusProgressField setDoubleValue:progress];
//}

- (void)encodeEnded{
	[self.queueItemsTable reloadData];
	[self.queueItemsTable setNeedsDisplay];
	[self setViewTo: self.statusNoItemView];
	[self.startEndcodeButton setEnabled:TRUE];
}

- (IBAction)stopEncode: (id)sender{
	[self.appController stopEncode];
}

- (NSArray *)tableSortDescriptors{
	NSSortDescriptor *sortOrder = [[NSSortDescriptor alloc]
								   initWithKey: @"encodeTask.sortOrder" ascending:YES] ;
	return @[sortOrder];
}

- (void) rearrangeTable{
	[self.queueItemController didChangeArrangementCriteria];
}

- (void) editRow:(id)sender{
	NSInteger row = [self.queueItemsTable clickedRow];
	if(row == -1){
		return;
	}

	[self showItemWindow:sender];
}

- (IBAction) moveItemUp: (id)sender{
	TMEncodeTaskModel *selectedItem = [self.queueItemController selectedObjects][0];
	if ([self.appController moveItemUp:selectedItem]) {
		[self rearrangeTable];
	};
}

- (IBAction) moveItemDown: (id)sender{
	TMEncodeTaskModel *selectedItem = [self.queueItemController selectedObjects][0];
	if ([self.appController moveItemDown:selectedItem]) {
		[self rearrangeTable];
	};
}

#pragma mark Drag-n-Drop Support
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender{
	NSLog(@"draggingEntered");
	NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation mask = [sender draggingSourceOperationMask];
    unsigned int ret = (NSDragOperationCopy & mask);

    if ([[pboard types] indexOfObject:NSFilenamesPboardType] == NSNotFound) {
        ret = NSDragOperationNone;
		NSLog(@"Unsupported drag source");
    }
    return ret;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender{
	NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation mask = [sender draggingSourceOperationMask];
    unsigned int ret = (NSDragOperationCopy & mask);

    if ([[pboard types] indexOfObject:NSFilenamesPboardType] == NSNotFound) {
        ret = NSDragOperationNone;
		NSLog(@"Unsupported drag source");
    }
    return ret;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender{

}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender{
	return YES;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender{
	NSArray *files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	NSError *anError;
	for(NSString *filename in files){
		NSLog(@"Adding file %@", filename);
		if([self.appController addItem:filename error:&anError] == NO){
			NSLog(@"Error adding item: %@", [anError localizedDescription]);
		}
	}

    return YES;
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender{

}


@end
