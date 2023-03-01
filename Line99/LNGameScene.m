//
//  GameScene.m
//  Line98
//
//  Created by Nguyen Minh Ngoc on 2015/08/26.
//  Copyright (c) 2015年 Nguyen Minh Ngoc. All rights reserved.
//

#import "LNGameScene.h"
#import "LNLevel.h"
#import "LNChain.h"
#import "LNMove.h"
#import "LNTextureCache.h"
#import <UIKit/UIKit.h>


static const CGFloat TileWidth = 35;
static const CGFloat TileHeight = 36.0;

@interface LNGameScene () {
    BOOL _invalidTouch;
}

@property (strong, nonatomic) SKNode *gameLayer;
@property (strong, nonatomic) SKNode *ballsLayer;
@property (strong, nonatomic) SKNode *gridLayer;

@property (assign, nonatomic) NSInteger touchedColumn;
@property (assign, nonatomic) NSInteger touchedRow;

@property (strong, nonatomic) SKAction *invalidMoveSound;
@property (strong, nonatomic) SKAction *moveSound;
@property (strong, nonatomic) SKAction *destroySound;
@property (strong, nonatomic) SKAction *jumpingSound;
@property (strong, nonatomic) SKSpriteNode *backgroundNode;

@property (assign, nonatomic) Cell selectedPoint;

@property (readonly, nonatomic) Cell invalidPoint;

@property (strong, nonatomic) LNBall *selectedBall;



@end

@implementation LNGameScene


- (id)initWithSize:(CGSize)size {
    if ((self = [super initWithSize:size])) {

        self.anchorPoint = CGPointMake(0.5, 0.5);

//        [SKTextureAtlas atlasNamed:@"Grid"]; //force to load atlas

        self.backgroundNode = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        [self addChild:self.backgroundNode];
        self.backgroundNode.zPosition = 1;

//        self.gameLayer = [SKNode node];
//        [self addChild:self.gameLayer];
//        self.gameLayer.zPosition = 2;

        CGPoint layerPosition = CGPointMake(-TileWidth*NumColumns/2, -TileHeight*NumRows/2);

        self.gridLayer = [SKNode node];

        self.gridLayer.position = layerPosition;
//        [self.gameLayer addChild:self.tilesLayer];
        [self addChild:self.gridLayer];
        self.gridLayer.zPosition = 3;
        
        self.ballsLayer = [SKNode node];
        self.ballsLayer.position = layerPosition;
//        [self.gameLayer addChild:self.ballsLayer];
        [self addChild:self.ballsLayer];
        self.ballsLayer.zPosition = 2;

        self.touchedColumn = self.touchedRow = NSNotFound;

        self.selectedPoint = self.invalidPoint;

        [self preloadResources];

    }
    return self;
}

/*
- (void)animateMoveBackgroudToPoint:(CGPoint)point completion:(dispatch_block_t)completion {
    [self.backgroundNode runAction:[SKAction sequence:@[
                                                        [SKAction moveTo:point duration:2.0/60],
                                                        [SKAction runBlock:completion]
                                                        ]]];
}
*/

- (void)preloadResources {
    self.invalidMoveSound = [SKAction playSoundFileNamed:@"Error.wav" waitForCompletion:NO];
    self.moveSound = [SKAction playSoundFileNamed:@"move.wav" waitForCompletion:NO];
    self.destroySound = [SKAction playSoundFileNamed:@"destroy.wav" waitForCompletion:NO];
    self.jumpingSound = [SKAction playSoundFileNamed:@"jump.wav" waitForCompletion:NO];
}

- (void)showSelectionIndicatorForBall:(LNBall *)ball {
    self.selectedBall = ball;
    SKAction *moveUpAction = [SKAction moveByX:0 y:3 duration:0.18];
    moveUpAction.timingMode = SKActionTimingEaseOut;
    SKAction *moveDownAction = [SKAction moveByX:0 y:-3 duration:0.18];
    moveDownAction.timingMode = SKActionTimingEaseIn;
    if (self.soundOn) {
        [ball.sprite runAction:self.jumpingSound];
    }
    SKAction *moveUpDown = [SKAction sequence:@[moveUpAction, moveDownAction]];
    [ball.sprite runAction:[SKAction repeatActionForever:moveUpDown] withKey:@"jumping"];
}

- (void)hideSelectionIndicatorCompletion:(dispatch_block_t)completion {
    if (self.selectedBall == nil) return;
    self.selectedPoint = self.invalidPoint;
    [self.selectedBall.sprite removeActionForKey:@"jumping"];
    CGPoint p = [self pointForColumn:self.selectedBall.column row:self.selectedBall.row];
    SKAction *action = [SKAction moveTo:p duration:0.1];
    action.timingMode = SKActionTimingEaseOut;
    [self.selectedBall.sprite runAction:[SKAction sequence:@[
                                                action,
                                                [SKAction runBlock:completion]
                                                ]]];
}

- (void)addSpritesForBalls:(NSSet *)balls {
    for (LNBall *ball in balls) {
        SKSpriteNode *sprite = [[LNTextureCache sharedInstance] spriteWithCacheName:[ball spriteName]];
        sprite.position = [self pointForColumn:ball.column row:ball.row];
        [self.ballsLayer addChild:sprite];
        ball.sprite = sprite;
        ball.sprite.alpha = 0;

        if (ball.ballType < 0) {
            ball.sprite.xScale = ball.sprite.yScale = 0.1;
            ball.sprite.zPosition = 10;
            [ball.sprite runAction:[SKAction sequence:@[
                                                        [SKAction waitForDuration:0.25 withRange:0.5],
                                                        [SKAction group:@[
                                                                          [SKAction fadeInWithDuration:0.25],
                                                                          [SKAction scaleTo:0.4 duration:0.25]
                                                                          ]]]]];
        } else {
            ball.sprite.zPosition = 100;
            ball.sprite.xScale = ball.sprite.yScale = 0.5;
            [ball.sprite runAction:[SKAction sequence:@[
                                                        [SKAction waitForDuration:0.25 withRange:0.5],
                                                        [SKAction group:@[
                                                                          [SKAction fadeInWithDuration:0.25],
                                                                          [SKAction scaleTo:1.0 duration:0.25]
                                                                          ]]]]];
        }
    }
}

- (void)animateAddNewBigBalls:(NSSet *)balls completion:(dispatch_block_t)completion {
    NSTimeInterval duration = 0.2;
    for (LNBall *ball in balls) {
        ball.sprite.zPosition = 100;
        [ball.sprite runAction: [SKAction scaleTo:1.0 duration:duration]];
    }

    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:duration],
                                         [SKAction runBlock:completion]
                                         ]]];

}

- (void)animateAddNewSmallBalls:(NSSet *)balls {
    for (LNBall *ball in balls) {
        SKSpriteNode *sprite = [[LNTextureCache sharedInstance] spriteWithCacheName:[ball spriteName]];
        sprite.position = [self pointForColumn:ball.column row:ball.row];
        [self.ballsLayer addChild:sprite];
        ball.sprite = sprite;
        ball.sprite.zPosition = 12;
        ball.sprite.alpha = 0;

        ball.sprite.xScale = ball.sprite.yScale = 0.1;
        [ball.sprite runAction:[SKAction sequence:@[
                                                    [SKAction waitForDuration:0.2 withRange:0.4],
                                                    [SKAction group:@[
                                                                      [SKAction fadeInWithDuration:0.2],
                                                                      [SKAction scaleTo:0.4 duration:0.2]
                                                                      ]]]]];

    }
}

- (Cell)invalidPoint {
    Cell point;
    point.column = point.row = NSNotFound;
    return point;
}

- (CGPoint)pointForColumn:(NSInteger)column row:(NSInteger)row {
    return CGPointMake(column*TileWidth + TileWidth/2, row*TileHeight + TileHeight/2);
}

- (void)addTiles {
    NSString *imageName;// = @"Tile_5" ;
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            imageName = nil;
            if (row == 0 && column == 0) {
                imageName = @"Tile_7";
            } else if (row == 0 && column < NumColumns - 1 && column > 0) {
                imageName = @"Tile_8";
            } else if (row == 0 && column == NumColumns - 1) {
                imageName = @"Tile_9";
            } else if (row == NumRows - 1 && column == 0) {
                imageName = @"Tile_1";
            } else if (row == NumColumns - 1 && column > 0 && column < NumColumns - 1) {
                imageName = @"Tile_2";
            } else if (row == NumColumns - 1 && column == NumColumns - 1) {
                imageName = @"Tile_3";
            } else if (column == 0 && row > 0 && row < NumRows -1) {
                imageName = @"Tile_4";
            } else if (column == NumColumns -1 && row > 0 && row < NumRows -1) {
                imageName = @"Tile_6";
            } else if (column > 0 && column < NumColumns - 1 && row > 0 && row < NumRows -1){
                imageName = @"Tile_5";
            }

            SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:imageName];
            tileNode.zPosition = 11;
            tileNode.position = [self pointForColumn:column row:row];
            tileNode.alpha = 0.9;
            [self.gridLayer addChild:tileNode];
        }
    }
}


- (void)removeAllBallSprites {
    [self hideSelectionIndicatorCompletion:nil];
    self.selectedPoint = self.invalidPoint;
    self.selectedBall = nil;
    [self.ballsLayer removeAllChildren];
}

- (BOOL)convertPoint:(CGPoint)point toColumn:(NSInteger *)column row:(NSInteger *)row {
    NSParameterAssert(column);
    NSParameterAssert(row);

    if (point.x >= 0 && point.x < NumColumns*TileWidth &&
        point.y >= 0 && point.y < NumRows*TileHeight) {

        *column = point.x / TileWidth;
        *row = point.y / TileHeight;
        return YES;

    } else {
        *column = NSNotFound;  // invalid location
        *row = NSNotFound;
        return NO;
    }
}



- (void)animateInvalidMoveCompletion:(dispatch_block_t)completion {
    if (self.soundOn) {
        [self runAction:self.invalidMoveSound];
    }
    SKAction *moveRightAction = [SKAction moveByX:4 y:0 duration:0.1];
    moveRightAction.timingMode = SKActionTimingEaseInEaseOut;
    SKAction *moveLeftAction = [SKAction moveByX:-4 y:0 duration:0.1];
    moveLeftAction.timingMode = SKActionTimingEaseIn;

    SKAction *invalidMoveAction = [SKAction repeatAction:[SKAction sequence:@[moveRightAction, moveLeftAction]] count:2];
    [self.selectedBall.sprite runAction:[SKAction sequence:@[invalidMoveAction, [SKAction runBlock:completion]]] withKey:@"invalid_moving"];
}


- (void)animateMatchedBalls:(NSSet *)chains completion:(dispatch_block_t)completion {
    for (LNChain *chain in chains) {
        [self animateScoreForChain:chain];
    }

    NSMutableSet *set = [NSMutableSet set];
    for (LNChain *chain in chains) {
        for (LNBall *ball in chain.balls) {
            [set addObject:ball];
        }
    }

    NSTimeInterval duration = 0.05;
    NSUInteger frameCount = 8;
    for (LNBall *ball in set) {
        if (ball.sprite != nil) {
            SKAction *explodeAction = [SKAction animateWithTextures:[ball explodeSpriteTextures] timePerFrame:duration];
            [ball.sprite runAction:[SKAction sequence:@[explodeAction, [SKAction removeFromParent]]]];
            ball.sprite = nil;
        }
    }
    duration = frameCount*duration;
    if (self.soundOn) {
        [self runAction:self.destroySound];
    }
    [self runAction:[SKAction sequence:@[
                                        [SKAction waitForDuration:duration],
                                        [SKAction runBlock:completion]
                                        ]]];
}

- (void)animateRevertBigBallsToSmall:(NSSet*)bigBalls completion:(dispatch_block_t)completion {
    NSTimeInterval duration = 0.2;
    for (LNBall *ball in bigBalls) {
        if (ball.sprite) {
            [ball.sprite runAction:[SKAction scaleTo:0.4 duration:duration]];
            ball.sprite.zPosition = 13;
        }
    }
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:duration],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateRemoveSmallBalls:(NSSet*)smallBalls completion:(dispatch_block_t)completion {
    NSTimeInterval duration = 0.2;
    for (LNBall *ball in smallBalls) {
        if (ball.sprite) {
            SKAction *groupAction = [SKAction group:@[
                                                      [SKAction scaleTo:0.1 duration:duration],
                                                      [SKAction fadeOutWithDuration:duration]]];
            [ball.sprite runAction:[SKAction sequence:@[groupAction, [SKAction removeFromParent]]]];
        }
    }
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:duration],
                                         [SKAction runBlock:completion]
                                         ]]];
}


- (void)animateUndoDestroy:(NSSet*)chains completion:(dispatch_block_t)completion {
    NSTimeInterval duration = 0.05;
    NSMutableSet *set = [NSMutableSet set];
    for (LNChain *chain in chains) {
        for (LNBall *ball in chain.balls) {
            [set addObject:ball];
        }
    }

    NSUInteger frameCount = 7;
    for (LNBall *ball in set) {
        ball.sprite = [[LNTextureCache sharedInstance] spriteWithCacheName:[ball explodedSpriteName]];
        ball.sprite.position = [self pointForColumn:ball.column row:ball.row];
        ball.sprite.zPosition = 13;
        [self.ballsLayer addChild:ball.sprite];
        SKAction *undoExplodeAction = [SKAction animateWithTextures:[ball undoExplodedSpriteTextures] timePerFrame:duration];
        [ball.sprite runAction:undoExplodeAction];
    }
    duration = frameCount*duration;
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:duration],
                                         [SKAction runBlock:completion]
                                         ]]];

}

- (void)animateUndoMove:(LNMove*)move completion:(dispatch_block_t)completion {
    [self hideSelectionIndicatorCompletion:nil];


    NSInteger count = move.cellList.len - 1;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPoint p = [self pointForColumn:move.cellList.cells[count].column row:move.cellList.cells[count].row];
    CGPathMoveToPoint(path, nil, p.x, p.y);
    count--;
    do {
        p = [self pointForColumn:move.cellList.cells[count].column row:move.cellList.cells[count].row];
        CGPathAddLineToPoint(path, nil, p.x, p.y);
        count--;
    } while (count >= 0);
    NSTimeInterval duration = 0.04;
    SKAction *moveAction = [SKAction followPath:path asOffset:NO orientToPath:NO duration:duration*move.cellList.len];
    CGPathRelease(path);
    moveAction.timingMode = SKActionTimingEaseInEaseOut;

    [move.ball.sprite runAction: [SKAction sequence:@[moveAction, [SKAction runBlock:completion]]]];

    duration = duration*move.cellList.len;
    if (move.smallBall) {
        SKSpriteNode *sprite = move.smallBall.sprite;
        Cell endPoint = move.cellList.cells[move.cellList.len - 1];
        CGPoint p = [self pointForColumn:endPoint.column row:endPoint.row];
        SKAction *action = [SKAction sequence:@[
                                                [SKAction fadeOutWithDuration:duration],
                                                [SKAction moveTo:p duration:0],
                                                [SKAction fadeInWithDuration:duration]]];
        [sprite runAction:action];
    }
}


- (void)animateMove:(LNMove*)move completion:(dispatch_block_t)completion {
    [self hideSelectionIndicatorCompletion:^{
        self.selectedBall = nil;
    }];
    self.selectedPoint = self.invalidPoint;

    NSInteger count = 0;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPoint p = [self pointForColumn:move.cellList.cells[count].column row:move.cellList.cells[count].row];
    CGPathMoveToPoint(path, nil, p.x, p.y);
    count++;
    do {
        p = [self pointForColumn:move.cellList.cells[count].column row:move.cellList.cells[count].row];
        CGPathAddLineToPoint(path, nil, p.x, p.y);
        count++;
    } while (count < move.cellList.len);
    NSTimeInterval duration = 0.04;
    SKAction *moveAction = [SKAction followPath:path asOffset:NO orientToPath:NO duration:duration*move.cellList.len];
    CGPathRelease(path);
    moveAction.timingMode = SKActionTimingEaseInEaseOut;

    [move.ball.sprite runAction: [SKAction sequence:@[moveAction, [SKAction runBlock:completion]]]];

    duration = duration*move.cellList.len;
    if (move.smallBall) {
        SKSpriteNode *sprite = move.smallBall.sprite;

        CGPoint p = [self pointForColumn:move.emptyCell.column row:move.emptyCell.row];
        SKAction *action = [SKAction sequence:@[
                                                [SKAction fadeOutWithDuration:duration],
                                                [SKAction moveTo:p duration:0],
                                                [SKAction fadeInWithDuration:duration]]];
        [sprite runAction:action];
    }
    if (self.soundOn) {
        [self runAction:self.moveSound];
    }
}

/// Hiển thị điểm tương ứng với balls trong chain
/// - Parameter chain: chain chứa các bi được tính điểm
- (void)animateScoreForChain:(LNChain *)chain {
    // Figure out what the midpoint of the chain is.
    LNBall *firstBall = [chain.balls firstObject];
    LNBall *lastBall = [chain.balls lastObject];
    CGPoint centerPosition = CGPointMake(
                                         (firstBall.sprite.position.x + lastBall.sprite.position.x)/2,
                                         (firstBall.sprite.position.y + lastBall.sprite.position.y)/2 - 8);

    // Add a label for the score that slowly floats up.
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"GillSans-Italic"];
    scoreLabel.fontSize = 16;
    scoreLabel.fontColor = [SKColor blueColor];
    scoreLabel.text = [NSString stringWithFormat:@"+%lu", (long)chain.score];
    scoreLabel.position = centerPosition;
    scoreLabel.zPosition = 300;
    [self.ballsLayer addChild:scoreLabel];

    SKAction *moveAction = [SKAction moveBy:CGVectorMake(0, 4) duration:0.8];
    moveAction.timingMode = SKActionTimingEaseOut;
    [scoreLabel runAction:[SKAction sequence:@[
                                               [SKAction group:@[moveAction,[SKAction fadeOutWithDuration:0.8]]],
                                               [SKAction removeFromParent]
                                               ]]];
}


#pragma mark -

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    _invalidTouch = NO;

    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.ballsLayer];

    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        self.touchedColumn = column;
        self.touchedRow = row;
    }
}



- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    if (self.swipeFromColumn == NSNotFound) return;

    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.ballsLayer];

    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        NSInteger horzDelta = 0, vertDelta = 0;
        if (column < self.touchedColumn) {          // swipe left
            horzDelta = -1;
        } else if (column > self.touchedColumn) {   // swipe right
            horzDelta = 1;
        } else if (row < self.touchedRow) {         // swipe down
            vertDelta = -1;
        } else if (row > self.touchedRow) {         // swipe up
            vertDelta = 1;
        }

        if (horzDelta != 0 || vertDelta != 0) {
            _invalidTouch = YES;
            self.touchedColumn = NSNotFound;
            self.touchedRow = NSNotFound;
        }
    }
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.ballsLayer];

    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        if (column != self.touchedColumn || row != self.touchedRow) {
            _invalidTouch = YES;
        }
        if (!_invalidTouch) {
            if (self.selectedPoint.column == NSNotFound) {
                Cell p;
                p.column = self.touchedColumn;
                p.row = self.touchedRow;
                LNBall *ball = [self.level ballAtColumn:p.column row:p.row];
                if (ball && ball.ballType > 0) {
                    self.selectedPoint = p;
                    LNBall *ball = [self.level ballAtColumn:p.column row:p.row];
                    [self showSelectionIndicatorForBall:ball];
                }
            } else if (self.selectedPoint.column == self.touchedColumn && self.selectedPoint.row == self.touchedRow) {
//                LNBall *ball = [self.level ballAtColumn:self.selectedPoint.column row:self.selectedPoint.row];
                [self hideSelectionIndicatorCompletion:^{
                    self.selectedBall = nil;
                }];
                self.selectedPoint = self.invalidPoint;
            } else {
                Cell p;
                p.column = self.touchedColumn;
                p.row = self.touchedRow;
                [self tryMoveBallFromPoint:self.selectedPoint toPoint:p];
            }
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)tryMoveBallFromPoint:(Cell)fromPoint toPoint:(Cell)toPoint {
    LNBall *fromBall = [self.level ballAtColumn:fromPoint.column row:fromPoint.row];
    if (fromBall == nil || fromBall.ballType < 0) {
        self.selectedPoint = self.invalidPoint;
        return;
    }

    LNBall *toBall = [self.level ballAtColumn:toPoint.column row:toPoint.row];
    if (toBall && toBall.ballType > 0) {
        [self hideSelectionIndicatorCompletion:^{
            self.selectedPoint = toPoint;
            [self showSelectionIndicatorForBall:toBall];
        }];
    } else {
        if (self.moveHandler) {
            self.moveHandler(fromPoint, toPoint);
        }
    }
}



/*
- (void)animateMoveSmallBall:(LNBall*)smallBall toPoint:(LNPoint)toPoint completion:(dispatch_block_t)completion {
    SKSpriteNode *sprite = smallBall.sprite;
    [sprite removeFromParent];

    sprite.position = [self pointForColumn:toPoint.column row:toPoint.row];
    [self.ballsLayer addChild:sprite];
    smallBall.sprite = sprite;
    smallBall.sprite.alpha = 0;

    smallBall.sprite.xScale = smallBall.sprite.yScale = 0.1;
    [smallBall.sprite runAction:[SKAction sequence:@[
                                                [SKAction group:@[
                                                                  [SKAction fadeInWithDuration:0.25],
                                                                  [SKAction scaleTo:0.4 duration:0.25]
                                                                  ]], [SKAction runBlock:completion] ]
                                 ]];



//    [self.ballsLayer addChild:sprite];
//
//    ball.sprite = sprite;
//    ball.sprite.alpha = 0;
//
//    ball.sprite.xScale = ball.sprite.yScale = 0.1;
//    [ball.sprite runAction:[SKAction sequence:@[
//                                                [SKAction waitForDuration:0.25 withRange:0.5],
//                                                [SKAction group:@[
//                                                                  [SKAction fadeInWithDuration:0.25],
//                                                                  [SKAction scaleTo:0.4 duration:0.25]
//                                                                  ]]]]];

}
 */

/*
-(void)didMoveToView:(SKView *)view {
    SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    
    myLabel.text = @"Hello, World!";
    myLabel.fontSize = 65;
    myLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                   CGRectGetMidY(self.frame));
    
    [self addChild:myLabel];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"Spaceship"];
        
        sprite.xScale = 0.5;
        sprite.yScale = 0.5;
        sprite.position = location;
        
        SKAction *action = [SKAction rotateByAngle:M_PI duration:1];
        
        [sprite runAction:[SKAction repeatActionForever:action]];
        
        [self addChild:sprite];
    }
}

-(void)update:(CFTimeInterval)currentTime {

}
 */

@end
