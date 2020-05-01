//
//  TaskRowModel.swift
//  Tasks
//
//  Created by Nick Garfitt on 30/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI

struct TaskRowModel: View {
    
    var task: Task
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
                Helper.shared.changeTaskStatus(task: self.task, done: !self.task.done, ctx: self.cv.context)
            }
            .padding(.trailing, 5)
            Button(action: {
                self.cv.showTaskDetails = true
            }) {
                HStack {
                    Text(self.task.title)
                        .padding(.trailing, 15)
                        .truncationMode(.tail)
                        .lineLimit(1)
                    Spacer()
                    if self.task.done {
                        Text(Helper.shared.timeBetweenDates(d1: self.task.due).0)
                        .foregroundColor(.green)
                        .bold()
                        .font(.system(size: 14))
                    }else{
                        Text(Helper.shared.timeBetweenDates(d1: task.due).0)
                        .foregroundColor((Helper.shared.timeBetweenDates(d1: self.task.due).1) ? .red : .blue)
                        .bold()
                        .font(.system(size: 14))
                    }
                }
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
