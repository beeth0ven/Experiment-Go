//
//  HistoryManager.swift.swift
//  Experiment Go
//
//  Created by luojie on 9/11/15.
//  Copyright © 2015 LuoJie. All rights reserved.
//

import Foundation

class HistoryManager {
    
    private struct Constants {
        static let limiteBy = 10
    }
    
    var experimentSearchHistories: [String] {
        get { return iCloudKeyValueStore.arrayForKey(Key.experimentSearchHistories.rawValue) as? [String] ?? [String]() }
        set { iCloudKeyValueStore.setArray(newValue, forKey: Key.experimentSearchHistories.rawValue)  }
    }

    
    func addSearchText(text: String) {
        guard !text.isEmpty else { return }
        let lowercaseText = text.lowercaseString
        if let index = experimentSearchHistories.indexOf(lowercaseText) {
            experimentSearchHistories.removeAtIndex(index)
        }
        var histories = experimentSearchHistories
        histories.insert(lowercaseText, atIndex: 0)
        while experimentSearchHistories.count > Constants.limiteBy { experimentSearchHistories.removeLast() }
        experimentSearchHistories = histories
    }
    
    private var iCloudKeyValueStore = NSUbiquitousKeyValueStore.defaultStore()
    
    private enum Key: String {
        case experimentSearchHistories = "HistoryManager.experimentSearchHistories"
    }
}