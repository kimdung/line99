//
//  LNLevel.m
//  Line98
//
//  Created by Nguyen Minh Ngoc on 2015/08/26.
//  Copyright (c) 2015年 Nguyen Minh Ngoc. All rights reserved.
//

#import "LNLevel.h"
#import "LNChain.h"
#import "LNMove.h"
#import "config.h"

@interface LNLevel ()

@property (assign, nonatomic) NSUInteger comboMultiplier;

@end

@implementation LNLevel {
    LNBall *_balls[NumColumns][NumRows];
}

- (NSSet *)shuffle {
    return [self createInitialBalls];
}

- (NSSet *)createInitialBalls {
    int i, j, remain, count, count2;
    BOOL stop;
    for (i = 0; i < NumColumns; i++) {
        for (j = 0; j < NumRows; j++) {
            _balls[i][j] = nil;
        }
    }

    count = NumColumns * NumRows;
    count2 = count - InitBallNum;
    NSUInteger ballType;
    LNBall *ball;
    NSMutableSet *set = [NSMutableSet set];
    do {
        remain = arc4random_uniform(count--) + 1;
        stop = NO;
        for (i = 0; i < NumColumns; i++) {
            for (j = 0; j < NumRows; j++) {
                if (_balls[i][j] == nil) {
                    remain--;
                    if (remain == 0) {
                        ballType = arc4random_uniform(NumBallTypes) + 1;
                        ball = [self createBallAtColumn:i row:j withType:ballType];
                        [set addObject:ball];
                        stop = YES;
                        break;
                    }
                }
            }
            if (stop) break;
        }
    } while (count > count2);

    NSSet *nextBalls = [self addNextSmallBalls];
    return [set setByAddingObjectsFromSet:nextBalls];
}

- (NSSet*)addNextSmallBalls {
    NSMutableSet *set = [NSMutableSet set];

    int count, tmp, i, j, remain, stop;
    count = [self countEmptyCell];
    LNBall *ball;
    int ballType;
    NSMutableSet *tmpSet = [NSMutableSet set];

    for (tmp = 0; tmp < NextBallNum; tmp++) {
        remain = arc4random_uniform(count--) + 1;
        stop = 0;
        for (i = 0; i < NumColumns; i++) {
            for (j = 0; j < NumRows; j++) {
                if (_balls[i][j] == nil) {
                    remain--;
                    if (remain == 0) {
                        do {
                            ballType = - (arc4random_uniform(NumBallTypes) + 1);
                        } while ([tmpSet containsObject:@(ballType)]);
                        [tmpSet addObject:@(ballType)];

                        ball = [self createBallAtColumn:i row:j withType:ballType];
                        [set addObject:ball];
                        stop = 1;
                        break;
                    }
                }
            }
            if (stop) break;
        }
    }


    return set;
}

- (NSSet*)addNextBigBalls {
    NSMutableSet *set = [NSMutableSet set];
    for (int i = 0; i < NumColumns; i++) {
        for (int j = 0; j < NumRows; j++) {
            LNBall *ball = [self ballAtColumn:i row:j];
            if (ball && ball.ballType < 0) {
                ball.ballType = -ball.ballType;
                [set addObject:ball];
            }
        }
    }
    return set;
}

- (int)countEmptyCell {
    int i, j, count;
    count = 0;
    for (i = 0; i < NumColumns; i++) {
        for (j = 0; j < NumRows; j++) {
            if (_balls[i][j] == nil ) {
                count++;
            }
        }
    }
    return count;
}


- (LNBall *)createBallAtColumn:(NSInteger)column row:(NSInteger)row withType:(NSInteger)ballType {
    LNBall *ball = [[LNBall alloc] init];
    ball.ballType = ballType;
    ball.column = column;
    ball.row = row;
    _balls[column][row] = ball;
    return ball;
}

- (LNBall *)ballAtCell:(Cell)cell {
    return _balls[cell.column][cell.row];
}

- (LNBall *)ballAtColumn:(NSInteger)column row:(NSInteger)row {
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row: %ld", (long)row);

    return _balls[column][row];
}

- (void)performMove:(LNMove *)move {
    NSInteger len = move.cellList.len;
    Cell endPoint = move.cellList.cells[len-1];
    NSAssert1(_balls[endPoint.column][endPoint.row] == nil, @"Invalid moving %@", _balls[endPoint.column][endPoint.row]);

    LNBall *movingBall = move.ball;
    NSInteger column = movingBall.column;
    NSInteger row = movingBall.row;
    _balls[column][row] = nil;

    movingBall.column = endPoint.column;
    movingBall.row = endPoint.row;
    _balls[endPoint.column][endPoint.row] = movingBall;
}

- (void)performMoveBall:(LNBall *)ball toCell:(Cell)toCell {
    _balls[ball.column][ball.row] = nil;
    _balls[toCell.column][toCell.row] = ball;
    ball.column = toCell.column;
    ball.row = toCell.row;
}

- (BOOL)isInside:(NSInteger)column row:(NSInteger)row {
    return (column >= 0 && column < NumColumns && row >= 0 && row < NumRows);
}

//return set of chain
- (NSSet*)removeMatchesBall:(LNBall*)centerBall {

    NSMutableSet *set = [NSMutableSet set];
    NSInteger iCenter = centerBall.column;
    NSInteger jCenter = centerBall.row;
    int u[] = {0, 1, 1, 1};
    int v[] = {1, 0, -1, 1};
    NSInteger i, j, k, t, count;
    count = 0;

    for (t = 0; t < 4; t++) {
        k = 0;
        i = iCenter;
        j = jCenter;
        while (1) {
            i += u[t];
            j += v[t];
            if (![self isInside:i row:j]) {
                break;
            }
            LNBall *ball = _balls[i][j];
            if (ball.ballType != centerBall.ballType) {
                break;
            }
            k++;
        }
        i = iCenter;
        j = jCenter;

        while (1) {
            i -= u[t];
            j -= v[t];
            if (![self isInside:i row:j])
                break;
            LNBall *ball = _balls[i][j];
            if (ball.ballType != centerBall.ballType)
                break;
            k++;
        }
        k++;
        if (k >= EatBallLineNum) {
            LNChain *chain = [[LNChain alloc] init];
            if (t == 0) {
                chain.chainType = ChainType_0;
            } else if (t == 1) {
                chain.chainType = ChainType_90;
            } else if (t == 2) {
                chain.chainType = ChainType_135;
            } else if (t == 3) {
                chain.chainType = ChainType_45;
            }
            while (k-- > 0) {
                i += u[t];
                j += v[t];
                [chain addBall:[self ballAtColumn:i row:j]];
            }

            [set addObject:chain];
        }
    }
    if ([set count]) {
        [self removeBalls:set];
        [self calculateScores:set];
    } else {
        [self resetComboMultiplier];
    }
    return set;
}



- (void)removeBalls:(NSSet *)chains {
    for (LNChain *chain in chains) {
        for (LNBall *ball in chain.balls) {
            _balls[ball.column][ball.row] = nil;
        }
    }
}


- (void)revertBigBallsToSmall:(NSSet*)bigBalls {
    for (LNBall *ball in bigBalls) {
        NSInteger ballType = ball.ballType;
        if (ballType > 0) {
            _balls[ball.column][ball.row].ballType = -ballType;
        }
    }
}

- (void)undoDestroy:(NSSet*)chains {
    for (LNChain *chain in chains) {
        for (LNBall *ball in chain.balls) {
            _balls[ball.column][ball.row] = ball;
        }
    }
}

- (void)removeSmallBalls:(NSSet*)smallBalls {
    for (LNBall *ball in smallBalls) {
        _balls[ball.column][ball.row] = nil;
    }
}


- (void)performUndoMove:(LNMove*)move {
    LNCellList pointList = move.cellList;
    Cell startPoint = pointList.cells[0];
    Cell endPoint = pointList.cells[pointList.len - 1];
    LNBall *ball = move.ball;
    ball.column = startPoint.column;
    ball.row = startPoint.row;

    LNBall *smallBall = move.smallBall;
    if (smallBall) {
        smallBall.column = endPoint.column;
        smallBall.row = endPoint.row;
        _balls[endPoint.column][endPoint.row] = smallBall;
        _balls[move.emptyCell.column][move.emptyCell.row] = nil;
    } else {
        _balls[endPoint.column][endPoint.row] = nil;
    }
    _balls[startPoint.column][startPoint.row] = ball;
}


- (void)calculateScores:(NSSet *)chains {
    for (LNChain *chain in chains) {
        chain.score = (5 * ([chain.balls count] ) * self.comboMultiplier) + [self bonusPoint:[chain.balls count]] * self.comboMultiplier;
        chain.score *= chains.count;
        self.comboMultiplier *= 2;
    }
}

- (NSUInteger)bonusPoint:(NSUInteger)ballCount {
    if (ballCount <= EatBallLineNum) {
        return 0;
    } else {
        NSInteger bonusCnt = ballCount - EatBallLineNum;
        return  bonusCnt * 20;
    }
}

- (void)resetComboMultiplier {
    self.comboMultiplier = 1;
}

- (LNCellList)findPathFromCell:(Cell)fromCell toCell:(Cell)toCell {
    NSInteger i1 = fromCell.column;
    NSInteger j1 = fromCell.row;
    NSInteger i2 = toCell.column;
    NSInteger j2 = toCell.row;

    NSInteger dadi[NumColumns][NumRows];
    NSInteger dadj[NumColumns][NumRows];

    NSInteger queuei[NumColumns * NumRows];
    NSInteger queuej[NumColumns * NumRows];

    int u[] = {1, 0, -1, 0};
    int v[] = {0, 1, 0, -1};

    int fist = 0, last = 0;

    NSInteger x, y, xx, yy, i, k;

    LNCellList res;
    res.len = 0;

    for (x = 0; x < NumColumns; x++) {
        for (y = 0; y < NumRows; y++) {
            dadi[x][y] = -1;
        }
    }

    queuei[0] = i2;
    queuej[0] = j2;
    dadi[i2][j2] = -2;

    while (fist <= last) {
        x = queuei[fist];
        y = queuej[fist];
        fist++;
        for (k = 0; k < 4; k++) {
            xx = x + u[k];
            yy = y + v[k];
            if (xx == i1 && yy == j1) {
                dadi[i1][j1] = x;
                dadj[i1][j1] = y;

                i = 0;
                while (1) {
                    res.cells[i].column = i1;
                    res.cells[i].row = j1;
                    i++;
                    k = i1;
                    i1 = dadi[i1][j1];
                    if (i1 == -2) break;
                    j1 = dadj[k][j1];
                }
                res.len = i;
                for (int i = 0; i < res.len; i++) {
                    DLog(@"col %ld row %ld", (long)res.cells[i].column, (long)res.cells[i].row);
                }
                return res;
            }

            if (! (xx >= 0 && xx < NumColumns && yy >= 0 && yy < NumRows)) continue;

            if (dadi[xx][yy] == -1 && _balls[xx][yy].ballType <= 0) {
                last++;
                queuei[last] = xx;
                queuej[last] = yy;
                dadi[xx][yy] = x;
                dadj[xx][yy] = y;
            }
        }
    }

    for (int i = 0; i < res.len; i++) {
        DLog(@"col %ld row %ld", (long)res.cells[i].column, (long)res.cells[i].row);
    }

    return res;
}

- (Cell)findEmptyCell {
    Cell emptyPoint;
    emptyPoint.column = emptyPoint.row = NSNotFound;

    int empty = [self countEmptyCell];
    if (empty == 0) {
        return emptyPoint;
    } else {
        int tmp = arc4random_uniform(empty) + 1;
        int i, j;
        i = j = 0;
        int count = 0;
        BOOL stop = NO;
        for (i = 0; i < NumColumns; i++) {

            for (j = 0; j < NumRows; j++) {
                LNBall *ball = [self ballAtColumn:i row:j];
                if (ball == nil ) {
                    count++;
                    if (count == tmp) {
                        stop = YES;
                        break;
                    }
                }
            }
            if (stop) break;
        }
        emptyPoint.column = i;
        emptyPoint.row = j;
        DLog(@"empty col (%ld, %ld)", (long)emptyPoint.column, (long)emptyPoint.row);
        return emptyPoint;
    }
}

- (void)temporaryRemoveSmallBall:(LNBall*)smallBall {
    _balls[smallBall.column][smallBall.row] = nil;
}

//- (void)removeBalls:(NSSet*)balls {
//    for (LNBall *b in balls) {
//        _balls[b.column][b.row] = nil;
//    }
//}

- (void)performMoveSmallBall:(LNBall*)smallBall toCell:(Cell)emptyCell {
    if (emptyCell.column == NSNotFound || emptyCell.row == NSNotFound) {
        _balls[smallBall.column][smallBall.row] = nil;
    } else {
        smallBall.column = emptyCell.column;
        smallBall.row = emptyCell.row;
        _balls[emptyCell.column][emptyCell.row] = smallBall;
    }
}

@end
