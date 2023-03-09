//
//  Ball+Extension.swift
//  Line99
//
//  Created by Ngoc Nguyen on 06/03/2023.
//

import Foundation
import SpriteKit

class Ball: Codable {

    var column: Int
    var row: Int
    var ballType: Int
    var sprite: SKSpriteNode
    var spriteName: String


    private let spriteNames = [ "jump_1_1.png",
                                "jump_2_1.png",
                                "jump_3_1.png",
                                "jump_4_1.png",
                                "jump_5_1.png",
                                "jump_6_1.png",
                                "jump_7_1.png"]

    init(type: Int, column: Int, row: Int) {
        self.ballType = type
        self.column = column
        self.row = row

        let ballType = type < 0 ? -type : type
        spriteName = spriteNames[ballType - 1]
        let texture = SKTexture.init(imageNamed: spriteName)
        self.sprite = SKSpriteNode(texture: texture)
    }

    func copy() -> Ball {
        Ball(type: ballType, column: column, row: row)
    }

    private enum CodingKeys : String, CodingKey {
        case column
        case row
        case ballType
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let column = try container.decode(Int.self, forKey: .column)
        let row = try container.decode(Int.self, forKey: .row)
        let type = try container.decode(Int.self, forKey: .ballType)
        self.ballType = type
        self.column = column
        self.row = row
        let ballType = type < 0 ? -type : type
        spriteName = spriteNames[ballType - 1]
        let texture = SKTexture.init(imageNamed: spriteName)
        self.sprite = SKSpriteNode(texture: texture)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(column, forKey: .column)
        try container.encode(row, forKey: .row)
        try container.encode(ballType, forKey: .ballType)
    }
}

extension Ball: Hashable {
    static func == (lhs: Ball, rhs: Ball) -> Bool {
        return lhs.row == rhs.row &&
        lhs.column == rhs.column &&
        lhs.ballType == rhs.ballType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(column)
        hasher.combine(row)
        hasher.combine(ballType)
    }
}

extension Ball {

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

    func explodeAndRemove() async {
        let explodeAction = SKAction.animate(with: explodeSpriteTextures, timePerFrame: 0.05)
        let removeAction = SKAction.removeFromParent()
        await sprite.run(SKAction.sequence([explodeAction, removeAction]))
    }

    func prepareUndoExplode() {
        let textureArr: [SKTexture] = explodeSpriteTextures.reversed()
        sprite = SKSpriteNode(texture: textureArr.first)
    }

    func undoExplode() async {
        var textureArr: [SKTexture] = explodeSpriteTextures.reversed()
        textureArr.append(SKTexture.init(imageNamed: spriteName))
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
