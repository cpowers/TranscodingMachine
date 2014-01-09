//
//  TMEncodeOperation.h
//  TranscodingMachine
//
//  Created by Cory Powers on 4/19/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaFinderPlugin/MediaFinderPlugin.h>

#import "TMEncodeTaskModel.h"

@class TMEncodeOperation;

@protocol TMEncodeOperationDelegate <NSObject>

- (void) encodeOperation: (TMEncodeOperation *)anOperation updateProgress: (CGFloat)precentage withETA: (NSString *)eta ofItem: (TMMediaItem *)anItem;
- (void) encodeOperationFinished: (TMEncodeOperation *)anOperation forItem: (TMMediaItem *)anItem;

@end

@interface TMEncodeOperation : NSOperation
@property (nonatomic, readonly) NSManagedObjectID *taskModelID;
@property (nonatomic, readonly) NSManagedObjectID *mediaItemModelID;

- (id)initWithEncodeTask: (TMEncodeTaskModel *)aTask;
- (id)initWithEncodeTask: (TMEncodeTaskModel *)aTask andDelegate: (id<TMEncodeOperationDelegate>)aDelegate;

@end
