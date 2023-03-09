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
        removeAllBallSprites()
        let newBalls = ballManager.shuffle()
        addSprites(forBalls: newBalls)
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
                let cell = Cell(column: col, row: row)
                tileNode.position = cell.toPoint
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
        let centerPoint = ball.cell.toPoint
        let moveToCenterAction = SKAction.move(to: centerPoint, duration: 0.1)
        moveToCenterAction.timingMode = .easeInEaseOut
        ball.sprite.run(moveToCenterAction)
    }


    /// Tạo spriteNode cho balls, add spriteNode vào ballLayer
    private func addSprites(forBalls balls: Set<Ball>) {
        for ball in balls {
            let sprite = ball.sprite
            sprite.position = ball.cell.toPoint
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
                sprite.position = ball.cell.toPoint
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

    private func animateMatched(chains: Set<Chain>) async {
        for chain in chains {
            animateScore(forChain: chain)
        }

        var set = Set<Ball>()
        for chain in chains {
            for ball in chain.balls {
                if let visibleBall = ballManager.ballAt(cell: ball.cell) {
                    ball.sprite = visibleBall.sprite
                    set.insert(ball)
                } else {
                    print("ball not found on screen" )
                }
            }
        }

        return await withTaskGroup(of: Void.self) { group in
            for ball in set {
                group.addTask {
                    await ball.explodeAndRemove()
                }
            }
        }
    }


    /// Hiển thị score của chain
    /// - Parameter chain: chuỗi các ball ăn điểm
    private func animateScore(forChain chain: Chain) {
        guard let ball1 = chain.balls.first, let lastBall1 = chain.balls.last else {
            return
        }

        guard let firstBall = ballManager.ballAt(cell: ball1.cell), let lastBall = ballManager.ballAt(cell: lastBall1.cell) else {
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

        guard let beginCell = move.cells.first, let endCell = move.cells.last, let ball = ballManager.ballAt(cell: beginCell) else {
            return
        }

        hideSelectionIndicator(ball: ball)
        seletecBall = nil

        ball.sprite.addChild(tailFor(ball: ball))

        var count = 0
        let path = CGMutablePath()

        let cells = move.cells

        var p: CGPoint = cells[count].toPoint  //   point(column: cells[count].column, row: cells[count].row)
        path.move(to: p)
        count += 1

        repeat {
            p =  cells[count].toPoint// point(column:  cells[count].column, row:  cells[count].row)
            path.addLine(to: p)
            count += 1
        } while (count < cells.count)

        let duration = 0.05
        let moveAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration * Double(cells.count))
        moveAction.timingMode = .easeInEaseOut

        await ball.sprite.run(moveAction)


        ball.sprite.removeAllChildren()

        if let smallBallCell = move.smallBallCell, let smallBall = ballManager.ballAt(cell: endCell) {
            let sprite = smallBall.sprite
            let p = smallBallCell.toPoint//  point(column: smallBallCell.column, row: smallBallCell.row)
            let action = SKAction.sequence([SKAction.fadeOut(withDuration: 0),
                                            SKAction.move(to: p, duration: 0),
                                            SKAction.fadeIn(withDuration: 0.2)])
            await sprite.run(action)
        }

    }

    private func findMatchesBall(balls: Set<Ball>) -> Set<Chain> {

        var chains = Set<Chain>() // những chain chứa ball ăn điểm
        for ball in balls {
            let chain = ballManager.findMatchesBall(centerBall: ball)
            if chain.count != 0 {
                chains.inserts(chain)
            }
        }

        return chains

    }

    private func beginNextTurn() async {
        let bigBalls = ballManager.addNextBigBalls()
        await animateShowBigBalls(bigBalls)

        let matchedBalls = findMatchesBall(balls: bigBalls)
        if matchedBalls.isEmpty {
            let smallBalls = ballManager.addNextSmallBalls()
            await animateAddSmallBalls(smallBalls)
        } else {
            await animateMatched(chains: matchedBalls)
            ballManager.removeMatcheBalls(chains: matchedBalls)
        }
    }

    private func tryMoveBall(_ ball: Ball, toCell: Cell) {
        let fromCell = ball.cell// Cell(column: ball.column, row: ball.row)
        let move = ballManager.findMove(cell: fromCell, toCell: toCell)
        let cells = move.cells
        if cells.isEmpty {
            animateInvalidMove(ball: ball)
        } else {
            isBusy = true

            Task {
                await animate(move:move)
                ballManager.performMove(move: move)
                if let movedBall = ballManager.ballAt(cell: toCell) {
                    let matchedBalls = findMatchesBall(balls: [movedBall])
                    if matchedBalls.isEmpty {
                        await beginNextTurn()
                    } else {
                        await animateMatched(chains: matchedBalls)
                        ballManager.removeMatcheBalls(chains: matchedBalls)
                    }
                }

                isBusy = false
            }

        }
    }
}

extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isBusy {
            print("isBusy")
        }
        guard let touch = touches.first, !isBusy else {
            return
        }
        let location = touch.location(in: ballsLayer)
        guard let cell = location.toCell else {
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
        guard let newCell = location.toCell else {
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

        guard let cell = location.toCell else {
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
        guard let lastUndo = ballManager.lastUndo else {
            return
        }

        if isBusy {
            return
        }

        isBusy = true


        ballManager.resetComboMultiplier()
        Task {
            if lastUndo.justExplodedChains.count != 0 {
                let balls = ballManager.undoDestroy(chains: lastUndo.justExplodedChains)
                await animateUndoExplode(balls)

                await animateRemoveSmallBalls(lastUndo.justAdddedSmallBalls)

                await animateRevertBigBalls(lastUndo.justAddedBigBalls)

                await animateUndoMove(lastUndo.justMoved)

                ballManager.undo()
            } else {

                await animateRemoveSmallBalls(lastUndo.justAdddedSmallBalls)

                await animateRevertBigBalls(lastUndo.justAddedBigBalls)

                await animateUndoMove(lastUndo.justMoved)

                ballManager.undo()
            }
            isBusy = false
        }

    }

    private func animateRevertBigBalls(_ cells: Set<Cell>) async {
        return await withTaskGroup(of: Void.self) { group in
            let duration = 0.2
            for cell in cells {
                if let ball = ballManager.ballAt(cell: cell), ball.sprite.parent != nil {
                    ball.sprite.zPosition = smallBallZPosition
                    group.addTask {
                        await ball.sprite.run(SKAction.scale(to: 0.5, duration: duration))
                    }
                } else {
                    print("revert big ball error")
                }
            }
        }
    }

    private func animateRemoveSmallBalls(_ cells: Set<Cell>) async {
        return await withTaskGroup(of: Void.self) { group in
            let duration = 0.2
            for cell in cells {
                if let smallBall = ballManager.ballAt(cell: cell), smallBall.sprite.parent != nil {
                    let scaleAndFadeOut = SKAction.group([SKAction.scale(to: 0.1, duration: duration),
                                                          SKAction.fadeOut(withDuration: duration)])
                    group.addTask {
                        await smallBall.sprite.run(SKAction.sequence([scaleAndFadeOut, SKAction.removeFromParent()]))
                    }
                } else {
                    print("remove small ball error")
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

        guard let endCell = move.cells.last, let ball = ballManager.ballAt(cell: endCell), ball.sprite.parent != nil else {
            print("animate undo move error")
            return
        }

        var count = move.cells.count - 1
        let path = CGMutablePath()
        let points = move.cells

        ball.sprite.addChild(tailFor(ball: ball))

        var p: CGPoint = points[count].toPoint// point(column: points[count].column, row: points[count].row)
        path.move(to: p)
        count -= 1

        repeat {
            p = points[count].toPoint //point(column: points[count].column, row: points[count].row)
            path.addLine(to: p)
            count -= 1
        } while (count >= 0)

        let duration = 0.05
        let moveAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration * Double(move.cells.count))
        moveAction.timingMode = .easeInEaseOut

        await ball.sprite.run(moveAction)
        ball.sprite.removeAllChildren()

        if let smallBallCell = move.smallBallCell {
            if let smallBall = ballManager.ballAt(cell: smallBallCell) {
                let sprite = smallBall.sprite
                let p = endCell.toPoint// point(column: endCell.column, row: endCell.row)
                let action = SKAction.sequence([SKAction.fadeOut(withDuration: 0),
                                                SKAction.move(to: p, duration: 0),
                                                SKAction.scale(to: 0.1, duration: 0),
                                                SKAction.group([SKAction.fadeIn(withDuration: 0.2),
                                                                SKAction.scale(to: 0.5, duration: 0.2)])
                                               ])
                await sprite.run(action)
            } else {
                print("animate undo move small ball error")
            }
        }
    }


    /// Add ball lên màn hình và thực hiện animation quay ngược
    /// - Parameter balls: ball vừa bị phá huỷ
    private func animateUndoExplode(_ balls: Set<Ball>) async {
        return await withTaskGroup(of: Void.self) { group in
            for ball in balls {
                ball.prepareUndoExplode()
                ball.sprite.position = ball.cell.toPoint// point(column: ball.column, row: ball.row)
                ball.sprite.zPosition = bigBallZPosition
                ballsLayer.addChild(ball.sprite)
                group.addTask {
                    await ball.undoExplode()
                }
            }
        }
    }
}


/*
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


*/
