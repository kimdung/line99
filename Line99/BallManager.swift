//
//  BallManager.swift
//  Line99
//
//  Created by Ngoc Nguyen on 07/03/2023.
//

import Foundation


class BallManager {

    private var balls: [[Ball?]] = [[Ball?]](repeating: [Ball?](repeating: nil, count: Config.NumRows), count: Config.NumColumns)

    private var comboMultiplier = 1
    private var undoArr = [UndoMove]()

    func shuffle() -> Set<Ball> {
        if let loadedArr = loadBalls() {
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

        if let lastUndo = undoArr.last {
//            lastUndo.justAdddedSmallBalls = Set(set)
            lastUndo.justAdddedSmallBalls.removeAll()
            for ball in set {
                lastUndo.justAdddedSmallBalls.insert(ball)
                print("Add small ball \(ball.column),\(ball.row)")
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

        if let lastUndo = undoArr.last {

//            lastUndo.justAddedBigBalls = Set(set)
            lastUndo.justAdddedSmallBalls.removeAll()
            for ball in set {
                lastUndo.justAddedBigBalls.insert(ball.copy())
                print("Add big ball \(ball.column),\(ball.row)")
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
        let len = move.cells.count
        let endPoint = move.cells[len - 1]

        if let smallBall = ballAt(cell: endPoint), !smallBall.isBig {

            if let lastUndo = undoArr.last {
                let justAddSmalls = lastUndo.justAdddedSmallBalls
                for smallBall in justAddSmalls {
                    if smallBall.column == endPoint.column && smallBall.row == endPoint.row {
                        print("aaaaa")
                    }
                }
            }


            temporaryRemoveSmallBall(smallBall: smallBall)
            performMove(ball: move.ball, toCell: endPoint)
            let emptyCell = findEmptyCell()
            performMoveSmallBall(smallBall: smallBall, toCell: emptyCell)
            move.smallBall = smallBall
            move.emptyCell = emptyCell




        } else {
            performMove(ball: move.ball, toCell: endPoint)
        }

        print("-----")

        let undoMove = UndoMove()
        let justMove = Move(ball: move.ball.copy(), cells: move.cells, smallBall: move.smallBall?.copy(), emptyCell: move.emptyCell)
        undoMove.justMoved = justMove
        undoArr.append(undoMove)


        print("Moved big Ball \(move.cells.first!.column),\(move.cells.first!.row) to \(move.cells.last!.column),\(move.cells.last!.row)")
        if let smallBall = move.smallBall {
            print("Moved small Ball \(move.cells.last!.column),\(move.cells.last!.row) to \(move.emptyCell!.column),\(move.emptyCell!.row)")
        }

    }

    private func performMove(ball: Ball, toCell: Cell) {
        balls[ball.column][ball.row] = nil
        balls[toCell.column][toCell.row] = ball
        ball.column = toCell.column
        ball.row = toCell.row
    }

    private func performMoveSmallBall(smallBall: Ball, toCell emptyCell: Cell) {
        if (emptyCell.column == NSNotFound || emptyCell.row == NSNotFound) {
            balls[smallBall.column][smallBall.row] = nil;
        } else {
            smallBall.column = emptyCell.column;
            smallBall.row = emptyCell.row;
            balls[emptyCell.column][emptyCell.row] = smallBall;
        }
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

        if let lastUndo = undoArr.last {
            lastUndo.justExplodedChains.inserts(set)
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

    func calculateScore(chains:Set<Chain>) {
        for chain in chains {
            chain.score = (5 * chain.balls.count * comboMultiplier) +  bonusPoint(ballCount: chain.balls.count) * comboMultiplier
            chain.score *= Int(UInt(chains.count));
            comboMultiplier *= 2;
        }
    }

    private func bonusPoint(ballCount: Int) -> Int {
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

    func findPathFrom(cell fromCell: Cell, toCell: Cell) -> [Cell] {
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

        var cells = [Cell]()

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
//                        res.cells[i].column = i1;
//                        res.cells[i].row = j1;
                        cells.append(Cell(column: i1, row: j1))
                        i += 1;
                        k = i1;
                        i1 = dadi[i1][j1];
                        if (i1 == -2) {
                            break
                        }
                        j1 = dadj[k][j1];
                    }

                    return cells;
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
        return cells
    }

    private func findEmptyCell() -> Cell {
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

    private func temporaryRemoveSmallBall(smallBall: Ball) {
        balls[smallBall.column][smallBall.row] = nil
    }




}

//MARK: - Undo
extension BallManager {

    var lastUndo: UndoMove? {
        return undoArr.last
    }

    func undo() {
        guard let lastUndo = undoArr.last else {
            return
        }
        undoArr.removeLast()
        print("======")

        undoDestroy(chains: lastUndo.justExplodedChains)
        removeSmallBalls(lastUndo.justAdddedSmallBalls)
        revertBigBallsToSmall(bigBalls: lastUndo.justAddedBigBalls)
        performUndoMove(move: lastUndo.justMoved)
    }


    private func removeSmallBalls(_ balls: Set<Ball>){
        for ball in balls {
            self.balls[ball.column][ball.row] = nil
            print("remove small ball \(ball.column),\(ball.row)")
        }
    }

    private func performUndoMove(move: Move) {
        guard let ball = move.ball, !move.cells.isEmpty else {
            return
        }

        let startPoint = move.cells[0]
        let len = move.cells.count
        let endPoint = move.cells[len - 1]

        ball.column = startPoint.column
        ball.row = startPoint.row
        if let smallBall = move.smallBall, let emptyCell = move.emptyCell {
            smallBall.column = endPoint.column
            smallBall.row = endPoint.row
            balls[endPoint.column][endPoint.row] = smallBall
            balls[emptyCell.column][emptyCell.row] = nil

            print("UnMove small ball \(emptyCell.column),\(emptyCell.row) to \(endPoint.column),\(endPoint.row)")

        } else {
            balls[endPoint.column][endPoint.row] = nil
        }
        balls[startPoint.column][startPoint.row] = ball

        print("UnMove Ball \(endPoint.column),\(endPoint.row) to \(startPoint.column),\(startPoint.row)")
    }

    private func undoDestroy(chains: Set<Chain>) {
        for chain in chains {
            for ball in chain.balls {
                balls[ball.column][ball.row] = ball
            }
        }
    }

    private func revertBigBallsToSmall(bigBalls: Set<Ball>) {
        for ball in bigBalls {
            let ballType = ball.ballType
            if ballType > 0 {
                balls[ball.column][ball.row]?.ballType = -ballType

                print("revert to small \(ball.column),\(ball.row)")
            }
        }
    }

}

extension BallManager {

    struct WrappedValue2: Codable {
        var values: [UndoMove]
    }

    func saveUndoData() {

        let wrappedValue = WrappedValue2(values: undoArr)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(wrappedValue)
            saveDataToDocuments(data, fileName: "undos.json")
            print(String(data: data, encoding: .utf8)!)
        } catch {
            print("error \(error)")
        }
    }

    private func loadUndoMove() -> [UndoMove]? {
        if let data = readDataFromFile(fileName: "undos.json") {
            do {
                let values = try JSONDecoder()
                    .decode(WrappedValue2.self, from: data)
                return values.values

            } catch {
                print("Retrieve Failed \(error)")
                return nil
            }
        }
        return nil
    }


    struct WrappedValue: Codable {
        var values: [[Ball?]]
    }

    func saveBalls() {
        let wrappedValue = WrappedValue(values: balls)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(wrappedValue)
            saveDataToDocuments(data, fileName: "balls.json")
            print(String(data: data, encoding: .utf8)!)
        } catch {
            print("error \(error)")
        }
    }

    func loadBalls() -> [[Ball?]]? {
        if let data = readDataFromFile(fileName: "balls.json") {
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
