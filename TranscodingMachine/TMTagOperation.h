//
//  TMTagOperation.h
//  TranscodingMachine
//
//  Created by Cory Powers on 5/10/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMTagTaskModel.h"


@interface TMTagOperation : NSOperation

- (id)initWithTagTask: (TMTagTaskModel *)aTask;

@end
