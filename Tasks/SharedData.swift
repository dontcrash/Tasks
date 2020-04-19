//
//  SharedData.swift
//  Tasks
//
//  Created by Nick Garfitt on 19/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import Foundation

class SharedData {
    
    static let shared = SharedData()
    let sharedDefaults = UserDefaults(suiteName: "group.com.nick.tasks")
  
    func saveData(value: Any, key: String) {
        sharedDefaults?.setValue(value, forKey: key)
    }
    
    func retrieveData(key: String) -> Any? {
        return sharedDefaults?.value(forKey: key)
    }
    
    func removeData(key: String) {
        sharedDefaults?.removeObject(forKey: key)
    }
}
