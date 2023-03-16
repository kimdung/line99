//
//  GameScene.swift
//  Line99
//
//  Created by Ngoc Nguyen on 02/11/2021.
//

import SpriteKit
import GameplayKit
import Combine

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

    private var isBusy = false

    private let invalidMoveSound: SKAction = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    private let moveSound: SKAction = SKAction.playSoundFileNamed("move.wav", waitForCompletion: false)
    private let destroySound: SKAction = SKAction.playSoundFileNamed("destroy.wav", waitForCompletion: false)
    private let jumpingSound: SKAction = SKAction.playSoundFileNamed("jump.wav", waitForCompletion: false)

    private var seletecBall: Ball?

    private var touchedCell: Cell? = nil

    private static let headerHeight = 60.0
    private let layerPosition = CGPointMake(-Cell.width * Double(Config.NumColumns) / 2, -Cell.height * Double(Config.NumRows) / 2 - headerHeight/2)

    private var cancellableBag = Set<AnyCancellable>()
    /*    override init() {
        let size = CGSize(width: 360, height: 400)
        super.init(size: size)

        // Đặt center của scene là toạ độ gốc
        anchorPoint = CGPointMake(0.5, 0.5)

//        let layerPostion = CGPointMake(-Cell.width * Double(Config.NumColumns) / 2, -Cell.height * Double(Config.NumRows) / 2)

        setupGridLayer()

        ballsLayer.position = layerPosition
        addChild(ballsLayer)
        backgroundColor = .white

    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    */


    private var score: Int = 0 {
        didSet {
            scoreLabelNode.text = "\(score)"

            let x = frame.maxX - scoreLabelNode.frame.size.width / 2 - 5
            let moveAction = SKAction.moveTo(x: x, duration: 0)

            let scaleUpAction = SKAction.scale(by:  oldValue < score ? 1.2 : 0.8, duration: 0.25)
            let scaleDownAction = scaleUpAction.reversed()
            let action = SKAction.sequence([moveAction, scaleUpAction, scaleDownAction])
            action.timingMode = .easeInEaseOut
            scoreLabelNode.run(action)
        }
    }

    private var scoreLabelNode: SKLabelNode!
    private var timerLabel: SKLabelNode!


    func beginGame() {
        removeAllBallSprites()
        seletecBall = nil
        touchedCell = nil
        let newBalls = ballManager.beginGame()
        addSprites(forBalls: newBalls)
    }

    func restartGame() {
        removeAllBallSprites()
        seletecBall = nil
        touchedCell = nil
        let newBalls = ballManager.beginNewGame()
        addSprites(forBalls: newBalls)
        updateTimerLabel()
    }

    override func didMove(to view: SKView) {
        setupView()
//        updateTimer()

        ballManager.movedCount.sink { count in
            print("moved \(count)")
        }
        .store(in: &cancellableBag)

        ballManager.$score.sink { value in
            self.score = value
        }
        .store(in: &cancellableBag)

        ballManager.$explodedBalls.sink { value in
            print("exploded balls \(value)")
        }
        .store(in: &cancellableBag)

        ballManager.$gameOver.removeDuplicates().sink { isGameOver in
            if isGameOver {
                self.removeAction(forKey: "updateTimer")
            } else {
                self.updateTimer()
            }
        }
        .store(in: &cancellableBag)
    }

    func secondsToHoursMinutesSeconds(_ seconds: Int) -> (hours: Int, minutes: Int, seconds: Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    private func updateTimer() {
        let updateTimerAction = SKAction.run { [weak self] in
            self?.updateTimerLabel()
        }
        let waitAction = SKAction.wait(forDuration: 1)
        run(SKAction.repeatForever(SKAction.sequence([updateTimerAction, waitAction])), withKey: "updateTimer" )
    }

    private func updateTimerLabel() {
        let duration = secondsToHoursMinutesSeconds(Int(ballManager.playDuration))

        var text = String(format: "%02d:%02d", duration.hours, duration.minutes)

        if duration.hours == 0 {
            text = String(format: "%02d:%02d", duration.minutes, duration.seconds)
        }
        timerLabel.text = text
    }

    private func setupView() {
        anchorPoint = CGPointMake(0.5, 0.5)
        setupGridLayer()

        ballsLayer.position = layerPosition
        addChild(ballsLayer)
        backgroundColor = .white
        scoreLabelNode = (childNode(withName: "scoreLabel") as! SKLabelNode)
        timerLabel = (childNode(withName: "timerLabel") as! SKLabelNode)

    }

    /// Vẽ lưới 9x9 trên màn hình
    private func setupGridLayer() {
        let gridLayer = SKNode()
        gridLayer.position = layerPosition
        gridLayer.zPosition = gridZPosition
        addChild(gridLayer)

        for col in 0...Config.NumColumns {
            let verticalLine = SKShapeNode()
            verticalLine.zPosition = gridZPosition
            let pathToDraw = CGMutablePath()
            pathToDraw.move(to: CGPoint(x: col * Int(Cell.width), y: 0))
            pathToDraw.addLine(to:CGPoint(x: col * Int(Cell.width), y: Config.NumRows * Int(Cell.height)))
            verticalLine.path = pathToDraw
            verticalLine.strokeColor = SKColor.lightGray
            verticalLine.lineWidth = 1
            gridLayer.addChild(verticalLine)
        }

        for row in 0...Config.NumRows {
            let horizontalLine = SKShapeNode()
            horizontalLine.zPosition = gridZPosition
            let pathToDraw = CGMutablePath()
            pathToDraw.move(to: CGPoint(x: 0, y: row * Int(Cell.height) ))
            pathToDraw.addLine(to:CGPoint(x: Config.NumColumns * Int(Cell.width), y: row * Int(Cell.height)))
            horizontalLine.path = pathToDraw
            horizontalLine.strokeColor = SKColor.lightGray
            horizontalLine.lineWidth = 1
            gridLayer.addChild(horizontalLine)
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

        await withTaskGroup(of: Void.self) { group in
            var score = 0
            for chain in chains {
                score += chain.score
                group.addTask {
                    await self.animateScore(forChain: chain)
                }
            }

            for ball in set {
                group.addTask {
                    await ball.explodeAndRemove()
                }
            }

        }
    }


    /// Hiển thị score của chain
    /// - Parameter chain: chuỗi các ball ăn điểm
    private func animateScore(forChain chain: Chain) async {
        guard let firstCell = chain.balls.first?.cell, let lastCell = chain.balls.last?.cell else {
            return
        }

        guard let firstBall = ballManager.ballAt(cell: firstCell), let lastBall = ballManager.ballAt(cell: lastCell) else {
            return
        }

        let chainCenterPoint = CGPointMake((firstBall.sprite.position.x + lastBall.sprite.position.x) / 2,
                                      (firstBall.sprite.position.y + lastBall.sprite.position.y) / 2)

        let scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold", text: "\(chain.score)", fontSize: 20, textColor: .blue, shadowColor: .lightGray)

        scoreLabel.position = chainCenterPoint
        scoreLabel.zPosition = scoreZPosition
        scoreLabel.verticalAlignmentMode = .center
//        scoreLabel.addStroke(color: .lightGray, width: 4)
        ballsLayer.addChild(scoreLabel)
//        scoreLabelNode.text = "\(chain.score)"
//
//        let outlinelbl = LFOutlinedLabel(size: CGSize(width: 80, height: 40), font: "Courier-Bold", fSize: 20, fColor: .yellow, bSize: 2, bColor: .black, bOpacity: 0.8)
//
//        outlinelbl.text = "Test"
//        outlinelbl.update()
//        outlinelbl.position = centerPoint
//        ballsLayer.addChild(outlinelbl)

        let moveUpAction = SKAction.move(by: CGVector(dx: 0, dy: 0), duration: 0.75)
        let scaleAction = SKAction.scale(to: 1.2, duration: 0.75)
        let waitAndfadeOutAction = SKAction.sequence([SKAction.wait(forDuration: 0.35), SKAction.fadeOut(withDuration: 0.4)])

        let groupActions = SKAction.group([moveUpAction, scaleAction, waitAndfadeOutAction])
        groupActions.timingMode = .easeIn


        let action = SKAction.sequence([groupActions, SKAction.removeFromParent()])
        await scoreLabel.run(action)
//        scoreLabel.run(SKAction.sequence([SKAction.group([action, SKAction.fadeOut(withDuration: 0.8)])
//                                          SKAction.removeFromParent()
//                                         ]))

    }

    private func animate(move: Move) async {

        guard let beginCell = move.cells.first, let endCell = move.cells.last, let ball = ballManager.ballAt(cell: beginCell) else {
            return
        }

        hideSelectionIndicator(ball: ball)
        seletecBall = nil

        await ball.animateMove(cells: move.cells)

        if let smallBallCell = move.smallBallCell, let smallBall = ballManager.ballAt(cell: endCell) {
            let sprite = smallBall.sprite
            let p = smallBallCell.toPoint
            let action = SKAction.sequence([SKAction.fadeOut(withDuration: 0),
                                            SKAction.move(to: p, duration: 0),
                                            SKAction.fadeIn(withDuration: 0.2)])
            await sprite.run(action)
        }

    }

    private func beginNextTurn() async {
        let bigBalls = ballManager.addNextBigBalls()
        await animateShowBigBalls(bigBalls)

        let matchedBalls = ballManager.findMatchChains(balls: bigBalls)
        if matchedBalls.isEmpty {
            let smallBalls = ballManager.addNextSmallBalls()
            await animateAddSmallBalls(smallBalls)
        } else {
            await animateMatched(chains: matchedBalls)
            ballManager.removeMatcheBalls(chains: matchedBalls)
        }
    }

    private func tryMoveBall(_ ball: Ball, toCell: Cell) {
        let fromCell = ball.cell
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
                    let matchedBalls = ballManager.findMatchChains(balls: [movedBall])
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
        if isBusy && seletecBall != nil {
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

    func save() {
        ballManager.save()
    }

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
                var score = 0
                for chain in lastUndo.justExplodedChains {
                    score += chain.score
                }
                self.score -= score

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

        let cells: [Cell] = move.cells.reversed()
        await ball.animateMove(cells: cells)


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
