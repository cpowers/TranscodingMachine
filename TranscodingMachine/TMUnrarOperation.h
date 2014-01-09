//
//  TMUnrarOperation.h
//  TranscodingMachine
//
//  Created by Powers, Cory on 4/16/13.
//  Copyright (c) 2013 Cory Powers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TMUnrarTaskModel.h"

@interface TMUnrarOperation : NSOperation
@property (nonatomic, strong) NSString *rarFilePath;
@property (nonatomic, strong) NSString *extractedFile;

- (id)initWithUnrarTask: (TMUnrarTaskModel *)aTask;

@end
