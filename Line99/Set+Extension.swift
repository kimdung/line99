//
//  Set+Extension.swift
//  Line99
//
//  Created by Ngoc Nguyen on 10/03/2023.
//

import Foundation

extension Set {
    mutating func inserts(_ elements: Set<Element>) {
        for element in elements {
            insert(element)
        }
    }
}
