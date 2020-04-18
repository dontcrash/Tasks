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
        if self.hoursBetweenDates(d1: lastRefresh) > 24 {
            loadData(icsURL: self.userPrefs.icsURL)
        }
        
    }

    func timeBetweenDates(d1: Date) -> String {
        let hours: Int = hoursBetweenDates(d1: d1)
        if hours < 24 {
            if hours <= 0 {
                return "Late"
            }
            if hours == 1 {
                return "Now"
            }
            return String(hours) + " hours"
        }else{
            var daysFloat: Float = Float(hours)/24.0
            daysFloat.round()
            let days: Int = Int(daysFloat)
            if days == 1 {
                return String(hours) + " hours"
                //return "1 day"
            }
            return String(days) + " days"
        }
    }
    
    func hoursBetweenDates(d1: Date) -> Int {
        let cal = Calendar.current
        let components = cal.dateComponents([.hour], from: Date().toLocalTime(), to: d1.toLocalTime())
        return components.hour!
    }
    
    func clearCoreData(){
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        var results: [NSManagedObject] = []
        do {
            results = try context.fetch(fetchRequest)
            for object in results {
                self.context.delete(object)
            }
        }
        catch {
            print("error executing fetch request: \(error)")
        }
        do {
            try self.context.save()
            
        } catch {
            print(error)
            print(error.localizedDescription)
        }
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
                    
                    if taskExists(id: id) {
                        updateTask(id: id, due: (dateFormatter.date(from: date) ?? date.detectDates?.first!.toLocalTime())!, title: title, desc: description)
                        //print("Task exists, updating " + title + "\n\n")
                    }else{
                        self.addTask(id: id, title: title, description: description, due: (dateFormatter.date(from: date) ?? date.detectDates?.first!.toLocalTime())!)
                        //print("New task " + title + "\n\n")
                    }
                }
            }
        }
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
    
    func changeTaskStatus(task: Task, done: Bool){
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        fetchRequest.fetchLimit = 1
        do {
            let test = try self.context.fetch(fetchRequest)
            let taskUpdate = test[0] as! NSManagedObject
            taskUpdate.setValue(done, forKey: "done")
            try self.context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func updateTask(id: String, due: Date, title: String, desc: String){
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        do {
            let test = try self.context.fetch(fetchRequest)
            let taskUpdate = test[0] as! NSManagedObject
            taskUpdate.setValue(due, forKey: "due")
            taskUpdate.setValue(title, forKey: "title")
            taskUpdate.setValue(desc, forKey: "summary")
            try self.context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func taskExists(id: String) -> Bool {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        var results: [NSManagedObject] = []
        do {
            results = try context.fetch(fetchRequest)
        }
        catch {
            print("error executing fetch request: \(error)")
        }
        return results.count > 0
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
                            if (["Late","Now"].contains (self.timeBetweenDates(d1: task.due)) && !task.done) {
                                Text(self.timeBetweenDates(d1: task.due))
                                  .foregroundColor(.red)
                              .bold()
                            }else if task.done{
                                Text("Done").bold()
                                .foregroundColor(.green)
                            }else {
                                Text(self.timeBetweenDates(d1: task.due)).bold()
                          }
                        }
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
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                        self.changeTaskStatus(task: task, done: true)
                                    }
                                }) {
                                    Text("Complete")
                                    Image(systemName: "checkmark.circle")
                                }
                            }else{
                                Button(action: {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                        self.changeTaskStatus(task: task, done: false)
                                    }
                                }) {
                                    Text("Incomplete")
                                    Image(systemName: "arrow.uturn.left.circle")
                                }
                            }
                        }
                        .padding(.vertical, 15.0)
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
                }, isLoading: isLoading)
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
                           self.clearCoreData()
                       }, secondaryButton: .cancel())
                   }
               }.navigationBarTitle("Settings")
           }
           .tabItem {
               Image(systemName: "gear")
                .font(.system(size: 25))
           }
        }.onReceive(foregroundPublisher) { notification in
            print("foreground")
            
        }
        .accentColor(.orange)
        .alert(isPresented: $invalidURL){
            Alert(title: Text("Error getting data from the server, please ensure you entered a valid ICS feed URL"))
        }
    }
}

struct icsURLView: View {
    
    var delegate: ContentView
    
    @Binding var showSelf: Bool
    @ObservedObject var userPrefs = UserPrefs()
    
    var body: some View {
        Form {
            Section {
                TextField("website.com/file.ics", text: $userPrefs.icsURL, onEditingChanged: {_ in
                    self.delegate.userPrefs.icsURL = self.userPrefs.icsURL
                }, onCommit: { self.showSelf = false })
                 .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            Section {
                Text("Please paste your iCalendar/ICS feed URL above, this will be the URL that the app updates your task list from")
            }
        }
        .navigationBarTitle(Text("ICS URL"), displayMode: .inline)
        .onDisappear(perform: { self.delegate.loadData(icsURL: self.delegate.userPrefs.icsURL) })
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return ContentView().environment(\.managedObjectContext, context)
    }
    
}
