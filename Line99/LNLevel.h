//
//  LNLevel.h
//  Line98
//
//  Created by Nguyen Minh Ngoc on 2015/08/26.
//  Copyright (c) 2015年 Nguyen Minh Ngoc. All rights reserved.
//

#import "LNBall.h"

@class LNMove;

static const NSInteger NumColumns = 9;
static const NSInteger NumRows = 9;
static const NSInteger InitBallNum = 5;
static const NSInteger NextBallNum = 3;
static const NSInteger EatBallLineNum = 5;

typedef struct {
    NSInteger column;
    NSInteger row;
} LNPoint;

typedef struct {
    NSInteger len;
    LNPoint point[NumColumns * NumRows];
} LNPointList;

@interface LNLevel : NSObject

- (NSSet *)shuffle;
- (LNBall *)ballAtColumn:(NSInteger)column row:(NSInteger)row;

- (int)countEmpty;

- (void)resetComboMultiplier;
- (LNPointList)findPathFromPoint:(LNPoint)fromPoint toPoint:(LNPoint)toPoint;

- (LNPoint)findEmptyLocation;
- (void)temporaryRemoveSmallBall:(LNBall*)smallBall;
- (void)performMoveSmallBall:(LNBall*)smallBall toPoint:(LNPoint)toPoint;
- (void)performMove:(LNMove *)move;
- (NSSet*)addNextBigBalls;
- (NSSet*)addNextSmallBalls;
//- (LNPointList)checkLinesWithBall:(LNBall*)ball;

//return set of chain
- (NSSet*)removeMatchesBall:(LNBall*)centerBall;


//for undo
- (void)revertBigBallsToSmall:(NSSet*)bigBalls;
- (void)removeSmallBalls:(NSSet*)smallBalls;
- (void)performUndoMove:(LNMove*)move;
- (void)undoDestroy:(NSSet*)chains;

@end
