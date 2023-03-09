//
//  DataSaver.swift
//  Line99
//
//  Created by Ngoc Nguyen on 07/03/2023.
//

import Foundation

extension FileManager {
    private static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    static func saveDataToDocuments(_ data: Data, fileName: String) {
        let fullFileName = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try data.write(to: fullFileName, options: .atomic)
        } catch {
            print("Error = \(error)")
        }
    }

    static func readDataFromFile(fileName: String) -> Data? {
        let fullFileName = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: fullFileName)
            return data
        } catch {
            print("Error = \(error)")
        }
        return nil
    }
}






