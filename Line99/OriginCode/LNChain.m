//
//  LNChain.m
//  Line98
//
//  Created by Nguyen Minh Ngoc on 2015/08/27.
//  Copyright (c) 2015年 Nguyen Minh Ngoc. All rights reserved.
//

#import "LNChain.h"
#import "LNBall.h"

@implementation LNChain {
    NSMutableArray *_balls;
}

- (void)addBall:(LNBall *)ball {
    if (_balls == nil) {
        _balls = [NSMutableArray array];
    }
    [_balls addObject:ball];
}

- (NSArray *)balls {
    return _balls;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"type:%ld cookies:%@", (long)self.chainType, self.balls];
}


@end
