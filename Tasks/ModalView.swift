//
//  ModalView.swift
//  Tasks
//
//  Created by Nick Garfitt on 11/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import Foundation
import SwiftUI

struct ModalView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var description: String = ""
    var task: Task!
    
    var df = DateFormatter()
    
    init(_description: String, _tasks: [Task], _id: String) {
        df.dateFormat = "EEEE, d MMM h:mm a"
        for t in _tasks {
            if t.id == _id {
                task = t
                break
            }
        }
        description = task.description
        let arr = description.split(separator: "\r\n")
        var fullStr: String = ""
        for str in arr {
            if str.starts(with: " ") {
                fullStr.append(contentsOf: str.dropFirst())
            }else{
                fullStr.append(contentsOf: str)
            }
        }
        description = fullStr
        description = description.replacingOccurrences(of: "\\n\\n", with: "\n\n")
        description = description.replacingOccurrences(of: "\\n", with: "\n")
        description = description.replacingOccurrences(of: "\\", with: "")
        //< 3 to stop spaces counting as a description
        if description.count < 3 {
            description = "No description provided 😢"
        }
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
                Text(df.string(from: task.due)).padding(20)
                Text("\(description)").lineLimit(nil).padding(20)
            }
            
        }
    }
}
