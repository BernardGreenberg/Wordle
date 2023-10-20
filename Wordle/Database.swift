//
//  Database.swift
//  Wordle
//
//  Created by Bernard Greenberg on 10/4/23.
//

import Foundation

enum WordleDatabaseError: Error {
    case resourceError(String, String)
}

class Database {
    var Data : Set<String> = []
    var Path : String!
    init? (_ path: String) throws {
        try open(path)
    }

    init? (resourceName: String) throws {
        try openResource(resourceName)
    }
    
    func contains(word : String) -> Bool {
        return Data.contains(word)
    }
    
    func chooseRandom () -> String {
        return Data.randomElement()!
    }
    
    func merge (_ other: Database) {
        for item in other.Data {
            if !Data.contains(item) { // of course, not strictly necessary
                Data.insert(item)
            }
        }
    }
    
    func openResource(_ resourceName: String) throws {
        let path = Bundle.main.path(forResource: resourceName, ofType:nil)
        if (path == nil) {
            throw WordleDatabaseError.resourceError("Can't find resource:", resourceName)
        }
        try open(path!)
    }
    
    func open (_ path: String) throws {
        try openURL(fileURL: URL(fileURLWithPath: path))
    }
       
    func openURL(fileURL: URL) throws {
        let whole_file = try String(contentsOf: fileURL, encoding: .utf8)
        // https://stackoverflow.com/questions/32021712/how-to-split-a-string-by-new-lines-in-swift
        for line in whole_file.split(whereSeparator: \.isNewline) {
            let commasplits = line.components(separatedBy: ",")
            if commasplits.count == 1 {
                Data.insert(commasplits[0])
            }
            else if commasplits.count == 3 {
                if commasplits[2] == "" {
                    Data.insert(commasplits[0])
                }
            }
        }
//        print (path as Any, Data.count, "usable words.")
    }
}
