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
                VStack(alignment: .leading) {
                    HStack {
                        //pencil
                        //info
                        //textformat
                        //doc.text
                        Image(systemName: "doc.text")
                                .foregroundColor(Color.gray)
                        Text("Title")
                            .foregroundColor(Color.gray)
                    }
                    .padding(.bottom, padding/2)
                    Text(task.title)
                }
                .padding(.horizontal, padding*2)
                .padding(.top, padding*4.5)
                Divider().padding(.horizontal, padding*2)
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "calendar")
                                .foregroundColor(Color.gray)
                        Text("Date")
                            .foregroundColor(Color.gray)
                    }
                    .padding(.bottom, padding/2)
                    Text(self.cv.df.string(from: task.due))
                }
                .padding(.horizontal, padding*2)
                Divider().padding(.horizontal, padding*2)
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "book")
                                .foregroundColor(Color.gray)
                        Text("Notes")
                            .foregroundColor(Color.gray)
                    }
                    .padding(.bottom, padding/2)
                    Text((task.summary.count > 0 ? task.summary : Helper.noDesc))
                }
                .padding(.bottom, padding*2)
                .padding(.horizontal, padding*2)
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

struct TaskDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let task: Task = Task()
        task.title = "Title"
        task.due = Date()
        task.summary = "Title"
        return TaskDetailsView(cv: ContentView(), task: task)
    }
}
