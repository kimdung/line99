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
    private var effectNode: SKEffectNode?
    init(type: Int, column: Int, row: Int) {
        self.ballType = type
        self.column = column
        self.row = row

        let ballType = type < 0 ? -type : type
        spriteName = spriteNames[ballType - 1]
        let texture = SKTexture.init(imageNamed: spriteName)
        self.sprite = SKSpriteNode(texture: texture)
    }

    private enum CodingKeys : String, CodingKey {
        case column = "c"
        case row = "r"
        case ballType = "t"
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

    var cell: Cell {
        return Cell(column: column, row: row)
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
        effectNode?.removeFromParent()
        effectNode = nil
        let centerPoint = cell.toPoint
        let moveToCenterAction = SKAction.move(to: centerPoint, duration: 0.1)
        moveToCenterAction.timingMode = .easeInEaseOut
        sprite.run(moveToCenterAction)
    }

    /// Di chuyển ball theo danh sách cells. Giả định ball nằm ở cell đầu tiên trong danh sách
    func animateMove(cells: [Cell]) async {
        guard cells.count >= 2, // dịch chuyển tối thiểu 2 cell
              let fromCell = cells.first,
              cell == fromCell else {
            return
        }
        let path = CGMutablePath()
        path.move(to: fromCell.toPoint)

        for i in 1..<cells.count {
            path.addLine(to: cells[i].toPoint)
        }

        let duration = max(0.1, 0.04 * Double(cells.count)) // Tối thiểu 0.1 sec cho animation
        let moveAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        moveAction.timingMode = .easeInEaseOut

        await sprite.addChild(tail)
        await sprite.run(moveAction)
        await sprite.removeAllChildren()
    }

    private var tail: SKEmitterNode {
        let smoke = SKEmitterNode(fileNamed: "Smoke.sks")!
        smoke.targetNode = sprite.parent
        smoke.particleColorSequence = nil
        smoke.particleColorBlendFactor = 1
        smoke.particleBlendMode = .alpha
        smoke.particleColor = UIColor(named: "ball-color-\(ballType)") ?? .red
        return smoke
    }

    func animateShaking() {
        let duration = 0.1
        let center = cell.toPoint
        let moveRight = SKAction.moveTo(x: center.x + 3, duration: duration)
        moveRight.timingMode = .easeInEaseOut
        let moveLeft = SKAction.moveTo(x: center.x - 3, duration: duration)
        moveLeft.timingMode = .easeInEaseOut
        let moveToCenter = SKAction.moveTo(x: center.x, duration: duration)
        let shakeAction = SKAction.repeat(SKAction.sequence([moveLeft, moveRight]), count: 2)
        let action = SKAction.sequence([shakeAction, moveToCenter])
        sprite.run(action)
    }

    private var explodeSpriteTextures: [SKTexture] {
        let texttures = loadTextures(atlas: "Balls", prefix: "explode_\(ballType)_", startsAt: 1, stopsAt: 8)
        return texttures
    }

    func setupConstraints(floor: CGFloat) {
        let range = SKRange(lowerLimit: floor, upperLimit: floor)
        let lockToPlatform = SKConstraint.positionY(range)
//        constraints = [ lockToPlatform ]
    }

    func explodeAndRemove() async {
        let timePerFrame = 0.05
        let duration = timePerFrame * Double(explodeSpriteTextures.count)
        if isBig {
            let explodeAction = SKAction.animate(with: explodeSpriteTextures, timePerFrame: timePerFrame)
            let removeAction = SKAction.removeFromParent()
            await sprite.run(SKAction.sequence([explodeAction, removeAction]))
        } else {
            let scaleAndFadeOut = SKAction.group([SKAction.scale(to: 0.1, duration: duration),
                                                  SKAction.fadeOut(withDuration: duration)])
            await sprite.run(SKAction.sequence([scaleAndFadeOut, SKAction.removeFromParent()]))
        }
    }

    func prepareUndoExplode() {
        let textureArr: [SKTexture] = explodeSpriteTextures.reversed()
        sprite = SKSpriteNode(texture: textureArr.first)
    }

    func undoExplode() async {
        let timePerFrame = 0.05
        var textureArr: [SKTexture] = explodeSpriteTextures.reversed()
        textureArr.append(SKTexture.init(imageNamed: spriteName))
        let undoExplodeAction = SKAction.animate(with: textureArr, timePerFrame: timePerFrame)
        await sprite.run(undoExplodeAction)
    }

}

extension Ball {
    func loadTextures(atlas: String, prefix: String,
                      startsAt: Int, stopsAt: Int) -> [SKTexture] {
        var textureArray = [SKTexture]()
        let textureAtlas = SKTextureAtlas(named: atlas)
        for i in startsAt...stopsAt {
            let textureName = "\(prefix)\(i)"
            let temp = textureAtlas.textureNamed(textureName)
            textureArray.append(temp)
        }
        return textureArray

    }
}
