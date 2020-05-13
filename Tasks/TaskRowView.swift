//
//  TaskRowView.swift
//  Tasks
//
//  Created by Nick Garfitt on 13/5/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI

struct TaskRowView: View {
    
    @State var task: Task
    
    var body: some View {
        HStack {
            Text(self.task.title)
                .padding(.trailing, 15)
                .truncationMode(.tail)
                .lineLimit(1)
            Spacer()
            if self.task.done {
                Text(Helper.shared.niceDateFormatter.string(from: self.task.due))
                .foregroundColor(.green)
                .bold()
                .font(.system(size: 14))
            }else{
                if Helper.shared.isLate(d1: self.task.due) {
                    Text(Helper.shared.timeBetweenDates(d1: self.task.due).0)
                        .foregroundColor(.red)
                    .bold()
                    .font(.system(size: 14))
                }else if Helper.shared.isDueToday(d1: self.task.due) {
                    Text(Helper.shared.timeBetweenDates(d1: self.task.due).0)
                        .foregroundColor(.orange)
                    .bold()
                    .font(.system(size: 14))
                } else {
                    Text(Helper.shared.timeBetweenDates(d1: self.task.due).0)
                        .foregroundColor(.blue)
                    .bold()
                    .font(.system(size: 14))
                }
            }
        }
    }
    
}
