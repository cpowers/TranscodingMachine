//
//  TMEncoderQueue.h
//  TranscodingMachine
//
//  Created by Cory Powers on 4/21/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMEncodeOperation.h"

@interface TMEncoderQueue : NSObject

@property (nonatomic, assign, getter = isSuspended) BOOL suspended;
@property (nonatomic, readonly) TMEncodeOperation *runningEncode;
@property (nonatomic, strong) id<TMEncodeOperationDelegate> delegate;

- (void) runQueue;
- (void) stopQueue;
@end
