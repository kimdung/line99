//
//  Ball+Extension.swift
//  Line99
//
//  Created by Ngoc Nguyen on 06/03/2023.
//

import Foundation
import SpriteKit

extension LNBall {
    var isBig: Bool {
        return ballType > 0
    }



    func animateJumping() {
        let moveUpAction = SKAction.moveBy(x: 0, y: 3, duration: 0.18)
        moveUpAction.timingMode = .easeIn
        let moveDownAction = SKAction.moveBy(x: 0, y: -3, duration: 0.18)
        moveUpAction.timingMode = .easeOut
        let jumpingAction = SKAction.repeatForever(SKAction.sequence([moveUpAction, moveDownAction]))
        sprite.run(jumpingAction, withKey: "jumping")

    }

    func stopJumping() {
        sprite.removeAction(forKey: "jumping")
    }

    func animateShaking() {
        let duration = 0.1
        let moveRight = SKAction.moveBy(x: 4, y: 0, duration: duration)
        moveRight.timingMode = .easeInEaseOut
        let moveLeft = SKAction.moveBy(x: -4, y: 0, duration: duration)
        moveLeft.timingMode = .easeInEaseOut
        let shakeAction = SKAction.repeat(SKAction.sequence([moveLeft, moveRight]), count: 2)
        sprite.run(shakeAction)
    }

    private var explodeSpriteTextures: [SKTexture] {
        var textureArr = [SKTexture]()
        for i in 1..<9 {
            let name = "explode_\(ballType)_\(i).png"
            let texture = SKTexture(imageNamed: name)
            textureArr.append(texture)
        }
        return textureArr
    }

    func explodeAndRemove() {
        let explodeAction = SKAction.animate(with: explodeSpriteTextures, timePerFrame: 0.05)
        let removeAction = SKAction.removeFromParent()
        sprite.run(SKAction.sequence([explodeAction, removeAction]))
    }

    func prepareUndoExplode() {
        let textureArr: [SKTexture] = explodeSpriteTextures.reversed()
        sprite = SKSpriteNode(texture: textureArr.first)
    }

    func undoExplode() async {
        var textureArr: [SKTexture] = explodeSpriteTextures.reversed()
        textureArr.append(SKTexture.init(imageNamed: spriteName))
//        guard let firstTexture = textureArr.first else {
//            return
//        }
//        sprite = SKSpriteNode(texture: firstTexture)
        let undoExplodeAction = SKAction.animate(with: textureArr, timePerFrame: 0.05)
        await sprite.run(undoExplodeAction)
    }
//    var spriteNode: SKSpriteNode {
//        get {
//            let texture = SKTexture.init(imageNamed: spriteName())
//            let node = SKSpriteNode(texture: texture)
//            return node
//        }
//    }
//    - (void)animateShake {
//
//    }
//
//    - (void)animateJumping {
//        SKAction *moveUpAction = [SKAction moveByX:0 y:3 duration:0.18];
//        moveUpAction.timingMode = SKActionTimingEaseOut;
//        SKAction *moveDownAction = [moveUpAction reversedAction];
//        SKAction *upDownAction = [SKAction repeatActionForever:[SKAction sequence:@[moveUpAction, moveDownAction]]];
//        [self.sprite runAction:upDownAction withKey:@"jumping"];
//    }
//
//    - (void)stopJumping {
//
//    }
}
