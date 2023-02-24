//
//  LNMove.h
//  Line98
//
//  Created by Nguyen Minh Ngoc on 2015/08/28.
//  Copyright (c) 2015年 Nguyen Minh Ngoc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LNLevel.h"

@class LNBall;

@interface LNMove : NSObject

@property (strong, nonatomic) LNBall *ball;
@property (assign, nonatomic) LNPointList pointList;

@property (strong, nonatomic) LNBall *smallBall;
@property (assign, nonatomic) LNPoint emptyPoint;

@end
