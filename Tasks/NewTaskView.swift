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
    @State var isEditing: Bool = false

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
                        .padding(.vertical, padding*2)
                        .onAppear{self.endEditing()}
                    VStack(alignment: .leading) {
                        AdaptiveKeyboard {
                            TextView(text: self.$notes, isEditing: self.$isEditing, placeholder: "Notes", backgroundColor: UIColor.clear)
                            .frame(width: UIScreen.main.bounds.width - 30, height: 230)
                        }
                    }
                    .padding(.vertical, padding*2)
                }
            }
            .navigationBarItems(trailing: (
                Button(action: {
                    if self.isEditing {
                        self.isEditing = false
                        self.endEditing()
                    } else {
                        if self.title.count > 0 {
                            Helper.shared.addTask(id: String(Date().timeIntervalSince1970), title: self.title, description: self.notes, due: self.date, manual: true, ctx: self.cv.context)
                            Helper.shared.saveContext(ctx: self.cv.context)
                            Helper.shared.setNextTask(ctx: self.cv.context)
                        }
                        self.cv.showNewTask = false
                    }
                }) {
                    ZStack {
                        Rectangle()
                            .fill(Color.init(hex: 000000, alpha: 0.0001))
                            .frame(width: 70, height: 35)
                        if self.isEditing {
                            Text("Done")
                        } else {
                            Text((self.title.count > 0 ? "Add" : "Close"))
                        }
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
