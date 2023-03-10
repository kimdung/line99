//
//  Cell.swift
//  Line99
//
//  Created by Ngoc Nguyen on 09/03/2023.
//

import Foundation

struct Cell: Codable, Hashable {
    var column: Int = NSNotFound
    var row: Int = NSNotFound

    static let width = 40.0
    static let height = 40.0
}

extension Cell {

    /// Tính point tâm của hàng cột tương ứng ( gốc 0,0 là left,bottom)
    /// - Parameters:
    ///   - column: cột
    ///   - row: hàng
    /// - Returns: point tâm của ô
    var toPoint: CGPoint {
        return CGPoint(x: Double(column) * Cell.width + Cell.width * 0.5,
                       y: Double(row) * Cell.height + Cell.height * 0.5)
    }

}

extension CGPoint {

    /// Chuyển từ toạ độ x,y thành cell(column,row). Gốc 0,0 là góc trái, dưới
    var toCell: Cell? {
        if x >= 0 && x < Double(Config.NumColumns) * Cell.width &&
            y >= 0 && y < Double(Config.NumRows) *  Cell.height {
            let column: Int = Int(x /  Cell.width)
            let row: Int = Int(y / Cell.height)
            return Cell(column: column, row: row)
        }
        return nil
    }
}
