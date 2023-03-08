//
//  GameScene.swift
//  Line99
//
//  Created by Ngoc Nguyen on 02/11/2021.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, ObservableObject {
    typealias CompletionBlock = (() -> Void)

    private let backgroundZPostion: CGFloat = 1
    private let gridZPosition: CGFloat = 2
    private let smallBallZPosition: CGFloat = 98
    private let tailAnimationZPosition: CGFloat = 99
    private let bigBallZPosition: CGFloat = 100
    private let scoreZPosition: CGFloat = 101

    private var ballManager: BallManager = BallManager()

    private var undoArr: [UndoMove] = []
    var soundOn: Bool = false

    private let ballsLayer: SKNode = SKNode()
    private var invisibleNode: SKNode = SKNode() // node chứa hiệu ứng di chuyển của ball

    private var isBusy = false

    private let invalidMoveSound: SKAction = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    private let moveSound: SKAction = SKAction.playSoundFileNamed("move.wav", waitForCompletion: false)
    private let destroySound: SKAction = SKAction.playSoundFileNamed("destroy.wav", waitForCompletion: false)
    private let jumpingSound: SKAction = SKAction.playSoundFileNamed("jump.wav", waitForCompletion: false)

    private var seletecBall: Ball?

    private var touchedCell: Cell? = nil

    private let cellWidth = 40.0
    private let cellHeight = 40.0

    override init(size: CGSize) {
        super.init(size: size)

        // Đặt center của scene là toạ độ gốc
        anchorPoint = CGPointMake(0.5, 0.5)

        let bgNode = SKSpriteNode(color: .gray, size: size)

        addChild(bgNode)


        let layerPostion = CGPointMake(-cellWidth * Double(Config.NumColumns) / 2, -cellHeight * Double(Config.NumRows) / 2)

        setupGridLayer()

        ballsLayer.position = layerPostion
        addChild(ballsLayer)

        invisibleNode.position = layerPostion
        invisibleNode.zPosition = tailAnimationZPosition
        addChild(invisibleNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startGame() {
        undoArr.removeAll()

        if let undo = load() {
            undoArr.append(contentsOf: undo)
        }

        removeAllBallSprites()
        let newBalls = ballManager.shuffle()
        addSprites(forBalls: newBalls)

        for arr in ballManager.balls {
            for ball in arr {
                if let ball = ball, ball.sprite.parent != nil {
                    print("\(ball.column) \(ball.row)")
                }
            }
        }
    }


    /// Vẽ lưới 9x9 trên màn hình
    private func setupGridLayer() {
        let gridLayer = SKNode()
        let position = CGPointMake(-cellWidth * Double(Config.NumColumns) / 2, -cellHeight * Double(Config.NumRows) / 2)
        gridLayer.position = position
        gridLayer.zPosition = gridZPosition
        addChild(gridLayer)

        var imageName = ""
        for row in 0..<Config.NumRows {
            for col in 0..<Config.NumColumns {
                if row == 0 && col == 0 { // góc trái dưới
                    imageName = "Tile_7"
                } else if (row == 0 && col == Config.NumColumns - 1) { // góc phải dưới
                    imageName = "Tile_9"
                } else if (row == Config.NumRows - 1 && col == 0) { // góc trái trên
                    imageName = "Tile_1"
                } else if (row == Config.NumRows - 1 && col == Config.NumColumns - 1) { // góc phải trên
                    imageName = "Tile_3";
                } else if (row == 0 ) { // cạnh dưới
                    imageName = "Tile_8"
                } else if (row == Config.NumRows - 1) { // cạnh trên
                    imageName = "Tile_2";
                } else if (col == 0 ) { // cạnh trái
                    imageName = "Tile_4";
                } else if (col == Config.NumColumns - 1) { // cạnh phải
                    imageName = "Tile_6";
                } else { // những ô bên trong
                    imageName = "Tile_5";
                }
                let tileNode = SKSpriteNode(imageNamed: imageName)
                tileNode.position = point(column: col, row: row)
                tileNode.zPosition = 3
                gridLayer.addChild(tileNode)
            }
        }
    }


    /// Hiện thị ball đang được chọn bằng animation nẩy lên xuống & play âm thanh
    private func showSelectionIndicator(ball: Ball) {
        ball.animateJumping()
        if soundOn {
            run(jumpingSound)
        }
    }

    /// Ẩn ball được chọn bằng cách tắt animation và đưa ball về trung tâm của cell
    private func hideSelectionIndicator(ball: Ball) {
        ball.stopJumping()
        let centerPoint = point(column: ball.column, row: ball.row)
        let moveToCenterAction = SKAction.move(to: centerPoint, duration: 0.1)
        moveToCenterAction.timingMode = .easeInEaseOut
        ball.sprite.run(moveToCenterAction)
    }


    /// Tạo spriteNode cho balls, add spriteNode vào ballLayer
    private func addSprites(forBalls balls: Set<Ball>) {
        for ball in balls {
//            guard let sprite = ball.sprite  else {
//                return
//            }
            let sprite = ball.sprite
            sprite.position = point(column: ball.column, row: ball.row)
            ballsLayer.addChild(sprite)
            ball.sprite.alpha = 0

            if ball.ballType < 0 { // small ball
                ball.sprite.xScale = 0.1
                ball.sprite.yScale = 0.1
                ball.sprite.zPosition = smallBallZPosition
                let action = SKAction.sequence([SKAction.wait(forDuration: 0.25, withRange: 0.5),
                                                SKAction.group([SKAction.fadeIn(withDuration: 0.25),
                                                                SKAction.scale(to: 0.5, duration: 0.25)
                                                               ])])
                ball.sprite.run(action)
            } else { // big ball
                ball.sprite.xScale = 0.5
                ball.sprite.yScale = 0.5
                ball.sprite.zPosition = bigBallZPosition
                let action = SKAction.sequence([SKAction.wait(forDuration: 0.25, withRange: 0.5),
                                                SKAction.group([SKAction.fadeIn(withDuration: 0.25),
                                                                SKAction.scale(to: 1.0, duration: 0.25)
                                                               ])])
                ball.sprite.run(action)
            }
        }
    }


    /// Hiển thị big ball trên màn hình bằng cách scale các small ball lên thành big ball
    /// - Parameter balls: các balls nhỏ có sẵn trên màn hình (ballLayer)
    private func animateShowBigBalls(_ balls: Set<Ball>) async {
        return await withTaskGroup(of: Void.self) { group in
            let duration: TimeInterval = 0.2
            for ball in balls {
                ball.sprite.zPosition = bigBallZPosition
                group.addTask {
                    await ball.sprite.run(SKAction.scale(to: 1.0, duration: duration))
                }
            }
        }
    }


    /// Add các small ball lên màn hình. (Add vào ballLayer)
    /// - Parameter balls: small balls sẽ add
    private func animateAddSmallBalls(_ balls: Set<Ball>) async {
        return await withTaskGroup(of: Void.self) { group in
            let duration = 0.2
            for ball in balls {
                let sprite = ball.sprite
                sprite.position = point(column: ball.column, row: ball.row)
                sprite.zPosition = smallBallZPosition
                sprite.alpha = 0.0
                sprite.xScale = 0.1
                sprite.yScale = 0.1
                ballsLayer.addChild(sprite)
                let action = SKAction.group([SKAction.fadeIn(withDuration: duration),
                                             SKAction.scale(to: 0.5, duration: duration)])
                group.addTask {
                    await sprite.run(action)
                }
            }
        }

    }


    /// Xoá sạch balls trên màn hình.
    private func removeAllBallSprites() {
        if let seletecBall = seletecBall {
            hideSelectionIndicator(ball: seletecBall)
        }

        seletecBall = nil
        touchedCell = nil
        ballsLayer.removeAllChildren()
    }

    /// Hiện thị animation với trường hợp không tìm được đường cho ball di chuyển
    private func animateInvalidMove(ball: Ball) {
        if soundOn {
            run(invalidMoveSound)
        }
        ball.animateShaking()
    }

    private func animateMatched(chains: Set<Chain>) {
        for chain in chains {
            animateScore(forChain: chain)
        }

        var set = Set<Ball>()
        for chain in chains {
            for ball in chain.balls {
                set.insert(ball)
            }
        }

        Task {
            return await withTaskGroup(of: Void.self) { group in
                for ball in set {
                    group.addTask {
                        await ball.explodeAndRemove()
                    }
                }
            }
        }

        if soundOn {
            run(destroySound)
        }
    }


    /// Hiển thị score của chain
    /// - Parameter chain: chuỗi các ball ăn điểm
    private func animateScore(forChain chain: Chain) {
        guard let firstBall = chain.balls.first, let lastBall = chain.balls.last else {
            return
        }
        let centerPoint = CGPointMake((firstBall.sprite.position.x + lastBall.sprite.position.x) / 2,
                                      (firstBall.sprite.position.y + lastBall.sprite.position.y) / 2)
        let scoreLabel = SKLabelNode(fontNamed: "GillSans-Italic")
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = UIColor.blue
        scoreLabel.text = "\(chain.score)"
        scoreLabel.position = centerPoint
        scoreLabel.zPosition = scoreZPosition
        ballsLayer.addChild(scoreLabel)

        let action = SKAction.move(by: CGVector(dx: 0, dy: 4), duration: 0.8)
        action.timingMode = .easeInEaseOut
        scoreLabel.run(SKAction.sequence([SKAction.group([action, SKAction.fadeOut(withDuration: 0.8)]),
                                          SKAction.removeFromParent()
                                         ]))

    }

    private func tailFor(ball: Ball) -> SKEmitterNode {
        let smoke = SKEmitterNode(fileNamed: "Smoke.sks")!
        smoke.targetNode = invisibleNode
        smoke.particleColorSequence = nil
        smoke.particleColorBlendFactor = 1
        smoke.particleBlendMode = .alpha
        smoke.particleColor = UIColor(named: "ball-color-\(ball.ballType)") ?? .red
        return smoke
    }

    private func animate(move: Move) async {
        hideSelectionIndicator(ball: move.ball)
        seletecBall = nil

        move.ball.sprite.addChild(tailFor(ball: move.ball))

        var count = 0
        let path = CGMutablePath()
        guard let points = move.cellList else {
            return
        }

        var p: CGPoint = point(column: points.cells[count].column, row: points.cells[count].row)
        path.move(to: p)
        count += 1

        repeat {
            p = point(column:  points.cells[count].column, row:  points.cells[count].row)
            path.addLine(to: p)
            count += 1
        } while (count < move.cellList.len)

        let duration = 0.05
        let moveAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration * Double(move.cellList.len))
        moveAction.timingMode = .easeInEaseOut

        await move.ball.sprite.run(moveAction)


        move.ball.sprite.removeAllChildren()

        // chuyển small ball đến vị trí mới
        if let smallBall = move.smallBall, let emptyCell = move.emptyCell {
            let sprite = smallBall.sprite
            let p = point(column: emptyCell.column, row: emptyCell.row)
            let action = SKAction.sequence([SKAction.fadeOut(withDuration: 0),
                                            SKAction.move(to: p, duration: 0),
                                            SKAction.fadeIn(withDuration: 0.2)])
            await sprite.run(action)
        }

    }

    private func handleMatches(balls: Set<Ball>) -> Bool {

        guard let lastUndo = undoArr.last else {
            return false
        }

        var chains = Set<Chain>() // những chain chứa ball ăn điểm
        for ball in balls {
            let chain = ballManager.removeMatchesBall(centerBall: ball)
            if chain.count != 0 {
                chains.inserts(chain)
            }
        }
        lastUndo.justExplodedChains = chains

        if chains.count != 0 {
            let score = chains.reduce(0) { $0 + $1.score }
            lastUndo.justAddedScore = UInt(score)
            animateMatched(chains: chains)
            return true
        } else {
            return false
        }
    }

    private func beginNextTurn() {

        guard let lastUndo = undoArr.last else {
            return
        }
        let bigBalls = ballManager.addNextBigBalls()

        lastUndo.justAddedBigBalls = bigBalls

        Task {
            await animateShowBigBalls(bigBalls)
            if !handleMatches(balls: bigBalls) {
                let smallBalls = ballManager.addNextSmallBalls()
                if smallBalls.count == 0 {
                    // show game over
                } else {
                    lastUndo.justAdddedSmallBalls = smallBalls
                    await animateAddSmallBalls(smallBalls)
                }
            }
        }

    }

    private func tryMoveBall(_ ball: Ball, toCell: Cell) {
        let fromCell = Cell(column: ball.column, row: ball.row)
        let cellList = ballManager.findPathFrom(cell: fromCell, toCell: toCell)
        if cellList.len == 0 {
            animateInvalidMove(ball: ball)
        } else {
            let move = Move()
            move.ball = ball
            move.cellList = cellList

            ballManager.performMove(move: move)

            Task {
                await animate(move:move)
                if let movedBall = ballManager.ballAt(cell: toCell) {
                    if !handleMatches(balls: [movedBall]) {
                        beginNextTurn()
                    }
                }
            }
            let undo = UndoMove()
            undo.justMoved = move
            undoArr.append(undo)

        }
    }
}

extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let location = touch.location(in: ballsLayer)
        guard let cell = cell(fromPoint: location) else {
            touchedCell = nil
            return
        }
        touchedCell = cell
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            touchedCell = nil
            return
        }
        let location = touch.location(in: ballsLayer)
        guard let newCell = cell(fromPoint: location) else {
            touchedCell = nil
            return
        }

        guard let touchedCell = touchedCell else {
            return
        }

        // di chuyển ra ngoài cell ban đầu -> huỷ hành động
        if newCell.column != touchedCell.column || newCell.row != touchedCell.row {
            self.touchedCell = nil
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touchedCell == nil {
            return
        }

        guard let touch = touches.first else {
            return
        }
        let location: CGPoint = touch.location(in: ballsLayer)

        guard let cell = cell(fromPoint: location) else {
            touchedCell = nil
            return
        }

        if let ball = ballManager.ballAt(cell: cell), ball.isBig {
            if seletecBall == ball {
                hideSelectionIndicator(ball: ball)
                seletecBall = nil
            } else {
                if let seletecBall = seletecBall {
                    hideSelectionIndicator(ball: seletecBall)
                }
                showSelectionIndicator(ball: ball)
                seletecBall = ball
            }
        } else if let seletecBall = seletecBall {
            tryMoveBall(seletecBall, toCell: cell)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

}

// MARK: - Undo
extension GameScene {

    func undo() {
        if undoArr.isEmpty {
            return
        }

        if isBusy {
            return
        }

        isBusy = true

        let lastUndo = undoArr.removeLast()
        ballManager.resetComboMultiplier()
        Task {
            if lastUndo.justExplodedChains.count != 0 {

                await animateUndoExplode(lastUndo.justExplodedChains)

                await animateRemoveSmallBalls(lastUndo.justAdddedSmallBalls)
                await animateRevertBigBalls(lastUndo.justAddedBigBalls)
                await animateUndoMove(lastUndo.justMoved)

                ballManager.undoDestroy(chains: lastUndo.justExplodedChains)
                ballManager.revertBigBallsToSmall(bigBalls: lastUndo.justAddedBigBalls)
                ballManager.removeSmallBalls(lastUndo.justAdddedSmallBalls)
                ballManager.performUndoMove(move: lastUndo.justMoved)

            } else {

                await animateRemoveSmallBalls(lastUndo.justAdddedSmallBalls)
                await animateRevertBigBalls(lastUndo.justAddedBigBalls)
                await animateUndoMove(lastUndo.justMoved)

                ballManager.revertBigBallsToSmall(bigBalls: lastUndo.justAddedBigBalls)
                ballManager.removeSmallBalls(lastUndo.justAdddedSmallBalls)
                ballManager.performUndoMove(move: lastUndo.justMoved)
            }
            isBusy = false
        }

    }

    private func animateRevertBigBalls(_ balls: Set<Ball>) async {
        return await withTaskGroup(of: Void.self) { group in
            let duration = 0.2
            for ball in balls {
                ball.sprite.zPosition = smallBallZPosition
                group.addTask {
                    await ball.sprite.run(SKAction.scale(to: 0.5, duration: duration))
                }
            }
        }
    }

    private func animateRemoveSmallBalls(_ balls: Set<Ball>) async {
        return await withTaskGroup(of: Void.self) { group in
            let duration = 0.2
            for ball in balls {
                let scaleAndFadeOut = SKAction.group([SKAction.scale(to: 0.1, duration: duration),
                                                      SKAction.fadeOut(withDuration: duration)])

                let cell = Cell(column:ball.column, row: ball.row)
                if let managedBall = ballManager.ballAt(cell: cell), managedBall.sprite.parent != nil {
                    ball.sprite = managedBall.sprite
                }
                group.addTask {
                    await ball.sprite.run(SKAction.sequence([scaleAndFadeOut, SKAction.removeFromParent()]))
                }
            }
        }
    }

    private func animateUndoMove(_ move: Move) async {
        if let seletecBall = seletecBall {
            hideSelectionIndicator(ball: seletecBall)
            self.seletecBall = nil
            touchedCell = nil
        }

        var count = move.cellList.len - 1
        let path = CGMutablePath()
        let points = move.cellList.cells

        let cell = Cell(column:move.ball.column, row: move.ball.row)
        if let managedBall = ballManager.ballAt(cell: cell), managedBall.sprite.parent != nil {
            move.ball.sprite = managedBall.sprite
        }

        move.ball.sprite.addChild(tailFor(ball: move.ball))

        var p: CGPoint = point(column: points[count].column, row: points[count].row)
        path.move(to: p)
        count -= 1

        repeat {
            p = point(column: points[count].column, row: points[count].row)
            path.addLine(to: p)
            count -= 1
        } while (count >= 0)

        let duration = 0.05
        let moveAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration * Double(move.cellList.len))
        moveAction.timingMode = .easeInEaseOut

        await move.ball.sprite.run(moveAction)
        move.ball.sprite.removeAllChildren()

        // chuyển small ball về vị trí ban đầu
        if let smallBall = move.smallBall {
            let sprite = smallBall.sprite
            let endCell = move.cellList.cells[move.cellList.len - 1]
            let p = point(column: endCell.column, row: endCell.row)
            let action = SKAction.sequence([SKAction.fadeOut(withDuration: 0),
                                            SKAction.move(to: p, duration: 0),
                                            SKAction.scale(to: 0.1, duration: 0),
                                            SKAction.group([SKAction.fadeIn(withDuration: 0.2),
                                                            SKAction.scale(to: 0.5, duration: 0.2)])
                                            ])
            await sprite.run(action)
        }
    }

    private func animateUndoExplode(_ chains: Set<Chain>) async {
        var set = Set<Ball>()
        for chain in chains {
            for ball in chain.balls {
                set.insert(ball)
            }
        }

        return await withTaskGroup(of: Void.self) { group in
            for ball in set {
                ball.prepareUndoExplode()
                ball.sprite.position = point(column: ball.column, row: ball.row)
                ball.sprite.zPosition = bigBallZPosition
                ballsLayer.addChild(ball.sprite)
                group.addTask {
                    await ball.undoExplode()
                }
            }
        }
    }
}

extension GameScene {
    struct WrappedValue: Codable {
        var values: [UndoMove]
    }

    func save() {
        ballManager.save()
        let wrappedValue = WrappedValue(values: undoArr)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(wrappedValue)
            saveDataToDocuments(data, fileName: "undos")
            print(String(data: data, encoding: .utf8)!)
        } catch {
            print("error \(error)")
        }
    }

    private func load() -> [UndoMove]? {
        if let data = readDataFromFile(fileName: "undos") {
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
}


extension GameScene {
    /// Tính point tâm của hàng cột tương ứng ( gốc 0,0 là left,bottom)
    /// - Parameters:
    ///   - column: cột
    ///   - row: hàng
    /// - Returns: point tâm của ô
    private func point(column: Int, row: Int) -> CGPoint {
        // Do dùng toạ độ tâm nên cần cộng thêm 0.5 width và 0.5 height
        return CGPointMake(Double(column) * cellWidth + cellWidth * 0.5, Double(row) * cellHeight + cellHeight * 0.5)
    }

    /// Chuyển từ toạ độ x,y thành cell(column,row). Gốc 0,0 là góc trái, dưới
    private func cell(fromPoint: CGPoint) -> Cell? {
        if fromPoint.x >= 0 && fromPoint.x < Double(Config.NumColumns) * cellWidth &&
            fromPoint.y >= 0 && fromPoint.y < Double(Config.NumRows) * cellHeight {
            let column: Int = Int(fromPoint.x / cellWidth)
            let row: Int = Int(fromPoint.y / cellHeight)
            return Cell(column: column, row: row)
        } else {
            return nil
        }
    }
}


