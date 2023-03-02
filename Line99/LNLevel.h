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
} Cell;

typedef struct {
    NSInteger len;
    Cell cells[NumColumns * NumRows];
} LNCellList;

@interface LNLevel : NSObject

- (NSSet *)shuffle;


/// Lấy ball tại cell
/// - Parameter cell: cell cần truy vấn
/// - Returns: ball. Nil nếu không có
- (LNBall *)ballAtCell:(Cell)cell;

//- (LNBall *)ballAtColumn:(NSInteger)column row:(NSInteger)row;

- (int)countEmptyCell;

- (void)resetComboMultiplier;

/// Tìm đường đi giữa 2 cell
/// - Parameters:
///   - fromCell: cell bắt đầu
///   - toCell: cell kết thúc
///   - Returns: list cell đường đi. Độ dài của list == 0 tức là không tìm thấy
- (LNCellList)findPathFromCell:(Cell)fromCell toCell:(Cell)toCell;

/// Tìm cell trống trên màn hình
/// - Returns: cell trống. Nếu column hoặc row == NSNotFound tức là không tìm thấy
- (Cell)findEmptyCell;

/// Tạm thời xoá small ball khỏi màn hình. (Sử dụng trong trường hợp đích đến có chứa small ball)
/// - Parameter smallBall: small ball sẽ xoá
- (void)temporaryRemoveSmallBall:(LNBall*)smallBall;


/// Chuyển small ball đến empty cell.
/// - Parameters:
///   - smallBall: small ball sẽ chuyển
///   - emptyCell: cell đích
- (void)performMoveSmallBall:(LNBall*)smallBall toCell:(Cell)emptyCell;


- (void)performMove:(LNMove *)move;
- (void)performMoveBall:(LNBall *)ball toCell:(Cell)toCell;
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
