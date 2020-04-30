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
    let padding: CGFloat = 10
    @State var title: String = ""
    @State var date: Date = Date()
    @State var notes: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                VStack(alignment: .leading) {
                    TextField("Title", text: self.$title)
                        .frame(width: UIScreen.main.bounds.width-20, height: 60)
                }
                DatePicker(selection: self.$date, label: { /*@START_MENU_TOKEN@*/Text("Date")/*@END_MENU_TOKEN@*/ })
                    .foregroundColor(Color.gray)
                    .padding(.vertical, padding*2.5)
                VStack(alignment: .leading) {
                    TextField("Notes", text: self.$notes)
                        .frame(width: UIScreen.main.bounds.width-20, height: 60)
                }
            }
            .navigationBarItems(trailing: (
                Button(action: {
                    if self.title.count > 0 {
                        Helper.shared.addTask(id: String(Date().timeIntervalSince1970), title: self.title, description: self.notes, due: self.date, manual: true, ctx: self.cv.context)
                        Helper.shared.saveContext(ctx: self.cv.context)
                    }
                    self.cv.showNewTask = false
                }) {
                    ZStack {
                        Rectangle()
                            .fill(Color.init(hex: 000000, alpha: 0.0001))
                            .frame(width: 70, height: 35)
                        Text((self.title.count > 0 ? "Add" : "Done"))
                    }
                }
            ))
            .navigationBarTitle("New Task", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            UITableView.appearance().separatorStyle = .singleLine
            UITableViewCell.appearance().backgroundColor = UIColor.systemGray5
        }
        .onDisappear {
            UITableView.appearance().separatorStyle = .none
            UITableViewCell.appearance().backgroundColor = UIColor.systemGray6
        }
    }
    
}

struct NewTaskView_Previews: PreviewProvider {
    static var previews: some View {
        NewTaskView(cv: ContentView())
    }
}
