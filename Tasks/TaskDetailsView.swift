//
//  TaskDetailsView.swift
//  Tasks
//
//  Created by Nick Garfitt on 28/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI

struct TaskDetailsView: View {
    
    var task: Task
    var df: DateFormatter
    
    var body: some View {
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
            Text(self.df.string(from: task.due))
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
        .navigationBarTitle(Text("Details"))
    }
    
}
