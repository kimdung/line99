//
//  Move.swift
//  Line99
//
//  Created by Ngoc Nguyen on 07/03/2023.
//

import Foundation

struct Move: Codable {
    /// Danh sách cell chứa đường đi
    var cells: [Cell] = []

    /// Nếu điểm đến có small ball thì đưa small ball đến small cell
    var smallBallCell: Cell?

}

class UndoMove: Codable {
    var justAddedBigBalls: Set<Cell> = Set()
    var justAdddedSmallBalls: Set<Cell> = Set()
    var justExplodedChains: Set<Chain> = Set()
    var justMoved: Move = Move()
}
