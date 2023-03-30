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

    private let backgroundZPostion: CGFloat = 1
    private let gridZPosition: CGFloat = 2
    private let smallBallZPosition: CGFloat = 98

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

    private var score: Int = 0 {
        didSet {
            if oldValue == score {
                return
            }
            scoreLabelNode.text = "\(score)"

            let x = frame.maxX - scoreLabelNode.frame.size.width / 2 - 5
            let moveAction = SKAction.moveTo(x: x, duration: 0)

            let scaleAction = SKAction.scale(by:  oldValue < score ? 1.2 : 0.8, duration: 0.25)
            let scaleReversedAction = scaleAction.reversed()
            let action = SKAction.sequence([moveAction, scaleAction, scaleReversedAction])
            action.timingMode = .easeInEaseOut
            scoreLabelNode.run(action)
        }
    }

    private var scoreLabelNode: SKLabelNode!
    private var movedLabel: SKLabelNode!
    private var explodedLabel: SKLabelNode!
    private var nextBall: SKNode!

    func beginGame() {
        removeAllBallSprites()
        seletecBall = nil
        touchedCell = nil
        let newBalls = ballManager.beginGame()
        addSprites(forBalls: newBalls)
        showNextBall(balls: newBalls)
    }

    func restartGame() {
        let allBalls = ballManager.allBalls
        Task {
            await withTaskGroup(of: Void.self) { group in
                for ball in allBalls {
                    group.addTask {
                        await ball.explodeAndRemove()
                    }
                }
            }

            removeAllBallSprites()
            seletecBall = nil
            touchedCell = nil
            let newBalls = ballManager.beginNewGame()
            addSprites(forBalls: newBalls)
            showNextBall(balls: newBalls)
        }
    }

    private func showNextBall(balls: Set<Ball>?) {
        guard let balls = balls else {
            nextBall.removeAllChildren()
            return
        }
        nextBall.removeAllChildren()

        let smallBalls = balls.filter { !$0.isBig }

        for (index, ball) in smallBalls.enumerated() {

            let smallBallSpriteNode = SKSpriteNode(imageNamed: ball.spriteName)

            smallBallSpriteNode.xScale = 0.5
            smallBallSpriteNode.yScale = 0.5
            smallBallSpriteNode.position = CGPoint(x: CGFloat(index * 18), y: 0)
            nextBall.addChild(smallBallSpriteNode)
        }
    }

    convenience override init() {
        self.init(fileNamed: "GameScene")!
        setupView()
        setupCombine()
    }

    override func didMove(to view: SKView) {
//        beginGame()
    }

    private func updateMovedCount(movedCnt: Int) {
        movedLabel.text = "\(movedCnt)"
    }

    private func updateExplodedCount(explodedCnt: Int) {
        explodedLabel.text = "\(explodedCnt)"
    }

    private func setupCombine() {
        ballManager.movedCount.sink { [weak self] count in
            print("moved \(count)")
            self?.updateMovedCount(movedCnt: count)

        }
        .store(in: &cancellableBag)

        ballManager.$score.sink { [weak self] value in
            self?.score = value
        }
        .store(in: &cancellableBag)

        ballManager.$explodedBalls.sink { [weak self] value in
            print("exploded balls \(value)")
            self?.updateExplodedCount(explodedCnt: value)
        }
        .store(in: &cancellableBag)

        ballManager.$gameOver.removeDuplicates().sink { [weak self] isGameOver in
            if isGameOver {
                self?.showGameOver()
            }
        }
        .store(in: &cancellableBag)

        ballManager.$comboMultiplier.removeDuplicates().sink { value in
            print("combo \(value)")
        }
        .store(in: &cancellableBag)
    }

    private func setupView() {
        scaleMode = .aspectFit
        anchorPoint = CGPointMake(0.5, 0.5)
        setupGridLayer()

        ballsLayer.position = layerPosition
        addChild(ballsLayer)
        backgroundColor = .white
        scoreLabelNode = (childNode(withName: "scoreLabel") as! SKLabelNode)
        nextBall = childNode(withName: "nextBall")
        movedLabel = (childNode(withName: "movedLabel") as! SKLabelNode)
        explodedLabel = (childNode(withName: "explodedLabel") as! SKLabelNode)
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

    private func showCombo(combo: Int) {
        if combo == 1 {
            return
        }
        let comboLabel = SKLabelNode(fontNamed: "Courier-Bold", text: "COMBO x \(combo)", fontSize: 30, textColor: .blue, shadowColor: .lightGray)


        comboLabel.zPosition = scoreZPosition
        comboLabel.verticalAlignmentMode = .center
        comboLabel.horizontalAlignmentMode = .center

        addChild(comboLabel)

        let moveUpAction = SKAction.move(by: CGVector(dx: 0, dy: 0), duration: 0.75)
        let scaleAction = SKAction.scale(to: 1.2, duration: 0.75)
        let waitAndfadeOutAction = SKAction.sequence([SKAction.wait(forDuration: 0.35), SKAction.fadeOut(withDuration: 0.4)])

        let groupActions = SKAction.group([moveUpAction, scaleAction, waitAndfadeOutAction])
        groupActions.timingMode = .easeIn

        let action = SKAction.sequence([groupActions, SKAction.removeFromParent()])
        comboLabel.run(action)
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
                group.addTask { [weak self] in
                    await self?.animateScore(forChain: chain)
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

        let scoreLabel = SKLabelNode(fontNamed: "Courier-Bold", text: "\(chain.score)", fontSize: 21, textColor: .blue, shadowColor: .lightGray)

        scoreLabel.position = chainCenterPoint
        scoreLabel.zPosition = scoreZPosition
        scoreLabel.verticalAlignmentMode = .center
        ballsLayer.addChild(scoreLabel)

        let moveUpAction = SKAction.move(by: CGVector(dx: 0, dy: 0), duration: 0.75)
        let scaleAction = SKAction.scale(to: 1.2, duration: 0.75)
        let waitAndfadeOutAction = SKAction.sequence([SKAction.wait(forDuration: 0.35), SKAction.fadeOut(withDuration: 0.4)])

        let groupActions = SKAction.group([moveUpAction, scaleAction, waitAndfadeOutAction])
        groupActions.timingMode = .easeIn

        let action = SKAction.sequence([groupActions, SKAction.removeFromParent()])
        await scoreLabel.run(action)

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

        let dict = ballManager.explodedBallsType
        print("sum \(dict.values.reduce(0, +))")

    }

    private func beginNextTurn() async {
        let bigBalls = ballManager.addNextBigBalls()
        await animateShowBigBalls(bigBalls)

        let matchedBalls = ballManager.findMatchChains(balls: bigBalls)
        if matchedBalls.isEmpty {
            let smallBalls = ballManager.addNextSmallBalls()
            showNextBall(balls: smallBalls)
            await animateAddSmallBalls(smallBalls)

        } else {
            showNextBall(balls: nil)
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
        //        test()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

}

// MARK: - Gameover
extension GameScene {
    private func showGameOver() {


        let textures = bluredScreenshotTextures()
//        let bgNode = SKSpriteNode(texture: textures.first)
//        bgNode.zPosition = 9999
//        addChild(bgNode)
//        let blurAction = SKAction.animate(with: textures, timePerFrame: 0.05)
//        let removeAction = SKAction.removeFromParent()
//        bgNode.run(SKAction.sequence([blurAction]))
        let gameOver = GameOver(gameScene: self, backgroundTextures: textures)
        gameOver.scaleMode = .aspectFit
        view?.presentScene(gameOver)


//        let gameOver = GameOver()
//        gameOver.parrentScene = self
//        gameOver.scaleMode = .aspectFit
//        let transition = SKTransition.fade(with: .white, duration: 0.5)
//        view?.presentScene(gameOver, transition: transition)


//        let filter = CIFilter(name: "CIGaussianBlur")
//        filter?.setValue(3, forKey: kCIInputRadiusKey)
//        self.filter = filter
//        self.shouldEnableEffects = true
//        self.shouldRasterize = false

//        addChild(gameOver)
//
//        let duration = 1.0
//
//           let pauseBG:SKSpriteNode = self.getBluredScreenshot()
//
//           pauseBG.alpha = 0
//           pauseBG.zPosition = 1000 + self.zPosition + 1
//           pauseBG.run(SKAction.fadeAlpha(to: 1, duration: duration))
//
//           self.addChild(pauseBG)
//        let pauseBg = getBluredScreenshot()
//        addChild(pauseBg)
    }

    private func bluredScreenshotTextures() -> [SKTexture] {
        guard let filter = CIFilter(name: "CIGaussianBlur") else {
            return []
        }

        var textures: [SKTexture] = []
        self.shouldEnableEffects = true

        for i in 1...10 {
            filter.setValue(i, forKey: kCIInputRadiusKey)
            self.filter = filter
            let texture = view?.texture(from: self)
            textures.append(texture!)
        }
//        filter.setValue(0, forKey: kCIInputRadiusKey)
        self.filter = nil
        return textures
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

            showNextBall(balls: ballManager.allBalls)
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

//
//
//class BlurCropNode: SKCropNode {
//    var blurNode: BlurNode
//    var size: CGSize
//    init(size: CGSize) {
//        self.size = size
//        blurNode = BlurNode(radius: 10)
//        super.init()
//        addChild(blurNode)
//        let mask = SKSpriteNode (color: UIColor.black, size: size)
//        mask.anchorPoint = CGPoint.zero
//        maskNode = mask
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//class BlurNode: SKEffectNode {
//    var sprite: SKSpriteNode
//    var texture: SKTexture {
//        get { return sprite.texture! }
//        set {
//            sprite.texture = newValue
//            let scale = UIScreen.main.scale
//            let textureSize = newValue.size()
//            sprite.size = CGSizeMake(textureSize.width/scale, textureSize.height/scale)
//        }
//    }
//
//    init(radius: CGFloat) {
//        sprite = SKSpriteNode()
//        super.init()
//        sprite.anchorPoint = CGPointMake(0, 0)
//        addChild(sprite)
//        filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": radius])
//        shouldEnableEffects = true
//        shouldRasterize = true
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
