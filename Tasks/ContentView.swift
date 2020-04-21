//
//  ContentView.swift
//  Tasks
//
//  Created by Nick Garfitt on 9/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import UIKit
import SwiftUI
import CoreData

struct ContentView: View {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @State private var showDeleteAlert = false
    
    @State private var showConfigAlert = false
    
    @State var showICSSettings = false
    
    @State var lastTask: Task = Task()
    
    @State var isLoading: Bool = false
    
    private let foregroundPublisher = NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)
    
    @FetchRequest(
          entity: Task.entity(),
          sortDescriptors: [NSSortDescriptor(keyPath: \Task.due, ascending: true)]
    ) var allTasks: FetchedResults<Task>
    
    @FetchRequest(
           entity: Task.entity(),
           sortDescriptors: [NSSortDescriptor(keyPath: \Task.due, ascending: true)],
           predicate: NSPredicate(format: "done == %@", NSNumber(value: false))
    ) var incompleteTasks: FetchedResults<Task>
    
    let df = DateFormatter()
    
    @State private var show_modal: Bool = false
    @State var currentItem: String = ""
    @State var invalidURL = false
    
    @ObservedObject var userPrefs = UserPrefs()
    
    init() {
        UITabBar.appearance().barTintColor = UIColor.black
        UITabBar.appearance().isTranslucent = true
        
        let lastRefresh = UserDefaults.standard.object(forKey: "lastRefresh") as? Date ?? Date()
        //If the data is > 24 hours old, refresh automatically
        if Helper.shared.hoursBetweenDates(d1: lastRefresh) >= 24 {
            loadData(icsURL: self.userPrefs.icsURL)
        }
        Helper.shared.setNextTask(ctx: self.context)
    }
    
    func parseICS(data: String) {
        let arr = data.components(separatedBy: "BEGIN:VEVENT")
        if arr.count == 1{
            print("Error, is the ICS file empty?")
            //Small delay to not glitch loading UI
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.invalidURL = true
            }
        }else{
            //Loop through array of events
            for temp in arr {
                //Check if the event is valid ICS
                if temp.contains("DTSTART:") {
                    var id: String = ""
                    var date: String = ""
                    var title: String = ""
                    var description: String = ""
                    var foundDesc: Bool = false
                    for line in temp.components(separatedBy: "\r\n") {
                        if line.starts(with: "DESCRIPTION") {
                            description.append(line)
                            foundDesc = true
                            continue
                        }
                        if foundDesc {
                            if line.starts(with: " "){
                                var tempLine = line
                                tempLine.remove(at: tempLine.startIndex)
                                description.append(tempLine)
                            }else{
                                foundDesc = false
                            }
                        }
                    }
                    if description.count > 0 {
                        description.removeFirst(12)
                        description = description.replacingOccurrences(of: "\\n\\n", with: "\n\n")
                        description = description.replacingOccurrences(of: "\\n", with: "\n")
                        description = description.replacingOccurrences(of: "\\", with: "")
                    }
                    
                    let parts = temp.components(separatedBy: "\r\n")
                    for part in parts {
                        if part.starts(with: "DTEND:") {
                            date = String(part).replacingOccurrences(of: "DTEND:", with: "")
                        }
                        if part.starts(with: "SUMMARY:") {
                            title = String(part).replacingOccurrences(of: "SUMMARY:", with: "")
                        }
                        if part.starts(with: "UID:") {
                            id = String(part).replacingOccurrences(of: "UID:", with: "")
                        }
                    }
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    
                    //TODO
                    // 1) Find a date detector that works with time
                    // 2) Update entry instead of skipping
                    
                    if Helper.shared.taskExists(id: id, ctx: self.context) {
                        Helper.shared.updateTask(id: id, due: (dateFormatter.date(from: date) ?? date.detectDates?.first!.toLocalTime())!, title: title, desc: description, ctx: self.context)
                        //print("Task exists, updating " + title + "\n\n")
                    }else{
                        self.addTask(id: id, title: title, description: description, due: (dateFormatter.date(from: date) ?? date.detectDates?.first!.toLocalTime())!)
                        //print("New task " + title + "\n\n")
                    }
                }
            }
        }
        Helper.shared.setNextTask(ctx: self.context)
        Helper.shared.refreshControl?.endRefreshing()
    }
    
    func addTask(id: String, title: String, description: String, due: Date){
        let newTask = Task(context: self.context)
        newTask.id = id
        newTask.title = title
        newTask.summary = description
        newTask.due = due
        newTask.done = false
        do {
            try self.context.save()
        } catch {
            print(error)
            print(error.localizedDescription)
        }
    }
    
    func loadData(icsURL: String) {
        //Save last updated time as date
        UserDefaults.standard.set(Date(), forKey: "lastRefresh")
        if icsURL == "" {
            //no config yet
            print("No URL configured")
            return
        }
        
        let url = URL(string: icsURL)!
    
        URLSession.shared.dataTask(with: url) {(data,response,error) in
            do {
                if let d = data {
                    DispatchQueue.main.async {
                        self.parseICS(data: String(data: d, encoding: .utf8) ?? "")
                    }
                }else {
                    //Invalid url
                    //Small delay to not glitch loading UI
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.isLoading = false
                        self.invalidURL = true
                    }
                    print("No ICS data found")
                }
            }
        }.resume()
    }
    
    var body: some View {
        TabView {
            NavigationView {
                List((userPrefs.showCompleted == true ? allTasks : incompleteTasks), id: \.id) { task in
                        HStack {
                            Text(task.title)
                                .padding(.trailing, 30.0)
                            Spacer()
                              if (["Late","Now"].contains (Helper.shared.timeBetweenDates(d1: task.due)) && !task.done) {
                                  Text(Helper.shared.timeBetweenDates(d1: task.due))
                                    .foregroundColor(.red)
                                .bold()
                              }else if task.done{
                                  Text("Done").bold()
                                  .foregroundColor(.green)
                              }else {
                                  Text(Helper.shared.timeBetweenDates(d1: task.due)).bold()
                            }
                        }
                        .padding(.vertical, 15.0)
                        .contextMenu {
                            Button(action: {
                                self.show_modal = true
                                self.lastTask = task
                            }) {
                                Text("Info")
                                Image(systemName: "info.circle")
                            }.sheet(isPresented: self.$show_modal) {
                                ModalView(self.lastTask, context: self.context)
                            }
                            if !task.done {
                                Button(action: {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        Helper.shared.changeTaskStatus(task: task, done: true, ctx: self.context)
                                    }
                                }) {
                                    Text("Complete")
                                    Image(systemName: "checkmark.circle")
                                }
                            }else{
                                Button(action: {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        Helper.shared.changeTaskStatus(task: task, done: false, ctx: self.context)
                                    }
                                }) {
                                    Text("Incomplete")
                                    Image(systemName: "arrow.uturn.left.circle")
                                }
                            }
                        }
                }
                .onPull(perform: {
                    if self.userPrefs.icsURL.count > 0 {
                        self.loadData(icsURL: self.userPrefs.icsURL)
                    }else{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.isLoading = false
                            self.showConfigAlert = true
                        }
                    }
                }, isLoading: self.isLoading)
                .alert(isPresented: $showConfigAlert){
                    Alert(title: Text("Please configure an ICS URL in settings"))
                }
                .navigationBarTitle("Tasks")
            }
            .tabItem {
                Image(systemName: "list.bullet")
                    .font(.system(size: 25))
                
           }
           NavigationView {
               Form {
                   Section(header: Text("General")) {
                       Toggle(isOn: $userPrefs.showCompleted) {
                           Text("Show Completed")
                       }
                   }
                   Section(header: Text("Configuration")) {
                    NavigationLink(destination: icsURLView(delegate: self, showSelf: $showICSSettings), isActive: $showICSSettings) {
                           VStack(alignment: .leading){
                               Text("ICS URL")
                           }
                       }
                   }
                   Button(action: {
                       self.showDeleteAlert = true
                   }){
                       Text("Delete all cached data")
                   }
                   .alert(isPresented: self.$showDeleteAlert) {
                       Alert(title: Text("Are you sure?"), message: Text("This will clear all cached tasks"), primaryButton: .destructive(Text("Delete")) {
                           Helper.shared.clearCoreData(ctx: self.context)
                       }, secondaryButton: .cancel())
                   }
               }.navigationBarTitle("Settings")
           }
           .tabItem {
               Image(systemName: "gear")
                .font(.system(size: 25))
           }
        }.onReceive(foregroundPublisher) { notification in
            self.userPrefs.showCompleted = !self.userPrefs.showCompleted
            self.userPrefs.showCompleted = !self.userPrefs.showCompleted
        }
        .accentColor(.orange)
        .alert(isPresented: $invalidURL){
            Alert(title: Text("Error getting data from the server, please ensure you entered a valid ICS feed URL"))
        }
    }
}

struct icsURLView: View {
    
    var delegate: ContentView
    @State var changed: Bool = false
    
    @Binding var showSelf: Bool
    @ObservedObject var userPrefs = UserPrefs()
    
    var body: some View {
        Form {
            Section {
                TextField("website.com/file.ics", text: $userPrefs.icsURL, onEditingChanged: {_ in
                    self.delegate.userPrefs.icsURL = self.userPrefs.icsURL
                    self.changed = true
                }, onCommit: {
                    self.showSelf = false
                    
                })
                 .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            Section {
                Text("Please paste your iCalendar/ICS feed URL above, this will be the URL that the app updates your task list from")
            }
        }
        .navigationBarTitle(Text("ICS URL"), displayMode: .inline)
        .onDisappear(perform: {
            if self.changed {
                Helper.shared.clearCoreData(ctx: self.delegate.context)
                self.delegate.loadData(icsURL: self.delegate.userPrefs.icsURL)
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return ContentView().environment(\.managedObjectContext, context)
    }
    
}
