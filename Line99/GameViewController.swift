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
    private let scene = GameScene(fileNamed: "GameScene")!
    override func viewDidLoad() {
        super.viewDidLoad()

//        if let scene = GameScene(fileNamed: "GameScene") {
//            print("ok")
//        }

        if let view = self.gridView as! SKView? {
//            let scene = SKScene(fileNamed: "GameScene")!
            view.showsFPS = true
            view.showsNodeCount = true
            scene.scaleMode = .aspectFit
            view.presentScene(scene)
            beginGame()
        }
    }

    @IBAction func undoButtonOnClicked(_ sender: Any) {
        scene.undo()
    }
    @IBAction func saveButtonOnClicked(_ sender: Any) {
        scene.save()
    }

    @IBAction func restartGameButtonOnClicked(_ sender: Any) {
        scene.restartGame()
    }

    private func beginGame() {
        scene.beginGame()
    }

}


