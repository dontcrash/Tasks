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
    @Published var icsURL = UserDefaults.standard.string(forKey: "icsURL") ?? ""
    private var canc: AnyCancellable!

    init() {
        canc = $icsURL.debounce(for: 0.2, scheduler: DispatchQueue.main).sink { newText in
            UserDefaults.standard.set(newText, forKey: "icsURL")
        }
    }

    deinit {
        canc.cancel()
    }
}
