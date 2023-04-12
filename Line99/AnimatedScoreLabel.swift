//
//  AnimatedScoreLabel.swift
//  Line99
//
//  Created by Ngoc Nguyen on 10/04/2023.
//

import Foundation
import SpriteKit

class AnimatedScoreLabel: SKLabelNode {

    var score: Int = 0 {
        didSet {
            updateDisplay()
        }
    }

    private let step = 1
    private let animationDelay = 0.02
    private let animationKey = "AnimaitonKey"
    private var currentScore: Int = 0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        fontName = "Arial"
        fontColor = .blue
        text = "0"
        horizontalAlignmentMode = .right
        verticalAlignmentMode = .center

    }

    @objc private func updateDisplay() {
        if score != currentScore {
            let wait = SKAction.wait(forDuration: animationDelay)
            let update = SKAction.run { [weak self] in
                guard let self = self else { return }
                self.currentScore = self.computeNextScore()
                self.text = String(format: "%i", self.currentScore)
            }
            let checkAgainAction = SKAction.perform(#selector(updateDisplay), onTarget: self)
            self.run(SKAction.sequence([wait, update, checkAgainAction]), withKey: animationKey)
        } else {
            removeAction(forKey: animationKey)
        }
    }


    private func computeNextScore() -> Int {
        var next: Int
        if score > currentScore {
            if currentScore >= 0 {
                next = ((currentScore + step) / step) * step
            } else {
                next = ((currentScore + 1) / step) * step
            }
            if next > score {
                next = score
            }
        } else if score < currentScore {
            if currentScore <= 0 {
                next = ((currentScore - step) / step) * step
            } else {
                next = ((currentScore - 1) / step) * step
            }
            if next < score {
                next = score
            }
        } else {
            next = score
        }
        return next
    }
}
