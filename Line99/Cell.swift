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
}

extension Cell {

    /// Tính point tâm của hàng cột tương ứng ( gốc 0,0 là left,bottom)
    /// - Parameters:
    ///   - column: cột
    ///   - row: hàng
    /// - Returns: point tâm của ô
    var toPoint: CGPoint {
        return CGPoint(x: Double(column) * Config.CellWidth + Config.CellWidth * 0.5,
                       y: Double(row) * Config.CellHeight + Config.CellHeight * 0.5)
    }

}

extension CGPoint {

    /// Chuyển từ toạ độ x,y thành cell(column,row). Gốc 0,0 là góc trái, dưới
    var toCell: Cell? {
        if x >= 0 && x < Double(Config.NumColumns) * Config.CellWidth &&
            y >= 0 && y < Double(Config.NumRows) * Config.CellHeight {
            let column: Int = Int(x / Config.CellWidth)
            let row: Int = Int(y / Config.CellHeight)
            return Cell(column: column, row: row)
        }
        return nil
    }
}
