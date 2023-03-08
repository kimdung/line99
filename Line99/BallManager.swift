//
//  BallManager.swift
//  Line99
//
//  Created by Ngoc Nguyen on 07/03/2023.
//

import Foundation


class BallManager {

    var balls: [[Ball?]] = [[Ball?]](repeating: [Ball?](repeating: nil, count: Config.NumRows), count: Config.NumColumns)

    private var comboMultiplier = 1

    func shuffle() -> Set<Ball> {
        if let loadedArr = load() {
            balls = loadedArr
            var set = Set<Ball>()
            for arr in balls {
                for ball in arr {
                    if let ball = ball {
                        set.insert(ball)
                    }
                }
            }
            return set
        }
        return createInitialBalls()
    }

    func createInitialBalls() -> Set<Ball> {
        var remain, count, count2: UInt32
        var stop: Bool

        for i in 0..<Config.NumColumns {
            for j in 0..<Config.NumRows {
                balls[i][j] = nil
            }
        }

        count = UInt32(Config.NumColumns * Config.NumRows)
        count2 = count - UInt32(Config.InitBallNum)
        var ballType: Int
        var set = Set<Ball>()
        repeat {
            remain = arc4random_uniform(count) + 1
            count -= 1
            stop = false
            for i in 0..<Config.NumColumns {
                for j in 0..<Config.NumRows {
                    if balls[i][j] == nil {
                        remain -= 1
                        if remain == 0 {
                            ballType = Int(arc4random_uniform(UInt32(Config.NumBallTypes)) + 1)
                            let ball = createBallAt(column: i, row: j, type: ballType)
                            set.insert(ball)
                            stop = true
                            break
                        }
                    }
                }
                if stop {
                    break
                }
            }

        } while (count > count2)


        let nextSmallBalls = addNextSmallBalls()
        set.inserts(nextSmallBalls)

        return set
    }

    func addNextSmallBalls() -> Set<Ball> {
        var set = Set<Ball>()

        var count, remain: Int
        var stop: Bool
        count = countEmptyCell()

        if count == 0 {
            return set
        }

        var ballType: Int

        var tmpSet = Set<Int>()

        for _ in 0..<Config.NextBallNum {
            remain = Int(arc4random_uniform(UInt32(count)) + 1)
            stop = false
            for i in 0..<Config.NumColumns {
                for j in 0..<Config.NumRows {
                    if balls[i][j] == nil {
                        remain -= 1
                        if remain == 0 {
                            repeat {
                                ballType = -1 * (Int(arc4random_uniform(UInt32(Config.NumBallTypes))) + 1)
                            } while tmpSet.contains(ballType)
                            tmpSet.insert(ballType)

                            let ball = createBallAt(column: i, row: j, type: ballType)
                            set.insert(ball)
                            stop = true
                            break
                        }
                    }
                }
                if stop {
                    break
                }
            }
            count -= 1
            if count <= 0 {
                break
            }
        }
        return set
    }

    func addNextBigBalls() -> Set<Ball> {
        var set = Set<Ball>()
        for i in 0..<Config.NumColumns {
            for j in 0..<Config.NumRows {
                if let ball = balls[i][j], ball.ballType < 0 {
                    ball.ballType = -ball.ballType
                    set.insert(ball)
                }
            }
        }
        return set
    }


    private func countEmptyCell() -> Int {
        var count = 0
        for i in 0..<Config.NumColumns {
            for j in 0..<Config.NumRows {
                if balls[i][j] == nil {
                    count += 1
                }
            }
        }
        return count
    }

    private func createBallAt(column: Int, row: Int, type: Int) -> Ball {
        let ball = Ball(type: type, column: column, row: row)

        balls[column][row] = ball
        return ball
    }

    func ballAt(cell: Cell) -> Ball? {
        return balls[cell.column][cell.row]
    }

    func performMove(move: Move) {
        let len = move.cellList.len
        let endPoint = move.cellList.cells[len - 1]

        if let smallBall = ballAt(cell: endPoint), !smallBall.isBig {
            temporaryRemoveSmallBall(smallBall: smallBall)
            performMove(ball: move.ball, toCell: endPoint)
            let emptyCell = findEmptyCell()
            performMoveSmallBall(smallBall: smallBall, toCell: emptyCell)
            move.smallBall = smallBall
            move.emptyCell = emptyCell
        } else {
            performMove(ball: move.ball, toCell: endPoint)
        }

        //
        //
        //        let len = move.cellList.len
        //        let endPoint = move.cellList.array[len - 1]
        //
        //        guard let movingBall = move.ball else {
        //            return
        //        }
        //        let column = movingBall.column
        //        let row = movingBall.row
        //        balls[column][row] = nil
        //
        //        movingBall.column = endPoint.column
        //        movingBall.row = endPoint.row
        //        balls[endPoint.column][endPoint.row] = movingBall
    }

    private func performMove(ball: Ball, toCell: Cell) {
        balls[ball.column][ball.row] = nil
        balls[toCell.column][toCell.row] = ball
        ball.column = toCell.column
        ball.row = toCell.row
    }

    private func isInside(column: Int, row: Int) -> Bool {
        return (column >= 0 && column < Config.NumColumns && row >= 0 && row < Config.NumRows)
    }

    func removeMatchesBall(centerBall: Ball) -> Set<Chain> {
        var set = Set<Chain>()
        let iCenter = centerBall.column
        let jCenter = centerBall.row
        let u = [0, 1, 1, 1]
        let v = [1, 0, -1, 1]
        var i, j, k: Int


        for t in 0..<4 {
            k = 0
            i = iCenter
            j = jCenter
            while (true) {
                i += u[t]
                j += v[t]
                if !isInside(column: i, row: j) {
                    break
                }
                let ball = balls[i][j]
                if ball == nil || ball!.ballType != centerBall.ballType {
                    break
                }
                k += 1
            }
            i = iCenter
            j = jCenter

            while (true) {
                i -= u[t]
                j -= v[t]
                if !isInside(column: i, row: j) {
                    break
                }
                let ball = balls[i][j]
                if ball == nil || ball!.ballType != centerBall.ballType {
                    break
                }
                k += 1
            }
            k += 1
            if k >= Config.EatBallLineNum {
                let chain = Chain()
                if t == 0 {
                    chain.chainType = .ChainType_0
                } else if t == 1 {
                    chain.chainType = .ChainType_90
                } else if t == 2 {
                    chain.chainType = .ChainType_135
                } else if t == 3 {
                    chain.chainType = .ChainType_45
                }

                while k > 0 {
                    i += u[t]
                    j += v[t]
                    chain.addBall(balls[i][j])
                    k -= 1
                }
                set.insert(chain)
            }
        }
        if set.count > 0 {
            removeBalls(chains: set)
            calculateScore(chains: set)
        } else {
            resetComboMultiplier()
        }
        return set
    }

    private func removeBalls(chains: Set<Chain>) {
        for chain in chains {
            for ball in chain.balls {
                balls[ball.column][ball.row] = nil
            }
        }
    }

    func revertBigBallsToSmall(bigBalls: Set<Ball>) {
        for ball in bigBalls {
            let ballType = ball.ballType
            if ballType > 0 {
                balls[ball.column][ball.row]?.ballType = -ballType
            }
        }
    }

    func undoDestroy(chains: Set<Chain>) {
        for chain in chains {
            for ball in chain.balls {
                balls[ball.column][ball.row] = ball
            }
        }
    }

    func removeSmallBalls(_ balls: Set<Ball>){
        for ball in balls {
            self.balls[ball.column][ball.row] = nil
        }
    }

    func performUndoMove(move: Move) {
        guard let pointList = move.cellList, let ball = move.ball else {
            return
        }




        let startPoint = pointList.cells[0]
        let endPoint = pointList.cells[pointList.len - 1]

        ball.column = startPoint.column
        ball.row = startPoint.row
        if let smallBall = move.smallBall, let emptyCell = move.emptyCell {
            smallBall.column = endPoint.column
            smallBall.row = endPoint.row
            balls[endPoint.column][endPoint.row] = smallBall
            balls[emptyCell.column][emptyCell.row] = nil
        } else {
            balls[endPoint.column][endPoint.row] = nil
        }
        balls[startPoint.column][startPoint.row] = ball
    }

    func calculateScore(chains:Set<Chain>) {
        for chain in chains {
            chain.score = (5 * chain.balls.count * comboMultiplier) +  bonusPoint(ballCount: chain.balls.count) * comboMultiplier
            chain.score *= Int(UInt(chains.count));
            comboMultiplier *= 2;
        }
    }

    func bonusPoint(ballCount: Int) -> Int {
        if ballCount <= Config.EatBallLineNum {
            return 0
        } else {
            let bonusCnt = ballCount - Config.EatBallLineNum
            return bonusCnt * 20
        }
    }

    func resetComboMultiplier() {
        comboMultiplier = 1
    }

    func findPathFrom(cell fromCell: Cell, toCell: Cell) -> CellList {
        var i1 = fromCell.column
        var j1 = fromCell.row
        let i2 = toCell.column
        let j2 = toCell.row

        var dadi = [[Int]](repeating: [Int](repeating: 0, count: Config.NumRows), count: Config.NumColumns)
        var dadj = [[Int]](repeating: [Int](repeating: 0, count: Config.NumRows), count: Config.NumColumns)

        var queuei = [Int](repeating: 0, count: Config.NumColumns * Config.NumRows)
        var queuej = [Int](repeating: 0, count: Config.NumColumns * Config.NumRows)
        let u = [1, 0, -1, 0]
        let v = [0, 1, 0, -1]

        var first = 0
        var last = 0

        var x, y, xx, yy, i, k: Int

        var res = CellList()
        res.len = 0

        for x in 0..<Config.NumColumns {
            for y in 0..<Config.NumRows {
                dadi[x][y] = -1
            }
        }

        queuei[0] = i2;
        queuej[0] = j2;
        dadi[i2][j2] = -2;

        while first <= last {
            x = queuei[first]
            y = queuej[first]
            first += 1

            for kkkk in 0..<4 {
                xx = x + u[kkkk];
                yy = y + v[kkkk];
                if (xx == i1 && yy == j1) {
                    dadi[i1][j1] = x;
                    dadj[i1][j1] = y;

                    i = 0;
                    while (true) {
                        res.cells[i].column = i1;
                        res.cells[i].row = j1;
                        i += 1;
                        k = i1;
                        i1 = dadi[i1][j1];
                        if (i1 == -2) {
                            break
                        }
                        j1 = dadj[k][j1];
                    }
                    res.len = i;
                    return res;
                }

                if !(xx >= 0 && xx < Config.NumColumns && yy >= 0 && yy < Config.NumRows) {
                    continue;
                }

                if (dadi[xx][yy] == -1 && balls[xx][yy]?.ballType ?? 0 <= 0) {
                    last += 1
                    queuei[last] = xx;
                    queuej[last] = yy;
                    dadi[xx][yy] = x;
                    dadj[xx][yy] = y;
                }
            }
        }
        return  res
    }

    func findEmptyCell() -> Cell {
        var emptyCell = Cell()
        emptyCell.column = NSNotFound
        emptyCell.row = NSNotFound
        let emptyCount = countEmptyCell()
        if emptyCount != 0 {
            let tmp = arc4random_uniform(UInt32(emptyCount)) + 1;
            var count = 0;
            var stop = false;
            for i in 0..<Config.NumColumns {
                for j in 0..<Config.NumRows {
                    let ball = balls[i][j]
                    if (ball == nil) {
                        count += 1
                        if (count == tmp) {
                            stop = true;
                            emptyCell.column = i;
                            emptyCell.row = j;
                            break;
                        }
                    }
                }
                if (stop) {
                    break
                }
            }
        }

        return emptyCell
    }

    func temporaryRemoveSmallBall(smallBall: Ball) {
        balls[smallBall.column][smallBall.row] = nil
    }


    func performMoveSmallBall(smallBall: Ball, toCell emptyCell: Cell) {
        if (emptyCell.column == NSNotFound || emptyCell.row == NSNotFound) {
            balls[smallBall.column][smallBall.row] = nil;
        } else {
            smallBall.column = emptyCell.column;
            smallBall.row = emptyCell.row;
            balls[emptyCell.column][emptyCell.row] = smallBall;
        }
    }

}
extension BallManager {
    struct WrappedValue: Codable {
        var values: [[Ball?]]
    }

    func save() {
        let wrappedValue = WrappedValue(values: balls)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(wrappedValue)
            UserDefaults.standard.set(data, forKey: "balls")
            print(String(data: data, encoding: .utf8)!)
        } catch {
            print("error \(error)")
        }
    }

    func load() -> [[Ball?]]? {
        if let data = UserDefaults.standard.data(forKey: "balls") {
            do {
                let values = try JSONDecoder()
                    .decode(WrappedValue.self, from: data)


                return values.values

            } catch {
                print("Retrieve Failed \(error)")
                return nil
            }
        }
        return nil
    }

   
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

struct CellList: Codable {
    var len: Int = 0
    var cells: [Cell] = [Cell](repeating: Cell(), count: Config.NumColumns * Config.NumRows)
}
