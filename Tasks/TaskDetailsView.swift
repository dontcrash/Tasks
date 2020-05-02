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
    @State var isEditing: Bool = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func endEditing() {
        let keyWindow = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first
        keyWindow?.endEditing(true)
    }
    
    var dismiss: () -> ()
    
    var body: some View {

        return NavigationView {
            GeometryReader { geometry in
                VStack {
                    Form {
                        VStack(alignment: .leading) {
                            if self.task.manual {
                                CTextField(text: self.$title, placeholder: "Title")
                                    .frame(width: UIScreen.main.bounds.width-20, height: 60)
                            } else {
                                Text(self.title)
                                    .padding(.vertical, self.padding*2)
                                    .foregroundColor(Color.gray)
                            }
                        }
                        DatePicker(selection: self.$date, label: { /*@START_MENU_TOKEN@*/Text("Date")/*@END_MENU_TOKEN@*/ })
                            .foregroundColor((self.task.manual ? Color.primary : Color.gray))
                            .padding(.vertical, self.padding*2)
                            .onAppear{self.endEditing()}
                            .disabled(!self.task.manual)
                        VStack(alignment: .leading) {
                            if self.task.manual {
                                AdaptiveKeyboard {
                                    TextView(text: self.$notes, isEditing: self.$isEditing, placeholder: "Notes", backgroundColor: UIColor.clear)
                                        .frame(width: (self.horizontalSizeClass == .compact ? geometry.size.width - 30 : geometry.size.width - 60), height: 230)
                                }
                            } else {
                                if self.notes.isEmpty {
                                    Text(Helper.noDesc)
                                        .foregroundColor(Color.gray)
                                } else {
                                    Text(self.notes)
                                        .foregroundColor(Color.gray)
                                }
                            }
                        }
                        .padding(.vertical, self.padding*2)
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
                    if self.isEditing {
                        self.isEditing = false
                        self.endEditing()
                    } else {
                        if self.task.manual {
                            if self.title.count > 0 {
                                Helper.shared.updateTask(id: self.task.id, due: self.date, title: self.title, desc: self.notes, ctx: self.cv.context)
                            }
                        }
                        self.cv.showTaskDetails = false
                    }
                }) {
                    ZStack {
                        Rectangle()
                            .fill(Color.init(hex: 000000, alpha: 0.0001))
                            .frame(width: 70, height: 35)
                        if self.isEditing {
                            Text("Done")
                        } else {
                            if self.task.manual {
                                Text((self.title.count > 0 ? "Save" : "Close"))
                            } else {
                                Text("Close")
                            }
                        }
                    }
                }
            ))
            .navigationBarTitle((self.task.manual ? "Details" : "ICS Details"), displayMode: .inline)
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
