//
//  QMController.h
//  QueueManager
//
//  Created by Cory Powers on 12/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaFinderPlugin/MediaFinderPlugin.h>

#import "TMEncodeTaskModel.h"
#import "TMMediaItem.h"

@class TMQueueWindowController;
@class TMPrefWindowController;

@protocol TMAppMetadataDelegate <NSObject>
- (void) metadataDidComplete: (TMMediaItem *) anItem;
@end


@interface TMAppController : NSObject {
	NSUserDefaults *defaults;

    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;

	TMPrefWindowController *prefController;
	TMQueueWindowController *queueController;
	NSString *appSupportDir;
	NSString *appResourceDir;
	NSString *encodeStatusFile;

	NSTask *encodingTask;
	TMEncodeTaskModel *encodingItem;
	NSFileHandle *encodeOutputHandle;
	NSTimer *outputReadTimer;
	double encodeProgress;
	NSString *encodeETA;

	NSTask *metadataTask;
	NSFileHandle *metadataOutputHandle;
	NSTimer *metadataReadTimer;
	TMMediaItem *metadataItem;
	
	BOOL runQueue;
	BOOL terminating;

	IBOutlet id <TMAppMetadataDelegate> delegate;
}

@property (nonatomic, retain) id <TMAppMetadataDelegate> delegate;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (readonly) NSArray *queueItems;
@property (readonly) MFPInfoProvider *infoProvider;

- (id) init;
- (IBAction) saveAction:(id)sender;
- (IBAction) showPreferencesWindow:(id)sender;
- (IBAction) showQueueWindow:(id)sender;
- (BOOL) areFolderActionsEnabledOn: (NSString *)path;
- (void) disableFolderActionOn: (NSString *)path;
- (void) enableFolderActionOn: (NSString *)path;

- (BOOL) addItem: (NSString *)path error:(NSError **)outError;
- (BOOL) addItemsInDirectory: (NSString *)path error:(NSError **)outError;
- (BOOL) addRarFile: (NSString *)path error:(NSError **)outError;
- (BOOL) addVideoFile: (NSString *)path error:(NSError **)outError;

- (TMEncodeTaskModel *) nextQueueItem;
- (TMEncodeTaskModel *) nextQueueItemAfterItem: (TMEncodeTaskModel *)prevItem;
- (TMEncodeTaskModel *) lastQueueItem;
- (BOOL) moveItemUp: (TMEncodeTaskModel *)anItem;
- (BOOL) moveItemDown: (TMEncodeTaskModel *)anItem;
- (BOOL) processFileName: (TMMediaItem *)anItem error:(NSError **)outError;
- (BOOL) updateMetadata: (TMMediaItem *)anItem error:(NSError **)outError;
- (BOOL) writeMetadata: (TMMediaItem *)anItem error:(NSError **)outError;
- (BOOL) cleanOldTags: (TMMediaItem *)anItem error:(NSError **) outError;
- (BOOL) writeArt: (TMMediaItem *)anItem error:(NSError **)outError;
- (BOOL) setHDFlag: (TMMediaItem *)anItem error:(NSError **)outError;

- (TMMediaItem *) mediaItemFromFile:(NSString *)path error:(NSError **)outError;

- (BOOL) runQueue;
- (BOOL) isEncodeRunning;
- (BOOL) startEncode:(TMEncodeTaskModel *)anItem;
- (void) stopEncode;
- (TMEncodeTaskModel *) encodingItem;
- (void) taskEnded:(NSNotification *)aNotification;


// Scripting support
- (NSArray *) items;
- (NSScriptObjectSpecifier *) objectSpecifier;
@end
