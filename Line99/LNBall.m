//
//  LNBall.m
//  Line98
//
//  Created by Nguyen Minh Ngoc on 2015/08/26.
//  Copyright (c) 2015年 Nguyen Minh Ngoc. All rights reserved.
//

#import "LNBall.h"
#import "LNTextureCache.h"

@implementation LNBall

- (NSString *)spriteName {

    static NSString * const spriteNames[] = {
        @"jump_1_1.png",
        @"jump_2_1.png",
        @"jump_3_1.png",
        @"jump_4_1.png",
        @"jump_5_1.png",
        @"jump_6_1.png",
        @"jump_7_1.png"
    };
    NSInteger ballType = self.ballType;
    ballType = ballType < 0 ? -ballType : ballType;
    return spriteNames[ballType - 1];
}

- (NSArray*)explodeSpriteTextures {
    NSMutableArray *arr = [NSMutableArray array];
    NSInteger ballType = self.ballType;
    ballType = ballType < 0 ? -ballType : ballType;
    for (int i = 1; i <= 8; i++) {
        NSString *name = [NSString stringWithFormat:@"explode_%ld_%d.png", (long)ballType, i];
        SKTexture *texture = [[LNTextureCache sharedInstance] textureWithCacheName:name];
        [arr addObject:texture];

    }
    return arr;
}

- (NSString*)explodedSpriteName {
    NSString *name = [NSString stringWithFormat:@"explode_%ld_%d.png", (long)self.ballType, 8];
    return name;
}

- (NSArray*)undoExplodedSpriteTextures {
    NSMutableArray *arr = [NSMutableArray array];
    NSInteger ballType = self.ballType;
    ballType = ballType < 0 ? -ballType : ballType;
    for (int i = 7; i >= 1; i--) {
        NSString *name = [NSString stringWithFormat:@"explode_%ld_%d.png", (long)ballType, i];
        SKTexture *texture = [[LNTextureCache sharedInstance] textureWithCacheName:name];
        [arr addObject:texture];
    }
    SKTexture *texture = [[LNTextureCache sharedInstance] textureWithCacheName:[self spriteName]];
    [arr addObject:texture];
    return arr;
}

//- (NSString *)highlightedSpriteName {
//    static NSString * const highlightedSpriteNames[] = {
//        @"Croissant-Highlighted",
//        @"Cupcake-Highlighted",
//        @"Danish-Highlighted",
//        @"Donut-Highlighted",
//        @"Macaroon-Highlighted",
//        @"SugarCookie-Highlighted",
//    };
//    NSInteger ballType = self.ballType;
//    ballType = ballType < 0 ? -ballType : ballType;
//    return highlightedSpriteNames[ballType - 1];
//}


- (NSString *)description {
    return [NSString stringWithFormat:@"type:%ld square:(%ld,%ld)", (long)self.ballType, (long)self.column, (long)self.row];
}

@end
