//
//  GameViewController.swift
//  Line99
//
//  Created by Ngoc Nguyen on 02/11/2021.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    @IBOutlet weak var gridView: UIView!
    private var scene: LNGameScene!
    private var level: LNLevel = LNLevel()
    override func viewDidLoad() {
        super.viewDidLoad()

        if let cache = LNTextureCache.sharedInstance() as? LNTextureCache {
            cache.addTexture(fromPlist: "balls")
        }

        if let view = self.gridView as! SKView? {
            // Load the SKScene from 'GameScene.sks'
//            if let scene = SKScene(fileNamed: "GameScene") {
//                // Set the scale mode to scale to fit the window
//                scene.scaleMode = .aspectFill
//
//                // Present the scene
//                view.presentScene(scene)
//            }
//
//            view.ignoresSiblingOrder = true
//
//            view.showsFPS = true
//            view.showsNodeCount = true


            scene = LNGameScene.init(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            view.presentScene(scene)
            scene.addTiles()
            scene.level = level

            let block: ((_ fromPoint: LNPoint, _ toPoint: LNPoint) -> Void)  = {[weak self] fromPoint,toPoint in
                guard let self = self else { return }
                let pointList = self.level.findPath(from: fromPoint, to: toPoint)
                if pointList.len == 0 {
                    self.scene.animateInvalidMoveCompletion {

                    }
                } else {
                    let move = LNMove()
                    move.ball = self.level.ball(atColumn: fromPoint.column, row: fromPoint.row)
                    move.pointList = pointList
                    self.level.perform(move)
                    self.scene.animate(move) {

                    }
                }
            }

            scene.moveHandler = block
            beginGame()
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }


    private func beginGame() {
        shuffle()
    }

    private func shuffle() {
        scene.removeAllBallSprites()
        let newBalls = level.shuffle()
        scene.addSprites(forBalls: newBalls)
    }
}
