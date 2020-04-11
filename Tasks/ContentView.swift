//
//  ContentView.swift
//  Tasks
//
//  Created by Nick Garfitt on 9/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI
import Combine

class UserPrefs : ObservableObject {
    @Published var icsURL = UserDefaults.standard.string(forKey: "icsURL") ?? ""
    private var canc: AnyCancellable!

    init() {
        canc = $icsURL.debounce(for: 0.2, scheduler: DispatchQueue.main).sink { newText in
            UserDefaults.standard.set(newText, forKey: "icsURL")
        }
    }

    deinit {
        canc.cancel()
    }
}

extension Date {

    // Convert local time to UTC (or GMT)
    func toGlobalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

    // Convert UTC (or GMT) to local time
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

}

struct Task: Identifiable {
    var id: String
    var title: String
    var description: String
    var due: Date
    var done: Bool
}

struct ModalView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var description: String = ""
    var task: Task!
    
    var df = DateFormatter()
    
    init(_description: String, _tasks: [Task], _id: String) {
        df.dateFormat = "EEEE, d MMM h:mm a"
        for t in _tasks {
            if t.id == _id {
                task = t
                break
            }
        }
        description = task.description
        let arr = description.split(separator: "\r\n")
        var fullStr: String = ""
        for str in arr {
            if str.starts(with: " ") {
                fullStr.append(contentsOf: str.dropFirst())
            }else{
                fullStr.append(contentsOf: str)
            }
        }
        description = fullStr
        description = description.replacingOccurrences(of: "\\n\\n", with: "\n\n")
        description = description.replacingOccurrences(of: "\\n", with: "\n")
        description = description.replacingOccurrences(of: "\\", with: "")
        //< 3 to stop spaces counting as a description
        if description.count < 3 {
            description = "No description provided 😢"
        }
    }
    
    var body: some View {
        VStack {
            /*
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Text("Dismiss")
            }.padding(.bottom, 50)
            */
            List {
                Text(df.string(from: task.due)).padding(20)
                Text("\(description)").lineLimit(nil).padding(20)
            }
            
        }
    }
}

struct ContentView: View {
    
    @State private var show_modal: Bool = false
    
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
    var tasks = [Task]()
    
    init() {
        UITabBar.appearance().barTintColor = UIColor.black
        UITabBar.appearance().isTranslucent = true
        tasks = parseICS()
        
        //DEBUG
        //tasks = [Task(id: "1", title: "Title", description: "Desc", due: Date().toLocalTime(), done: false)]
    }

    func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func parseICS() -> Array<Task> {
        var tasks = [Task]()
        var data: String = ""
        if let path = Bundle.main.path(forResource: "test", ofType: "ics"){
            do {
                data = try String(contentsOfFile: path, encoding: .utf8)
            } catch {
                print(error)
            }
        }
        let arr = data.components(separatedBy: "BEGIN:VEVENT")
        if arr.count == 1{
            print("Error, is the ICS file empty?")
        }else{
            //Loop through array of events
            for temp in arr {
                //Check if the event is valid ICS
                if temp.contains("DTSTART:") {
                    var id: String = ""
                    var date: String = ""
                    var title: String = ""
                    var description: String = ""
                    let desc: [String] = matches(for: "DESCRIPTION:([\\s\\S]*?)SEQUENCE:", in: temp)
                    if desc.count > 0 {
                        description = desc[0]
                        description = description.replacingOccurrences(of: "DESCRIPTION:", with: "")
                        description = description.replacingOccurrences(of: "SEQUENCE:", with: "")
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
                    tasks.append(Task(id: id, title: title, description: description, due: dateFormatter.date(from: date)!, done: false))
                }
            }
        }
        return tasks
    }

    @State var currentItem: String = ""
    @ObservedObject var userPrefs = UserPrefs()
    
    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    List(tasks, id: \.id) { Task in
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
                            ModalView(_description: self.currentItem, _tasks: self.tasks, _id: self.currentItem)
                          }
                          Button(action: {/* Mark as done here */}) {
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
                TextField("example.com/file.ics", text: $userPrefs.icsURL, onCommit: {})
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        //ContentView()
        //TODO call ContentView() instead of forced dark mode for releases
        ContentView().environment(\.colorScheme, .dark)
    }
}
