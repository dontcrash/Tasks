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

enum AlertPresent {
    case invalidurl, nourl
}

struct ContentView: View {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    @State var showAlert = false
    @State var activeAlert: AlertPresent = .nourl
    
    @State var showDeleteAlert = false
    
    @State var showICSSettings = false
    
    @State var showNewTask = false
    
    @State var lastTask: Task = Task()
    
    @State var isLoading: Bool = false
    
    @State var showConfigMenu: Bool = false
    
    @State var showTaskDetails: Bool = false
    
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
    
    var df = DateFormatter()
    
    @State var currentItem: String = ""
    
    @ObservedObject var userPrefs = UserPrefs()
    
    init() {
        UITableView.appearance().backgroundColor = UIColor.systemGray6
        UITableViewCell.appearance().backgroundColor = UIColor.systemGray6
        UITabBar.appearance().barTintColor = UIColor.black
        UITabBar.appearance().isTranslucent = true
        //UITableView.appearance().separatorStyle = .none
        let lastRefresh = UserDefaults.standard.object(forKey: "lastRefresh") as? Date ?? Date()
        //If the data is > 24 hours old, refresh automatically
        if Helper.shared.hoursBetweenDates(d1: lastRefresh) >= 24 {
            loadData(icsURL: self.userPrefs.icsURL)
        }
        Helper.shared.setNextTask(ctx: self.context)
        df.dateFormat = "EEEE, d MMM h:mm a"
    }
    
    func parseICS(data: String) {
        let arr = data.components(separatedBy: "BEGIN:VEVENT")
        if arr.count == 1{
            print("Error, is the ICS file empty?")
            //Small delay to not glitch loading UI
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.activeAlert = .invalidurl
                self.showAlert = true
            }
        }else{
            //Loop through array of events
            for temp in arr {
                //Check if the event is valid ICS
                if temp.contains("DTEND") && temp.contains("SUMMARY") {
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
                        if let index = description.index(of: ":") {
                            let sub = description[..<index] + ":"
                            description = description.replacingOccurrences(of: sub, with: "")
                        }
                        description = description.replacingOccurrences(of: "\\n\\n", with: "\n\n")
                        description = description.replacingOccurrences(of: "\\n", with: "\n")
                        description = description.replacingOccurrences(of: "\\", with: "")
                    }
                    
                    let parts = temp.components(separatedBy: "\r\n")
                    for part in parts {
                        if part.starts(with: "DTSTART") {
                            if let index = part.index(of: ":") {
                                let sub = part[..<index] + ":"
                                date = part.replacingOccurrences(of: sub, with: "")
                            }
                        }
                        if part.starts(with: "SUMMARY") {
                            if let index = part.index(of: ":") {
                                let sub = part[..<index] + ":"
                                title = part.replacingOccurrences(of: sub, with: "")
                            }
                        }
                        if part.starts(with: "UID") {
                            if let index = part.index(of: ":") {
                                let sub = part[..<index] + ":"
                                id = part.replacingOccurrences(of: sub, with: "")
                            }
                        }
                    }
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    
                    //TODO
                    // 1) Find a date detector that works with time
                    
                    if title.count > 0 {
                        if Helper.shared.taskExists(id: id, ctx: self.context) {
                            Helper.shared.updateTask(id: id, due: (dateFormatter.date(from: date) ?? date.detectDates?.first!.toLocalTime())!, title: title, desc: description, ctx: self.context)
                        }else{
                            Helper.shared.addTask(id: id, title: title, description: description, due: (dateFormatter.date(from: date) ?? date.detectDates?.first!.toLocalTime())!, manual: false, ctx: self.context)
                        }
                    }else{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.activeAlert = .invalidurl
                            self.showAlert = true
                        }
                    }
                }
            }
        }
        Helper.shared.saveContext(ctx: self.context)
        Helper.shared.setNextTask(ctx: self.context)
        Helper.shared.refreshControl?.endRefreshing()
    }
    
    func loadData(icsURL: String) {
        //Save last updated time as date
        UserDefaults.standard.set(Date(), forKey: "lastRefresh")
        if icsURL == "" {
            //no config yet
            print("No URL configured")
            return
        }
        
        let url: URL = (URL(string: icsURL) ?? URL(string:"https://www.google.com"))!
    
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
                        self.activeAlert = .invalidurl
                        self.showAlert = true
                    }
                    print("No ICS data found")
                }
            }
        }.resume()
    }
    
    var body: some View {
        
        NavigationView {
            VStack {
                List {
                    ForEach((userPrefs.showCompleted == true ? allTasks : incompleteTasks), id: \.id) { task in
                        HStack {
                            ZStack {
                                Image(systemName: task.done ? "checkmark.square" : "square")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Rectangle()
                                    .fill(Color.init(hex: 000000, alpha: 0.0001))
                                    .frame(width: 30, height: 30)
                            }
                            .onTapGesture {
                                Helper.shared.changeTaskStatus(task: task, done: !task.done, ctx: self.context)
                            }
                            .padding(.trailing, 15)
                            Button(action: {
                                self.showTaskDetails = true
                            }) {
                                HStack {
                                    Text(task.title)
                                        .padding(.trailing, 15)
                                        .truncationMode(.tail)
                                        .lineLimit(1)
                                    Spacer()
                                    if task.done {
                                        Text(Helper.shared.timeBetweenDates(d1: task.due).0)
                                        .foregroundColor(.green)
                                        .bold()
                                        .font(.system(size: 14))
                                    }else{
                                        Text(Helper.shared.timeBetweenDates(d1: task.due).0)
                                        .foregroundColor((Helper.shared.timeBetweenDates(d1: task.due).1) ? .red : .blue)
                                        .bold()
                                        .font(.system(size: 14))
                                    }
                                }
                            }
                            .sheet(isPresented: self.$showTaskDetails) {
                                TaskDetailsView(cv: self, task: task)
                            }
                            .onDisappear { UITableView.appearance().separatorStyle = .singleLine }
                        }
                        .listRowBackground(Color(UIColor.systemGray6))
                        .padding(.vertical, 14)
                    }
                    .onDelete { indexSet in
                        let deleteItem = (self.userPrefs.showCompleted == true ? self.allTasks : self.incompleteTasks)[indexSet.first!]
                        Helper.shared.deleteTask(id: deleteItem.id, ctx: self.context)
                    }
                }
                .onPull(perform: {
                    if self.userPrefs.icsURL.count > 0 {
                        self.loadData(icsURL: self.userPrefs.icsURL)
                    }else{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.isLoading = false
                            self.activeAlert = .nourl
                            self.showAlert = true
                        }
                    }
                }, isLoading: self.isLoading)
                .sheet(isPresented: self.$showConfigMenu) {
                    SettingsView(cv: self)
                }
                .navigationBarTitle("Tasks", displayMode: .inline)
                .navigationBarItems(leading: (
                    Button(action: {
                        self.showConfigMenu = true
                    }) {
                        ZStack {
                            Rectangle()
                                .fill(Color.init(hex: 000000, alpha: 0.0001))
                                .frame(width: 35, height: 35)
                            Image(systemName: "gear")
                                .imageScale(.large)
                                .foregroundColor(Color.gray)
                        }
                    }
                ), trailing: (
                    Button(action: {
                        self.showNewTask = true
                    }) {
                        ZStack {
                            Rectangle()
                                .fill(Color.init(hex: 000000, alpha: 0.0001))
                                .frame(width: 35, height: 35)
                            Image(systemName: "calendar.badge.plus")
                                .imageScale(.large)
                                .foregroundColor(Color.gray)
                        }.sheet(isPresented: self.$showNewTask) {
                            NewTaskView(cv: self)
                        }
                    }
                ))
            }
            .alert(isPresented: self.$showAlert){
                switch activeAlert {
                    case .invalidurl:
                        return Alert(title: Text("Error getting data from the server, please ensure you entered a valid ICS feed URL"))
                    case .nourl:
                        return Alert(title: Text("Please configure an ICS URL in settings"))
                }
            }
        }
        .onReceive(foregroundPublisher) { notification in
            //TODO
            //Find a non hackish way to refresh the list view
            self.userPrefs.showCompleted = !self.userPrefs.showCompleted
            self.userPrefs.showCompleted = !self.userPrefs.showCompleted
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.blue)
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return ContentView().environment(\.managedObjectContext, context)
    }
    
}
