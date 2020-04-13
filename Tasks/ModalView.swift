//
//  ModalView.swift
//  Tasks
//
//  Created by Nick Garfitt on 11/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import Foundation
import CoreData
import SwiftUI

struct ModalView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var description: String = ""
    var due: Date
    
    var df = DateFormatter()
    
    init(_ task: Task, context: NSManagedObjectContext) {
        df.dateFormat = "EEEE, d MMM h:mm a"
        description = task.summary
        //< 3 to stop spaces counting as a description
        if description.count < 3 {
            description = "No description provided 😢"
        }
        due = task.due
    }
    
    var body: some View {
        VStack {
            /*
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Text("Dismiss")
            }.padding(.bottom, 50)
            */
            List {
                Text(df.string(from: due)).padding(20)
                Text("\(description)").lineLimit(nil).padding(20)
            }
            
        }
    }
}
