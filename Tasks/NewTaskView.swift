//
//  AddTaskView.swift
//  Tasks
//
//  Created by Nick Garfitt on 29/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI

struct NewTaskView: View {
    
    var cv: ContentView
    
    let dg = DragGesture()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add task")
            }
            .navigationBarItems(trailing: (
                Button(action: {
                    self.cv.showNewTask = false
                }) {
                    ZStack {
                        Rectangle()
                            .fill(Color.init(hex: 000000, alpha: 0.0001))
                            .frame(width: 70, height: 35)
                        Text("Done")
                    }
                }
            ))
            .navigationBarTitle("New Task", displayMode: .inline)
        }
    }
    
}

struct NewTaskView_Previews: PreviewProvider {
    static var previews: some View {
        NewTaskView(cv: ContentView())
    }
}
