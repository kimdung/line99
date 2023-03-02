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
    private let ballZposition: CGFloat = 100
    private let scoreZposition: CGFloat = 101
    private var level: LNLevel = LNLevel()

    private var undoArr: [Undo] = []
    var soundOn: Bool = false

    private var ballsLayer: SKNode = SKNode()

    private let invalidMoveSound: SKAction = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    private let moveSound: SKAction = SKAction.playSoundFileNamed("move.wav", waitForCompletion: false)
    private let destroySound: SKAction = SKAction.playSoundFileNamed("destroy.wav", waitForCompletion: false)
    private let jumpingSound: SKAction = SKAction.playSoundFileNamed("jump.wav", waitForCompletion: false)

    private var seletecBall: LNBall?

    private var touchedCell: Cell? = nil

    private let cellWidth = 35.0
    private let cellHeight = 36.0

    override init(size: CGSize) {
        super.init(size: size)

        // Đặt center của scene là toạ độ gốc
        anchorPoint = CGPointMake(0.5, 0.5)

        let bgNode = SKSpriteNode(color: .gray, size: size)

        addChild(bgNode)


        let layerPostion = CGPointMake(-cellWidth * Double(NumColumns) / 2, -cellHeight * Double(NumRows) / 2)

        setupGridLayer()

        ballsLayer.position = layerPostion
        addChild(ballsLayer)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startGame() {
        undoArr.removeAll()
        removeAllBallSprites()
        let newBalls = level.shuffle() as! Set<LNBall>
        level.resetComboMultiplier()
        addSprites(forBalls: newBalls)
    }


    /// Vẽ lưới 9x9 trên màn hình
    private func setupGridLayer() {
        let gridLayer = SKNode()
        let position = CGPointMake(-cellWidth * Double(NumColumns) / 2, -cellHeight * Double(NumRows) / 2)
        gridLayer.position = position
        gridLayer.zPosition = gridZPosition
        addChild(gridLayer)

        var imageName = ""
        for row in 0..<NumRows {
            for col in 0..<NumColumns {
                if row == 0 && col == 0 { // góc trái dưới
                    imageName = "Tile_7"
                } else if (row == 0 && col == NumColumns - 1) { // góc phải dưới
                    imageName = "Tile_9"
                } else if (row == NumRows - 1 && col == 0) { // góc trái trên
                    imageName = "Tile_1"
                } else if (row == NumRows - 1 && col == NumColumns - 1) { // góc phải trên
                    imageName = "Tile_3";
                } else if (row == 0 ) { // cạnh dưới
                    imageName = "Tile_8"
                } else if (row == NumRows - 1) { // cạnh trên
                    imageName = "Tile_2";
                } else if (col == 0 ) { // cạnh trái
                    imageName = "Tile_4";
                } else if (col == NumColumns - 1) { // cạnh phải
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
    private func showSelectionIndicator(ball: LNBall) {
        let moveUpAction = SKAction.moveBy(x: 0, y: 3, duration: 0.18)
        moveUpAction.timingMode = .easeOut
        let moveDownAction = SKAction.moveBy(x:0, y: -3, duration: 0.18)
        moveDownAction.timingMode = .easeIn
        let moveUpDown = SKAction.sequence([moveUpAction, moveDownAction])
        ball.sprite.run(SKAction.repeatForever(moveUpDown), withKey: "jumping")

        if soundOn {
            ball.sprite.run(jumpingSound)
        }
    }

    /// Ẩn ball được chọn bằng cách tắt animation và đưa ball về trung tâm của cell
    private func hideSelectionIndicator(ball: LNBall) {
        ball.sprite.removeAllActions()
        let centerPoint = point(column: ball.column, row: ball.row)
        let moveToCenterAction = SKAction.move(to: centerPoint, duration: 0.1)
        moveToCenterAction.timingMode = .easeInEaseOut
        ball.sprite.run(moveToCenterAction)
    }


    /// Tạo spriteNode cho balls, add spriteNode vào ballLayer
    private func addSprites(forBalls balls: Set<AnyHashable>) {
        let textureCache = LNTextureCache.sharedInstance() as! LNTextureCache
        for ball in balls {
            guard let ball = ball as? LNBall, let sprite = textureCache.sprite(withCacheName: ball.spriteName())  else {
                return
            }

            sprite.position = point(column: ball.column, row: ball.row)
            ballsLayer.addChild(sprite)
            ball.sprite = sprite
            ball.sprite.alpha = 0
            ball.sprite.zPosition = ballZposition
            if ball.ballType < 0 { // small ball
                ball.sprite.xScale = 0.1
                ball.sprite.yScale = 0.1
                let action = SKAction.sequence([SKAction.wait(forDuration: 0.25, withRange: 0.5),
                                                SKAction.group([SKAction.fadeIn(withDuration: 0.25),
                                                                SKAction.scale(to: 0.4, duration: 0.25)
                                                               ])])
                ball.sprite.run(action)
            } else { // big ball
                ball.sprite.xScale = 0.4
                ball.sprite.yScale = 0.4
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
    private func animateShowBigBalls(_ balls: Set<LNBall>) async {
        return await withTaskGroup(of: Void.self) { group in
            let duration: TimeInterval = 0.2
            for ball in balls {
                ball.sprite.zPosition = ballZposition
                group.addTask {
                    await ball.sprite.run(SKAction.scale(to: 1.0, duration: duration))
                }
            }
        }
    }


    /// Add các small ball lên màn hình. (Add vào ballLayer)
    /// - Parameter balls: small balls sẽ add
    private func animateAddSmallBalls(_ balls: Set<LNBall>) {
        let textureCache = LNTextureCache.sharedInstance() as! LNTextureCache
        let duration = 0.2
        for ball in balls {
            guard let sprite = textureCache.sprite(withCacheName: ball.spriteName()) else {
                return
            }

            sprite.position = point(column: ball.column, row: ball.row)
            sprite.zPosition = ballZposition
            sprite.alpha = 0.0
            sprite.xScale = 0.1
            sprite.yScale = 0.1
            ballsLayer.addChild(sprite)
            let action = SKAction.sequence([SKAction.wait(forDuration: duration, withRange: 0.4),
                                            SKAction.group([SKAction.fadeIn(withDuration: duration),
                                                            SKAction.scale(to: 0.4, duration: duration)
                                                           ])])
            sprite.run(action)
            ball.sprite = sprite
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
    private func animateInvalidMove(ball: LNBall) {
        if soundOn {
            run(invalidMoveSound)
        }
        let duration = 0.1
        let moveRight = SKAction.moveBy(x: 4, y: 0, duration: duration)
        moveRight.timingMode = .easeInEaseOut
        let moveLeft = SKAction.moveBy(x: -4, y: 0, duration: duration)
        moveLeft.timingMode = .easeInEaseOut
        let shakeAction = SKAction.repeat(SKAction.sequence([moveLeft, moveRight]), count: 2)
        Task {
            await ball.sprite.run(shakeAction)
        }
    }

    private func animateMatched(chains: Set<LNChain>) {
        for chain in chains {
            animateScore(forChain: chain)
        }

        var set = Set<LNBall>()
        for chain in chains {
            for ball in chain.balls {
                set.insert(ball as! LNBall)
            }
        }

        let duration = 0.05
        let frameCount = 8
        for ball in set {
            let explodeAction = SKAction.animate(with: ball.explodeSpriteTextures() as! [SKTexture], timePerFrame: duration)
            ball.sprite.run(SKAction.sequence([explodeAction, SKAction.removeFromParent()]))
        }

        if soundOn {
            run(destroySound)
        }
    }


    /// Hiển thị score của chain
    /// - Parameter chain: chuỗi các ball ăn điểm
    private func animateScore(forChain chain: LNChain) {
        guard let firstBall = chain.balls.first as? LNBall, let lastBall = chain.balls.last as? LNBall else {
            return
        }
        let centerPoint = CGPointMake((firstBall.sprite.position.x + lastBall.sprite.position.x) / 2,
                                      (firstBall.sprite.position.y + lastBall.sprite.position.y) / 2)
        let scoreLabel = SKLabelNode(fontNamed: "GillSans-Italic")
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = UIColor.blue
        scoreLabel.text = "\(chain.score)"
        scoreLabel.position = centerPoint
        scoreLabel.zPosition = scoreZposition
        ballsLayer.addChild(scoreLabel)

        let action = SKAction.move(by: CGVector(dx: 0, dy: 4), duration: 0.8)
        action.timingMode = .easeInEaseOut
        scoreLabel.run(SKAction.sequence([SKAction.group([action, SKAction.fadeOut(withDuration: 0.8)]),
                                          SKAction.removeFromParent()
                                         ]))

    }

    private func animate(move: LNMove) async {
        hideSelectionIndicator(ball: move.ball)
        seletecBall = nil

        var count = 0
        let path = CGMutablePath()
        let points = move.cellList.array
        var p: CGPoint = point(column: points[count].column, row: points[count].row)
        path.move(to: p)
        count += 1

        repeat {
            p = point(column: points[count].column, row: points[count].row)
            path.addLine(to: p)
            count += 1
        } while (count < move.cellList.len)

        let duration = 0.04
        let moveAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration * Double(move.cellList.len))
        moveAction.timingMode = .easeInEaseOut

        await move.ball.sprite.run(moveAction)

        // chuyển small ball đến vị trí mới
        if let smallBall = move.smallBall, let sprite = smallBall.sprite {
            let p = point(column: move.emptyCell.column, row: move.emptyCell.row)
            let action = SKAction.sequence([SKAction.fadeOut(withDuration: duration),
                                            SKAction.move(to: p, duration: 0),
                                            SKAction.fadeIn(withDuration: duration)])
            await sprite.run(action)
        }

    }
















    private func handleMatches(balls: Set<LNBall>) -> Bool {

        guard let lastUndo = undoArr.last else {
            return false
        }

        var chains = Set<LNChain>() // những chain chứa ball ăn điểm
        for ball in balls {
            if let chain = level.removeMatchesBall(ball) as? Set<LNChain>, chain.count != 0 {
                chains.inserts(chain)
            }
        }
        lastUndo.justExplodedChains = chains

        if chains.count != 0 {
            let score = chains.reduce(0) { $0 + $1.score }
            lastUndo.justAddedScore = score
            animateMatched(chains: chains)
            return true
        } else {
            return false
        }
    }

    private func beginNextTurn() {
        guard let bigBalls: Set<LNBall> = level.addNextBigBalls() as? Set<LNBall>, let lastUndo = undoArr.last else {
            return
        }
        lastUndo.justAddedBigBalls = bigBalls
        Task {
            await animateShowBigBalls(bigBalls)
            if !handleMatches(balls: bigBalls) {
                if let smallBalls = level.addNextSmallBalls() as? Set<LNBall> {
                    if smallBalls.count == 0 {
                        // show game over
                    } else {
                        lastUndo.justAdddedSmallBalls = smallBalls
                        animateAddSmallBalls(smallBalls)
                    }
                }
            }
        }

    }

    private func tryMoveBall(_ ball: LNBall, toCell: Cell) {
        let fromCell = Cell(column: ball.column, row: ball.row)
        let cellList = level.findPath(from: fromCell, to: toCell)
        if cellList.len == 0 {
            animateInvalidMove(ball: ball)
        } else {
            let move = LNMove()
            move.ball = ball
            move.cellList = cellList

            if let smallBall = level.ball(at: toCell), !smallBall.isBigBall {
                level.temporaryRemoveSmallBall(smallBall)
                level.performMove(ball, to: toCell)
                let emptyCell = level.findEmptyCell()
                level.performMoveSmallBall(smallBall, to: emptyCell)
                move.smallBall = smallBall
                move.emptyCell = emptyCell

            } else {
                level.performMove(ball, to: toCell)
            }
            Task {
                await animate(move:move)
                if let movedBall = level.ball(at: toCell) {
                    if !handleMatches(balls: [movedBall]) {
                        beginNextTurn()
                    }
                }
            }
            let undo = Undo()
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

        if let ball = level.ball(at: cell), ball.isBigBall {
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

    override func didEvaluateActions() {

    }

}

extension GameScene {

    func undo() {
        if undoArr.isEmpty {
            return
        }
        let lastUndo = undoArr.removeLast()
        level.resetComboMultiplier()
        if lastUndo.justExplodedChains.count != 0 {
            Task {
                await animateUndoExplode(lastUndo.justExplodedChains)
                level.undoDestroy(lastUndo.justExplodedChains)
                level.revertBigBalls(toSmall: lastUndo.justAddedBigBalls)
                level.removeSmallBalls(lastUndo.justAdddedSmallBalls)
                level.performUndoMove(lastUndo.justMoved)

                animateRemoveSmallBalls(lastUndo.justAdddedSmallBalls)
                animateRevertBigBalls(lastUndo.justAddedBigBalls)
                animateUndoMove(lastUndo.justMoved)
            }
        } else {
            level.revertBigBalls(toSmall: lastUndo.justAddedBigBalls)
            level.removeSmallBalls(lastUndo.justAdddedSmallBalls)
            level.performUndoMove(lastUndo.justMoved)

            animateRemoveSmallBalls(lastUndo.justAdddedSmallBalls)
            animateRevertBigBalls(lastUndo.justAddedBigBalls)
            animateUndoMove(lastUndo.justMoved)
        }

    }

    private func animateRevertBigBalls(_ balls: Set<LNBall>) {
        let duration = 0.2
        for ball in balls {
            ball.sprite.run(SKAction.scale(to: 0.4, duration: duration))
        }
    }

    private func animateRemoveSmallBalls(_ balls: Set<LNBall>) {
        let duration = 0.2
        for ball in balls {
            let scaleAndFadeOut = SKAction.group([SKAction.scale(to: 0.1, duration: duration),
                                              SKAction.fadeOut(withDuration: duration)])

            ball.sprite.run(SKAction.sequence([scaleAndFadeOut, SKAction.removeFromParent()]))
        }
    }

    private func animateUndoMove(_ move: LNMove) {
        if let seletecBall = seletecBall {
            hideSelectionIndicator(ball: seletecBall)
            self.seletecBall = nil
            touchedCell = nil
        }

        var count = move.cellList.len - 1
        let path = CGMutablePath()
        let points = move.cellList.array

        var p: CGPoint = point(column: points[count].column, row: points[count].row)
        path.move(to: p)
        count -= 1

        repeat {
            p = point(column: points[count].column, row: points[count].row)
            path.addLine(to: p)
            count -= 1
        } while (count >= 0)

        let duration = 0.04
        let moveAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration * Double(move.cellList.len))
        moveAction.timingMode = .easeInEaseOut

        Task {
            await move.ball.sprite.run(moveAction)

            // chuyển small ball về vị trí ban đầu
            if let smallBall = move.smallBall, let sprite = smallBall.sprite {
                let endCell = move.cellList.array[move.cellList.len - 1]
                let p = point(column: endCell.column, row: endCell.row)
                let action = SKAction.sequence([SKAction.fadeOut(withDuration: duration),
                                                SKAction.move(to: p, duration: 0),
                                                SKAction.fadeIn(withDuration: duration)])
                await sprite.run(action)
            }
        }
    }

    private func animateUndoExplode(_ chains: Set<LNChain>) async {
        var set = Set<LNBall>()
        for chain in chains {
            for ball in chain.balls {
                set.insert(ball as! LNBall)
            }
        }

        let duration = 0.05
        let textureCache = LNTextureCache.sharedInstance() as! LNTextureCache

        return await withTaskGroup(of: Void.self) { group in
            for ball in set {
                ball.sprite = textureCache.sprite(withCacheName: ball.explodedSpriteName())
                ball.sprite.position = point(column: ball.column, row: ball.row)
                ball.sprite.zPosition = ballZposition
                ballsLayer.addChild(ball.sprite)

                let undoExplodeAction = SKAction.animate(with: ball.undoExplodedSpriteTextures() as! [SKTexture], timePerFrame: duration)
                group.addTask {
                    await ball.sprite.run(undoExplodeAction)
                }
            }
        }
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
        if fromPoint.x >= 0 && fromPoint.x < Double(NumColumns) * cellWidth &&
            fromPoint.y >= 0 && fromPoint.y < Double(NumRows) * cellHeight {
            let column: Int = Int(fromPoint.x / cellWidth)
            let row: Int = Int(fromPoint.y / cellHeight)
            return Cell(column: column, row: row)
        } else {
            return nil
        }
    }
}

extension LNCellList {
    var array: [Cell] {
        withUnsafePointer(to: self.cells) { tuplePtr in
            let start = tuplePtr.qpointer(to: \.0)!
            let count = MemoryLayout.size(ofValue: tuplePtr.pointee) / MemoryLayout.size(ofValue: tuplePtr.pointee.0)
            let buf = UnsafeBufferPointer(start: start, count: count)
            return [Cell](buf)
        }
    }
}

extension UnsafePointer {

    public func qpointer<Property>(to property: KeyPath<Pointee, Property>) -> UnsafePointer<Property>? {
        guard let offset = MemoryLayout<Pointee>.offset(of: property) else { return nil }
        return (UnsafeRawPointer(self) + offset).assumingMemoryBound(to: Property.self)
    }
}


class Undo {
    var justAddedBigBalls: Set<LNBall> = Set()
    var justAdddedSmallBalls: Set<LNBall> = Set()
    var justExplodedChains: Set<LNChain> = Set()
    var justMoved: LNMove = LNMove()
    var justAddedScore: UInt = 0
}
