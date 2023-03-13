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

    class func saveDataToDocuments(_ data: Data, fileName: String) {
        let fullFileName = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try data.write(to: fullFileName, options: .atomic)
        } catch {
            print("Error = \(error)")
        }
    }

    class func readDataFromFile(fileName: String) -> Data? {

        let fullFileName = getDocumentsDirectory().appendingPathComponent(fileName)
//        guard FileManager.default.fileExists(atPath: fullFileName.absoluteString) else {
//            print("file not found \(fullFileName)")
//            return nil
//        }
        do {
            let data = try Data(contentsOf: fullFileName)
            return data
        } catch {
            print("Error = \(error)")
        }
        return nil
    }
}






