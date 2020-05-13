//
//  TaskRowModel.swift
//  Tasks
//
//  Created by Nick Garfitt on 30/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI

struct TaskRowModel: View {
    
    @State var task: Task
    var cv: ContentView
    
    var body: some View {
        
        HStack {
            ZStack {
                Image(systemName: self.task.done ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color.gray)
                Rectangle()
                    .fill(Color.init(hex: 000000, alpha: 0.0001))
                    .frame(width: 30, height: 30)
            }
            .onTapGesture {
                let status: Bool = !self.task.done
                Helper.shared.changeTaskStatus(task: self.task, done: status, ctx: self.cv.context)
                Helper.lastTask = self.task
                withAnimation {
                    self.cv.showUndo = true
                    Helper.lastShownUndo = Date()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                    if Helper.shared.secondsBetweenDates(d1: Helper.lastShownUndo) <= -5 {
                        withAnimation {
                            self.cv.showUndo = false
                        }
                    }
                }
                self.cv.generator.notificationOccurred(.success)
            }
            .padding(.trailing, 5)
            Button(action: {
                self.cv.showTaskDetails = true
            }) {
                TaskRowView(task: task)
            }
            .sheet(isPresented: self.cv.$showTaskDetails) {
                TaskDetailsView(cv: self.cv, task: self.task, dismiss: { self.cv.showTaskDetails = false })
            }
            .onDisappear { UITableView.appearance().separatorStyle = .singleLine }
        }
        .deleteDisabled(!self.task.manual)
        //.listRowInsets(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 15))
        .listRowBackground(Color(UIColor.systemGray6))
        .padding(.vertical, 14)
    }
    
}
