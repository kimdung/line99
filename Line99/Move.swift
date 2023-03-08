//
//  Move.swift
//  Line99
//
//  Created by Ngoc Nguyen on 07/03/2023.
//

import Foundation

class Move: Codable {
    var ball: Ball!
    var cellList: CellList!
    var smallBall: Ball?
    var emptyCell: Cell?
}

class UndoMove: Codable {
    var justAddedBigBalls: Set<Ball> = Set()
    var justAdddedSmallBalls: Set<Ball> = Set()
    var justExplodedChains: Set<Chain> = Set()
    var justMoved: Move = Move()
    var justAddedScore: UInt = 0
}
