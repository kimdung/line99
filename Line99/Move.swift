//
//  Move.swift
//  Line99
//
//  Created by Ngoc Nguyen on 07/03/2023.
//

import Foundation

class Move: Codable {
    var ball: Ball!
    var cells: [Cell] = []
    var smallBall: Ball?
    var emptyCell: Cell?

    init() {}

    init(ball: Ball!, cells: [Cell], smallBall: Ball?, emptyCell: Cell?) {
        self.ball = ball
        self.cells = cells
        self.smallBall = smallBall
        self.emptyCell = emptyCell
    }
    
}

class UndoMove: Codable {
    var justAddedBigBalls: Set<Ball> = Set()
    var justAdddedSmallBalls: Set<Ball> = Set()
    var justExplodedChains: Set<Chain> = Set()
    var justMoved: Move = Move()
    var justAddedScore: UInt = 0
}
