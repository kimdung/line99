//
//  Chain.swift
//  Line99
//
//  Created by Ngoc Nguyen on 07/03/2023.
//

import Foundation

class Chain:  Codable {
    private enum CodingKeys: String, CodingKey {
        case balls = "bs"
        case chainType = "ct"
        case score = "s"
    }

    enum ChainType: Int {
        case ChainType_0
        case ChainType_45
        case ChainType_90
        case ChainType_135
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let balls = try container.decode([Ball].self, forKey: .balls)
        let type = try container.decode(Int.self, forKey: .chainType)
        let chainType = ChainType(rawValue: type)
        let score = try container.decode(Int.self, forKey: .score)
        self.balls = balls
        self.chainType = chainType
        self.score = score
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(balls, forKey: .balls)
        try container.encode(chainType.rawValue, forKey: .chainType)
        try container.encode(score, forKey: .score)
    }

    private(set) var balls: [Ball] = []
    var chainType: ChainType!
    var score: Int = 0

    init() {}

    var ballType: Int {
        guard let firstBall = balls.first else {
            print("invalid chain")
            return 0
        }
        return firstBall.ballType
    }

    var ballCount: Int {
        var set: Set<Ball> = Set()
        set.inserts(Set(balls))
        return set.count
    }

    func addBall(_ ball: Ball?) {
        guard let ball = ball else {
            return
        }
        let newBall = Ball(type: ball.ballType, column: ball.column, row: ball.row)
        balls.append(newBall)
    }

}

extension Chain: Hashable {
    static func == (lhs: Chain, rhs: Chain) -> Bool {
        return lhs.balls == rhs.balls
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(balls)
    }
}
