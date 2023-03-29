//
//  GameOver.swift
//  Line99
//
//  Created by Ngoc Nguyen on 17/03/2023.
//

import Foundation
import SpriteKit

class GameOver: SKScene {
    var testLabel: SKLabelNode?

    private var gameScene: GameScene!
    private var backgroundTextures: [SKTexture]!
    private var backgroundNode: SKSpriteNode!

    convenience init(gameScene: GameScene, backgroundTextures: [SKTexture]) {
        self.init(fileNamed: "GameOver")!
        self.gameScene = gameScene
        self.backgroundTextures = backgroundTextures
    }


    override func didMove(to view: SKView) {
        print("did move to view")
        backgroundNode = childNode(withName: "backgroundNode")! as? SKSpriteNode
        backgroundNode.texture = backgroundTextures.first

        let blurAction = SKAction.animate(with: backgroundTextures, timePerFrame: 0.05)
        let scaleAction = SKAction.scale(by: 1, duration: 0.05 * Double(backgroundTextures.count))
        backgroundNode.run(SKAction.group([blurAction, scaleAction]))
    }


    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        if let gameScene = gameScene {
            Task {

                let unblurAction = SKAction.animate(with: backgroundTextures.reversed(), timePerFrame: 0.05)
                await backgroundNode.run(unblurAction)

                gameScene.scaleMode = .aspectFit
                let transition = SKTransition()
                view?.presentScene(gameScene, transition: transition)
                gameScene.restartGame()
            }
        }

    }
}


extension SKReferenceNode {
    func getBasedChildNode () -> SKNode? {
        if let child = self.children.first?.children.first {return child}
        else {return nil}
    }
}

extension SKNode {
    func nodeReferenced() -> SKNode? {
        if self.isKind(of: SKReferenceNode.self) {
            return children.first!.children.first!
        }
        return nil
    }
}
