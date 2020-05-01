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
    let padding: CGFloat = 10
    @State var title: String = ""
    @State var date: Date = Date()
    @State var notes: String = ""
    
    func endEditing() {
        let keyWindow = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first
        keyWindow?.endEditing(true)
    }
    
    var body: some View {

        return NavigationView {
            VStack{
                Form {
                    VStack(alignment: .leading) {
                        TextField("Title", text: self.$title)
                            .frame(width: UIScreen.main.bounds.width-20, height: 60)
                    }
                    DatePicker(selection: self.$date, label: { /*@START_MENU_TOKEN@*/Text("Date")/*@END_MENU_TOKEN@*/ })
                        .foregroundColor(Color.gray)
                        .padding(.vertical, padding*2)
                        .onAppear{self.endEditing()}
                    VStack(alignment: .leading) {
                        NavigationLink(destination: NotesView(notes: self.$notes)){
                            Text((self.notes.count > 0 ? self.notes : "Notes"))
                                .foregroundColor(Color.gray)
                        }
                    }
                    .padding(.vertical, padding*2)
                    if self.task.title.isEmpty {
                        //
                    }else{
                        Section {
                            EmptyView()
                        }
                        Button(action: {
                            print("Delete")
                        }) {
                            Text("Delete")
                                .foregroundColor(Color.red)
                        }
                    }
                }
            }
            .onAppear(perform: {
                self.title = self.task.title
                self.date = self.task.due
                self.notes = self.task.summary
            })
            .navigationBarItems(trailing: (
                Button(action: {
                    if self.task.title.isEmpty {
                        if self.title.count > 0 {
                            Helper.shared.addTask(id: String(Date().timeIntervalSince1970), title: self.title, description: self.notes, due: self.date, manual: true, ctx: self.cv.context)
                            Helper.shared.saveContext(ctx: self.cv.context)
                            Helper.shared.setNextTask(ctx: self.cv.context)
                        }
                    } else {
                        //TODO
                        //Show a warning if the title is blank
                        if self.title.count > 0 {
                            Helper.shared.updateTask(id: self.task.id, due: self.date, title: self.title, desc: self.notes, ctx: self.cv.context)
                        }
                    }
                    self.cv.showTaskDetails = false
                }) {
                    ZStack {
                        Rectangle()
                            .fill(Color.init(hex: 000000, alpha: 0.0001))
                            .frame(width: 70, height: 35)
                        if self.task.title.isEmpty || !self.task.manual {
                            Text((self.title.count > 0 ? "Add" : "Close"))
                        } else {
                            Text("Save")
                        }
                    }
                }
            ))
            .navigationBarTitle((self.task.title.isEmpty ? "New Task" : "Details"), displayMode: .inline)
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

struct NotesView: View {
    
    @Binding var notes: String
    @State var isEditing: Bool = false
    
    var body: some View {
        TextView(text: self.$notes, isEditing: self.$isEditing, placeholder: "Notes", backgroundColor: UIColor.clear)
            .padding(.leading, 20)
            .modifier(AdaptsToKeyboard())
    }
    
}
