//
//  Task.swift
//  Tasks
//
//  Created by Nick Garfitt on 11/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import Foundation

struct Task: Identifiable {
    var id: String
    var title: String
    var description: String
    var due: Date
    var done: Bool
}
