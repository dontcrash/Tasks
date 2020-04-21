//
//  taskModel.swift
//  Tasks
//
//  Created by Nick Garfitt on 21/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import Foundation

class taskModel: Codable, Identifiable {
    
    var title: String = ""
    var due: Date = Date()

}
