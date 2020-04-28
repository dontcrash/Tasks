//
//  TaskDetailsView.swift
//  Tasks
//
//  Created by Nick Garfitt on 28/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI

struct TaskDetailsView: View {
    
    var cv: ContentView
    var task: Task
    
    var body: some View {
        NavigationView {
            List {
                Text("✏ Title")
                    .foregroundColor(Color.gray)
                    .padding(.top, 50)
                    .padding(.horizontal, 20.0)
                Text(task.title)
                    .padding([.leading, .trailing], 20)
                Divider()
                Text("🗓️ Date")
                    .foregroundColor(Color.gray)
                    .padding(.top, 20)
                    .padding(.horizontal, 20.0)
                Text(self.cv.df.string(from: task.due))
                    .padding([.leading, .trailing], 20)
                Divider()
                Text("📖 Notes")
                    .foregroundColor(Color.gray)
                    .padding(.top, 20)
                    .padding(.horizontal, 20.0)
                Text((task.summary.count > 0 ? task.summary : Helper.noDesc))
                    .padding([.leading, .trailing], 20)
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
