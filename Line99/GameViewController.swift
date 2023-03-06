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
    private var scene: GameScene!
//    private var level: LNLevel = LNLevel()
    override func viewDidLoad() {
        super.viewDidLoad()


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


//            scene = LNGameScene.init(size: view.bounds.size)
//            scene.scaleMode = .aspectFill
////            view.presentScene(scene)
//            scene.addTiles()
//            scene.level = level

            scene = GameScene(size: CGSize(width: 360, height: 360))
//            scene.level = level

            scene.scaleMode = .aspectFill
            view.presentScene(scene)

          

//            scene.moveHandler = block
            beginGame()
        }
    }

    @IBAction func undoButtonOnClicked(_ sender: Any) {
        scene.undo()
    }
    /*
    private func beginNextTurn() {
        let bigBallSet = level.addNextBigBalls()
        scene.animateAddNew(bigBalls: bigBallSet! as NSSet) { [weak self] in
            guard let self = self else { return }
            if (!self.handleMathes(balls: bigBallSet! as! Set<LNBall>)) {
                let smallBallSet = self.level.addNextSmallBalls()
                if smallBallSet?.count == 0 {
                    // game over
                } else {
                    self.scene.animateAddNew(smallBalls: smallBallSet! as NSSet)
                }
            }
        }
    }

    private func handleMathes(balls: Set<LNBall>) -> Bool {
        var foundLine = false
        var removedChains = Set<LNChain>()
        for ball in balls {
            if let chains = level.removeMatchesBall(ball) {
                if chains.count != 0 {
                    // undo
                    foundLine = true
                    removedChains.inserts(chains as! Set<LNChain>)
                }
            }
        }

        if foundLine {
            var addScore:UInt = 0
            for chain in removedChains {
                addScore += chain.score
            }
            scene.animateMatched(chains: removedChains) {

            }
            return true
        }
        return false
    }
    */

//    override var shouldAutorotate: Bool {
//        return true
//    }
//
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            return .allButUpsideDown
//        } else {
//            return .all
//        }
//    }

//    override var prefersStatusBarHidden: Bool {
//        return true
//    }


    private func beginGame() {
        scene.startGame()
    }

}

extension Set {



    mutating func inserts(_ elements: Set<Element>) {
        for element in elements {
            insert(element)
        }
    }
}
