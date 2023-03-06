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
@property (readonly, nonatomic) NSString *spriteName;

//- (NSString *)spriteName;
//
//- (NSString*)explodedSpriteName;
//- (NSArray*)undoExplodedSpriteTextures;

- (id)initWithType:(NSInteger) type column:(NSInteger)column row:(NSInteger)row;

@end
