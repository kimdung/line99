//
//  DataSaver.swift
//  Line99
//
//  Created by Ngoc Nguyen on 07/03/2023.
//

import Foundation

extension FileManager {
    private class func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    class func saveDataToDocuments(_ data: Data, fileName: String) throws -> String {
        let fullFileName = getDocumentsDirectory().appendingPathComponent(fileName)
        try data.write(to: fullFileName, options: .atomic)
        return fullFileName.absoluteString
    }

    class func readDataFromFile(fileName: String) throws -> Data {
        let fullFileName = getDocumentsDirectory().appendingPathComponent(fileName)
        let data = try Data(contentsOf: fullFileName)
        return data
    }
}






