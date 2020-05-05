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
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State var searchText: String = ""
    
    @State var showAlert = false
    
    @State var activeAlert: AlertPresent = .nourl
    
    @State var showDeleteAlert = false
    
    @State var showICSSettings = false
    
    @State var showNewTask = false
    
    @State var lastTask: Task = Task()
    
    @State var showConfigMenu: Bool = false
    
    @State var showTaskDetails: Bool = false
    
    @State var showCancelButton: Bool = false
    
    @State var showUndo: Bool = false
    
    let generator = UINotificationFeedbackGenerator()
    
    private let foregroundPublisher = NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)
    
    @FetchRequest(
          entity: Task.entity(),
          sortDescriptors: [NSSortDescriptor(keyPath: \Task.due, ascending: true)]
    ) var allTasks: FetchedResults<Task>
    
    var df = DateFormatter()
    
    @State var currentItem: String = ""
    
    @ObservedObject var userPrefs = UserPrefs()
    
    init() {
        UITableView.appearance().backgroundColor = UIColor.systemGray6
        UITableViewCell.appearance().backgroundColor = UIColor.systemGray6
        //UITableView.appearance().separatorStyle = .none
        let lastRefresh = UserDefaults.standard.object(forKey: "lastRefresh") as? Date ?? Date()
        //If the data is >= 3 hours old, refresh automatically
        if Helper.shared.hoursBetweenDates(d1: lastRefresh) <= -3 {
            loadData(icsURL: self.userPrefs.icsURL)
        }
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
        //Helper.shared.setNextTask(ctx: self.context)
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
                        self.activeAlert = .invalidurl
                        self.showAlert = true
                    }
                    print("No ICS data found")
                }
            }
        }.resume()
    }
    
    func removeItems(at offsets: IndexSet, list: [FetchedResults<Task>.Element]) {
        offsets.forEach{ offset in
            Helper.shared.deleteTask(id: list[offset].id, ctx: self.context)
        }
    }
    
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
        
        let today = allTasks.filter { task in
            return (self.searchText.isEmpty ? task.done == false && Helper.shared.isDueToday(d1: task.due) : (task.title.lowercased().contains(self.searchText.lowercased()) && task.done == false  && Helper.shared.isDueToday(d1: task.due) || task.summary.lowercased().contains(self.searchText.lowercased()) && task.done == false && Helper.shared.isDueToday(d1: task.due)))
        }
        
        let thisWeek = allTasks.filter { task in
            return (self.searchText.isEmpty ? task.done == false && Helper.shared.isDueThisWeek(d1: task.due) : (task.title.lowercased().contains(self.searchText.lowercased()) && task.done == false  && Helper.shared.isDueThisWeek(d1: task.due) || task.summary.lowercased().contains(self.searchText.lowercased()) && task.done == false && Helper.shared.isDueThisWeek(d1: task.due)))
        }
        
        let later = allTasks.filter { task in
            return (self.searchText.isEmpty ? task.done == false && Helper.shared.isDueLater(d1: task.due) : (task.title.lowercased().contains(self.searchText.lowercased()) && task.done == false  && Helper.shared.isDueLater(d1: task.due) || task.summary.lowercased().contains(self.searchText.lowercased()) && task.done == false && Helper.shared.isDueLater(d1: task.due)))
        }
        
        let completed = allTasks.filter { task in
            return (self.searchText.isEmpty ? task.done == true : (task.title.lowercased().contains(self.searchText.lowercased()) && task.done == true || task.summary.lowercased().contains(self.searchText.lowercased()) && task.done == true))
        }.sorted(by: { $0.due.timeIntervalSince1970 > $1.due.timeIntervalSince1970} )
        
        return NavigationView {
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 0) {
                        SearchBar(showCancelButton: self.$showCancelButton, searchText: self.$searchText)
                        List {
                            if today.count > 0 {
                                Section(header:
                                    HStack {
                                        Text("Today")
                                        Spacer()
                                        Text(String(today.count))
                                            .foregroundColor(Color.gray)
                                    }
                                ){
                                    ForEach(today, id: \.id) { task in
                                        TaskRowModel(task: task, cv: self)
                                    }
                                    .onDelete(perform: { offsets in
                                        self.removeItems(at: offsets, list: today)
                                    })
                                }
                            }
                            if thisWeek.count > 0 {
                                Section(header:
                                    HStack {
                                        Text("This Week")
                                        Spacer()
                                        Text(String(thisWeek.count))
                                            .foregroundColor(Color.gray)
                                    }
                                ){
                                    ForEach(thisWeek, id: \.id) { task in
                                        TaskRowModel(task: task, cv: self)
                                    }
                                    .onDelete(perform: { offsets in
                                        self.removeItems(at: offsets, list: thisWeek)
                                    })
                                }
                            }
                            if later.count > 0 {
                                Section(header:
                                    HStack {
                                        Text("Later")
                                        Spacer()
                                        Text(String(later.count))
                                            .foregroundColor(Color.gray)
                                    }
                                ){
                                    ForEach(later, id: \.id) { task in
                                        TaskRowModel(task: task, cv: self)
                                    }
                                    .onDelete(perform: { offsets in
                                        self.removeItems(at: offsets, list: later)
                                    })
                                }
                            }
                            if self.userPrefs.hideCompleted == false {
                                if completed.count > 0 {
                                    Section(header:
                                        HStack {
                                            Text("Completed")
                                            Spacer()
                                            Text(String(completed.count))
                                                .foregroundColor(Color.gray)
                                        }
                                    ){
                                        ForEach(completed, id: \.id) { task in
                                            TaskRowModel(task: task, cv: self)
                                        }
                                        .onDelete(perform: { offsets in
                                            self.removeItems(at: offsets, list: completed)
                                        })
                                    }
                                }
                            }
                            if today.isEmpty && thisWeek.isEmpty && later.isEmpty && completed.isEmpty {
                                if self.searchText.isEmpty {
                                    //Text(Helper.allCompleted)
                                        //.padding(.vertical, 14)
                                } else {
                                    Text("No results 😱")
                                        .padding(.vertical, 14)
                                }
                            }
                        }
                        .sheet(isPresented: self.$showConfigMenu) {
                            SettingsView(cv: self)
                        }
                        //Causes issues with deleting rows
                        //.resignKeyboardOnDragGesture()
                        .navigationBarTitle("Tasks", displayMode: .inline)
                        .navigationBarItems(leading: (
                            Button(action: {
                                self.endEditing()
                                self.showCancelButton = false
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
                                self.endEditing()
                                self.showCancelButton = false
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
                    VStack {
                        Spacer()
                        if self.showUndo {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Task status changed")
                                    Spacer()
                                    Button(action: {
                                        Helper.shared.changeTaskStatus(task: Helper.lastTask, done: !Helper.lastTask.done, ctx: self.context)
                                        self.generator.notificationOccurred(.success)
                                        withAnimation {
                                            self.showUndo = false
                                        }
                                    }){
                                        Text("Undo")
                                            .foregroundColor(Color.blue)
                                    }
                                }
                                .padding(.top, 25)
                                .padding(.horizontal, 25)
                            }
                            .transition(.opacity)
                            .frame(width: geometry.size.width/1.2, height: 30)
                            .padding(.bottom, 30)
                            .background(Color.init(UIColor.systemGray4))
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .background(Color.init(UIColor.systemGray6))
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
            self.userPrefs.hideCompleted.toggle()
            self.userPrefs.hideCompleted.toggle()
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

struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged{_ in
        UIApplication.shared.endEditing(true)
    }
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}

extension View {
    func resignKeyboardOnDragGesture() -> some View {
        return modifier(ResignKeyboardOnDragGesture())
    }
}
