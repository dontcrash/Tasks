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
    
    @State var lastTask: Task = Task()
    
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
        //clearCoreData()
        loadData(icsURL: userPrefs.icsURL)
    }
    
    func timeBetweenDates(d1: Date) -> String {
        let cal = Calendar.current
        let components = cal.dateComponents([.hour], from: Date().toLocalTime(), to: d1.toLocalTime())
        let hours: Int = components.hour!
        if hours < 24 {
            if hours <= 0 {
                return "Late"
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
    
    func clearCoreData(){
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        var results: [NSManagedObject] = []
        do {
            results = try context.fetch(fetchRequest)
            for object in results {
                context.delete(object)
            }
            try context.save()
        }
        catch {
            print("error executing fetch request: \(error)")
        }
    }
    
    func parseICS(data: String) {
        let arr = data.components(separatedBy: "BEGIN:VEVENT")
        if arr.count == 1{
            print("Error, is the ICS file empty?")
            self.invalidURL = true
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
                        print("Task exists, updating " + title + "\n\n")
                    }else{
                        self.addTask(id: id, title: title, description: description, due: (dateFormatter.date(from: date) ?? date.detectDates?.first!.toLocalTime())!)
                        print("New task " + title + "\n\n")
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
                    self.invalidURL = true
                    print("No ICS data found")
                }
            }
        }.resume()
         
    }

    //TODO
    //Show loading while loading data?
    
    var body: some View {
        TabView {
            NavigationView {
                VStack {
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
                                        self.changeTaskStatus(task: task, done: true)
                                    }) {
                                        Text("Complete")
                                        Image(systemName: "checkmark.circle")
                                    }
                                }else{
                                    Button(action: {
                                        self.changeTaskStatus(task: task, done: false)
                                    }) {
                                        Text("Incomplete")
                                        Image(systemName: "arrow.uturn.left.circle")
                                    }
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
               Form {
                Section(header: Text("General")) {
                    Toggle(isOn: $userPrefs.showCompleted) {
                        Text("Show Completed")
                    }
                }
                Section(header: Text("Configuration")) {
                    HStack() {
                        Text("ICS URL")
                        TextField("example.com/file.ics", text: $userPrefs.icsURL, onCommit: {
                            self.loadData(icsURL: self.userPrefs.icsURL)
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(/*@START_MENU_TOKEN@*/.webSearch/*@END_MENU_TOKEN@*/)
                    }
                }
               }.navigationBarTitle("Settings")
           }
           .tabItem {
               Image(systemName: "gear")
                .font(.system(size: 25))
           }
        }
        .accentColor(.orange)
        .alert(isPresented: $invalidURL){
            Alert(title: Text("Error getting data from the server"))
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        return ContentView().environment(\.managedObjectContext, context)
        
    }
}
