//
//  UserPrefs.swift
//  Tasks
//
//  Created by Nick Garfitt on 11/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import Foundation
import Combine

class UserPrefs : ObservableObject {
    
    @Published var icsURL = UserDefaults.standard.string(forKey: "icsURL") ?? "" {
        didSet {
            //print("ICS URL: " + icsURL)
        }
    }
    
    @Published var showCompleted = UserDefaults.standard.bool(forKey: "showCompleted")
    
    private var canc: AnyCancellable!
    private var canc2: AnyCancellable!

    init() {
        canc = $icsURL.debounce(for: 0.2, scheduler: DispatchQueue.main).sink { newText in
            UserDefaults.standard.set(newText, forKey: "icsURL")
        }
        canc2 = $showCompleted.debounce(for: 0.2, scheduler: DispatchQueue.main).sink { newText in
            UserDefaults.standard.set(newText, forKey: "showCompleted")
        }
    }

    deinit {
        canc.cancel()
        canc2.cancel()
    }
    
}
