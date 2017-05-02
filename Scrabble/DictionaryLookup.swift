//
//  DictionaryLookup.swift
//  Scrabble
//
//  Created by Jacob Parker on 28/09/2016.
//  Copyright © 2016 Jacob Parker. All rights reserved.
//

import Foundation

class DictionaryLookup {
    var entries: [String]!

    init?(path: String) {
        guard let entries = try? String(contentsOfFile: path).components(separatedBy: "\n") else {
            return nil
        }
        self.entries = entries
    }

    func hasWord(_ word: String) -> Bool {
        return entries.contains(word)
    }
}
