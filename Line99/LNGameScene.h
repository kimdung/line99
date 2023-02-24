//
//  GameScene.h
//  Line98
//
//  Copyright (c) 2015年 Nguyen Minh Ngoc. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "LNLevel.h"

@class LNMove;

@interface LNGameScene : SKScene

@property (strong, nonatomic) LNLevel *level;
@property (assign, nonatomic) BOOL soundOn;
@property (copy, nonatomic) void (^moveHandler)(LNPoint fromPoint, LNPoint toPoint);

- (void)addTiles;
- (void)addSpritesForBalls:(NSSet *)balls;
- (void)animateMatchedBalls:(NSSet *)balls completion:(dispatch_block_t)completion;
- (void)removeAllBallSprites;
- (void)animateAddNewBigBalls:(NSSet *)balls completion:(dispatch_block_t)completion;
- (void)animateAddNewSmallBalls:(NSSet *)balls;
- (void)animateMove:(LNMove*)move completion:(dispatch_block_t)completion;
- (void)animateInvalidMoveCompletion:(dispatch_block_t)completion;
//- (void)animateMoveBackgroudToPoint:(CGPoint)point completion:(dispatch_block_t)completion;

//for undo
- (void)animateRevertBigBallsToSmall:(NSSet*)bigBalls completion:(dispatch_block_t)completion;
- (void)animateRemoveSmallBalls:(NSSet*)smallBalls completion:(dispatch_block_t)completion;
- (void)animateUndoMove:(LNMove*)move completion:(dispatch_block_t)completion;
- (void)animateUndoDestroy:(NSSet*)chains completion:(dispatch_block_t)completion;

@end
