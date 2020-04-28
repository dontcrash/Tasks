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
    
    @State var showConfigMenu: Bool = false
    
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
    @State var invalidURL = false
    
    @ObservedObject var userPrefs = UserPrefs()
    
    init() {
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
        print(arr.count)
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
                if temp.contains("DTEND") && temp.contains("SUMMARY:") {
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
                        if part.starts(with: "DTSTART:") {
                            date = String(part).replacingOccurrences(of: "DTSTART:", with: "")
                        }
                        if part.starts(with: "DTSTART;TZID=") {
                            date = String(part).replacingOccurrences(of: "DTSTART;TZID=", with: "")
                        }
                        if part.starts(with: "DTSTART;VALUE=DATE:") {
                            date = String(part).replacingOccurrences(of: "DTSTART;VALUE=DATE:", with: "")
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
                    
                    if title.count > 0 {
                        if Helper.shared.taskExists(id: id, ctx: self.context) {
                            Helper.shared.updateTask(id: id, due: (dateFormatter.date(from: date) ?? date.detectDates?.first!.toLocalTime())!, title: title, desc: description, ctx: self.context)
                        }else{
                            Helper.shared.addTask(id: id, title: title, description: description, due: (dateFormatter.date(from: date) ?? date.detectDates?.first!.toLocalTime())!, ctx: self.context)
                        }
                    }else{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.invalidURL = true
                        }
                    }
                }
            }
        }
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
        
        NavigationView {
                VStack {
                    List {
                        ForEach((userPrefs.showCompleted == true ? allTasks : incompleteTasks), id: \.id) { task in
                            HStack {
                                Image(systemName: task.done ? "checkmark.square" : "square")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                .onTapGesture {
                                    Helper.shared.changeTaskStatus(task: task, done: !task.done, ctx: self.context)
                                }
                                .padding(.trailing, 15)
                                NavigationLink(destination:
                                    List {
                                        Text("✏ Title")
                                            .foregroundColor(Color.gray)
                                            .padding(.top, 50)
                                            .padding(.horizontal, 20.0)
                                        Text(task.title)
                                            .padding([.leading, .trailing], 20)
                                        Divider()
                                        Text("🗓️ Date")
                                            .foregroundColor(Color.gray)
                                            .padding(.top, 20)
                                            .padding(.horizontal, 20.0)
                                        Text(self.df.string(from: task.due))
                                            .padding([.leading, .trailing], 20)
                                        Divider()
                                        Text("📖 Notes")
                                            .foregroundColor(Color.gray)
                                            .padding(.top, 20)
                                            .padding(.horizontal, 20.0)
                                        Text((task.summary.count > 0 ? task.summary : Helper.noDesc))
                                            .padding([.leading, .trailing], 20)
                                    }
                                    .onAppear { UITableView.appearance().separatorStyle = .none }
                                    .navigationBarTitle(Text("Details"))
                                ) {
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
                                .onDisappear { UITableView.appearance().separatorStyle = .singleLine }
                            }
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
                                self.showConfigAlert = true
                            }
                        }
                    }, isLoading: self.isLoading)
                    .alert(isPresented: $showConfigAlert){
                        Alert(title: Text("Please configure an ICS URL in settings"))
                    }
                    .sheet(isPresented: self.$showConfigMenu) {
                        NavigationView {
                            Form {
                                HStack {
                                    NavigationLink(destination: icsURLView(delegate: self, showSelf: self.$showICSSettings), isActive: self.$showICSSettings){
                                        VStack(alignment: .leading){
                                           Button(action: {
                                               self.showICSSettings = true
                                           }){
                                               Text("Configure ICS URL")
                                                   .foregroundColor(Color.blue)
                                           }
                                            
                                        }
                                    }
                                }.padding(.vertical, 30)
                                HStack {
                                    Toggle(isOn: self.$userPrefs.showCompleted) {
                                        Text("Show completed")
                                    }
                                }.padding(.vertical, 30)
                                HStack {
                                    Button(action: {
                                        self.showDeleteAlert = true
                                    }){
                                        Text("Clear all cached tasks")
                                            .foregroundColor(Color.red)
                                    }
                                    .alert(isPresented: self.$showDeleteAlert) {
                                        Alert(title: Text("Are you sure?"), message: Text("This will clear all cached tasks"), primaryButton: .destructive(Text("Clear")) {
                                            Helper.shared.clearCoreData(ctx: self.context)
                                        }, secondaryButton: .cancel())
                                    }
                                }.padding(.vertical, 30)
                                HStack {
                                    Text("Tasks: " + (self.userPrefs.showCompleted ? String(self.allTasks.count) : String(self.incompleteTasks.count)))
                                    .foregroundColor(Color.gray)
                                }.padding(.vertical, 30)
                            }
                        .navigationBarItems(trailing: (
                            Button(action: {
                                self.showConfigMenu = false
                            }) {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.init(hex: 000000, alpha: 0.0001))
                                        .frame(width: 70, height: 35)
                                    Text("Done")
                                }
                            }
                        ))
                            .navigationBarTitle("Config", displayMode: .inline)
                        }
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
                            //self.showConfigMenu = true
                            print("Add")
                        }) {
                            ZStack {
                                Rectangle()
                                    .fill(Color.init(hex: 000000, alpha: 0.0001))
                                    .frame(width: 35, height: 35)
                                Image(systemName: "calendar.badge.plus")
                                    .imageScale(.large)
                                    .foregroundColor(Color.gray)
                            }
                        }
                    ))
                }
        }
        .onReceive(foregroundPublisher) { notification in
            //TODO
            //Find a non hackish way to refresh the list view
            self.userPrefs.showCompleted = !self.userPrefs.showCompleted
            self.userPrefs.showCompleted = !self.userPrefs.showCompleted
        }
        .accentColor(.blue)
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
