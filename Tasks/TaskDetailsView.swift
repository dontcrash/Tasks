//
//  TaskDetailsView.swift
//  Tasks
//
//  Created by Nick Garfitt on 28/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI

struct TaskDetailsView: View {
    
    let padding: CGFloat = 10
    var cv: ContentView
    var task: Task
    
    var body: some View {
        NavigationView {
            List {
                Text("✏ Title")
                    .foregroundColor(Color.gray)
                    .padding(.top, 50)
                    .padding(.horizontal, padding)
                Text(task.title)
                    .padding(.horizontal, 20)
                Divider().padding(.horizontal, 20)
                Text("🗓️ Date")
                    .foregroundColor(Color.gray)
                    .padding(.top, padding)
                    .padding(.horizontal, 20)
                Text(self.cv.df.string(from: task.due))
                    .padding(.horizontal, 20)
                Divider().padding(.horizontal, 20)
                Text("📖 Notes")
                    .foregroundColor(Color.gray)
                    .padding(.top, padding)
                    .padding(.horizontal, 20)
                Text((task.summary.count > 0 ? task.summary : Helper.noDesc))
                    .padding(.horizontal, 20)
            }
            .onAppear { UITableView.appearance().separatorStyle = .none }
            .navigationBarItems(trailing: (
                Button(action: {
                    self.cv.showTaskDetails = false
                }) {
                    ZStack {
                        Rectangle()
                            .fill(Color.init(hex: 000000, alpha: 0.0001))
                            .frame(width: 70, height: 35)
                        Text("Done")
                    }
                }
            ))
            .navigationBarTitle("Details", displayMode: .inline)
        }
    }
    
}
