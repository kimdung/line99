//
//  Chain.swift
//  Line99
//
//  Created by Ngoc Nguyen on 07/03/2023.
//

import Foundation

class Chain: Hashable, Codable {
    static func == (lhs: Chain, rhs: Chain) -> Bool {
        return lhs.balls == rhs.balls
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(balls)
    }

    private enum CodingKeys: String, CodingKey {
        case balls
        case chainType
        case score
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

    var balls: [Ball] = []
    var chainType: ChainType!
    var score: Int = 0

    init() {
        
    }

    func addBall(_ ball: Ball?) {
        guard let ball = ball else {
            return
        }
        balls.append(ball)
    }

}
