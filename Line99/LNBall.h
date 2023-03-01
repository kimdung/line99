//
//  LNBall.h
//  Line98
//
//  Created by Nguyen Minh Ngoc on 2015/08/26.
//  Copyright (c) 2015年 Nguyen Minh Ngoc. All rights reserved.
//

@import SpriteKit;

static const NSUInteger NumBallTypes = 7;

@interface LNBall : NSObject

@property (assign, nonatomic) NSInteger column;
@property (assign, nonatomic) NSInteger row;
@property (assign, nonatomic) NSInteger ballType;
@property (strong, nonatomic) SKSpriteNode *sprite;

/// Ball to hay nhỏ.
@property (readonly, nonatomic) BOOL isBigBall;

- (NSString *)spriteName;
//- (NSString *)highlightedSpriteName;
- (NSArray*)explodeSpriteTextures;

- (NSString*)explodedSpriteName;
- (NSArray*)undoExplodedSpriteTextures;

@end
