//
//  ContentView.swift
//  Tasks
//
//  Created by Nick Garfitt on 9/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    func timeBetweenDates(d1: Date) -> String {
        let cal = Calendar.current
        let components = cal.dateComponents([.hour], from: Date().toLocalTime(), to: d1.toLocalTime())
        let hours: Int = components.hour!
        if hours < 24 {
            if hours <= 0 {
                return "Overdue"
            }
            if hours == 1 {
                return "Now"
            }
            return String(hours) + " hours"
        }else{
            let days: Int = hours/24
            if days == 1 {
                return "1 day"
            }
            return String(days) + " days"
        }
    }
    
    let df = DateFormatter()
    
    @State private var show_modal: Bool = false
    @State var currentItem: String = ""
    
    @ObservedObject var userPrefs = UserPrefs()
    @ObservedObject var taskFetcher = fetchTasks()
    
    init() {
        UITabBar.appearance().barTintColor = UIColor.black
        UITabBar.appearance().isTranslucent = true
    }
    
    func completeItem(){
        UserDefaults.standard.set(true, forKey: self.currentItem)
        taskFetcher.refreshList()
    }

    //TODO
    //Show loading while taskFetcher is working?
    
    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    //TODO
                    //Add a setting to show completed
                    //If setting, don't use filter etc
                    //If true show List(filter) else show List(tasks)
                    List(taskFetcher.tasks.filter({return !$0.done}), id: \.id) { Task in
                        HStack {
                          Text(Task.title)
                              .padding(.trailing, 30.0)
                          Spacer()
                          if ["Overdue","Now"].contains (self.timeBetweenDates(d1: Task.due)) {
                              Text(self.timeBetweenDates(d1: Task.due))
                                  .foregroundColor(.red)
                              .bold()
                          }else{
                              Text(self.timeBetweenDates(d1: Task.due)).bold()
                          }
                        }
                        .contextMenu {
                            Button(action: {
                              self.currentItem = Task.id
                              self.show_modal = true
                            }) {
                                Text("Info")
                                Image(systemName: "info.circle")
                            }.sheet(isPresented: self.$show_modal) {
                              ModalView(_description: self.currentItem, _tasks: self.taskFetcher.tasks, _id: self.currentItem)
                            }
                            Button(action: {
                              self.currentItem = Task.id
                              self.completeItem()
                            }) {
                                Text("Complete")
                                Image(systemName: "checkmark.circle")
                            }
                        }
                        .padding(.vertical, 15.0)
                    }
                }.navigationBarTitle("Tasks")
            }
            .tabItem {
                Image(systemName: "list.bullet")
                    .font(.system(size: 25))
                
           }
           NavigationView {
               VStack(alignment: .leading) {
                   Text("iCal/ICS URL")
                       .bold()
                       .navigationBarTitle("Settings")
                       .padding([.top, .leading], 24.0)
                TextField("example.com/file.ics", text: $userPrefs.icsURL, onCommit: {
                        self.taskFetcher.load(icsURL: self.userPrefs.icsURL)
                    })
                    .padding([.leading, .trailing], 24.0)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(/*@START_MENU_TOKEN@*/.URL/*@END_MENU_TOKEN@*/)
                Spacer()
               }
           }
           .tabItem {
               Image(systemName: "gear")
                .font(.system(size: 25))
           }
        }
        .accentColor(.orange)
        .alert(isPresented: $taskFetcher.invalidURL){
            Alert(title: Text("Error getting data from the server"))
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        //ContentView()
        //TODO call ContentView() instead of forced dark mode for releases
        ContentView().environment(\.colorScheme, .dark)
    }
}
