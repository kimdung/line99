//
//  LNChain.h
//  Line98
//
//  Created by Nguyen Minh Ngoc on 2015/08/27.
//  Copyright (c) 2015年 Nguyen Minh Ngoc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LNBall;

typedef NS_ENUM(NSUInteger, ChainType) {
    ChainType_0,
    ChainType_45,
    ChainType_90,
    ChainType_135
};

/// Chain chứa danh sách các ball ăn được điểm
@interface LNChain : NSObject

@property (strong, nonatomic, readonly) NSArray *balls;
@property (assign, nonatomic) ChainType chainType;
@property (assign, nonatomic) NSUInteger score;

- (void)addBall:(LNBall *)ball;

@end
