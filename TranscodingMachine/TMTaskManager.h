//
//  TMTaskManager.h
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/16/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaFinderPlugin/MediaFinderPlugin.h>

#import "TMUnrarTaskModel.h"
#import "TMEncodeTaskModel.h"
#import "TMTagTaskModel.h"
#import "TMMetadataTaskModel.h"

@protocol TMEncodeOperationDelegate;

typedef void (^TMTaskManagerLoadImageCompleteBlock)(MFPImageProxy *aProxy);

@interface TMTaskManager : NSObject
@property (nonatomic, strong) id<TMEncodeOperationDelegate>delegate;

+ (TMTaskManager *)sharedManager;

- (void) runUnrarTask: (TMUnrarTaskModel *)aTask;
- (void) runMetadataTask: (TMMetadataTaskModel *)aTask;
//- (void) runEncodeTask: (TMEncodeTaskModel *)aTask withDelegate: (id<TMEncodeOperationDelegate>)aDelegate;
- (void) cancelRunningEncodeTask;
- (void) suspendEncoding;
- (void) resumeEncoding;

- (void) tagMediaItem: (TMMediaItem *)anItem;

- (void) runSecondaryOperation: (NSOperation *)anOperation;
//- (void) runEncodeTask: (TMEncodeTaskModel *)aTask;
//- (void) runTagTask: (TMTagTaskModel *)aTask;

- (void) loadImageForProxy: (MFPImageProxy *)aProxy withCompletionHandler: (TMTaskManagerLoadImageCompleteBlock)completionHandler;

@end
