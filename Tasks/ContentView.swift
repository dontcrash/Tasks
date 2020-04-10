//
//  ContentView.swift
//  Tasks
//
//  Created by Nick Garfitt on 9/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

/*
 
 https://myuni.adelaide.edu.au/feeds/calendars/user_RcoYVOeuxsNidrtJiEH0sd4fSIFLWlCchET0tDY6.ics
 
 */

import SwiftUI

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

struct ContentView: View {
    
    func timeBetweenDates(d1: Date) -> String {
        let cal = Calendar.current
        let components = cal.dateComponents([.hour], from: Date(), to: d1)
        let hours: Int = components.hour!
        if hours < 24 {
            if hours < 0 {
                return "Overdue"
            }
            if hours == 0 {
                return "Now"
            }
            if hours == 1 {
                return String(hours) + " hour"
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
        df.dateFormat = "dd/M"
        tasks = parseICS()
    }
    
    struct Task: Identifiable {
        var id: String
        var title: String
        var description: String
        var due: Date
        var done: Bool
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
                    let parts = temp.split(separator: "\r\n")
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
                    let properDate = dateFormatter.date(from: date)
                    tasks.append(Task(id: id, title: title, description: description, due: (properDate?.toLocalTime())!, done: false))
                }
            }
        }
        return tasks;
    }

 
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
                          Button(action: {/* Mark as done here */}) {
                            Text("Complete")
                            Image(systemName: "checkmark")
                          }
                      }
                      .padding(.vertical, 15.0)
                    }
                }.navigationBarTitle("Tasks")
            }
            .tabItem {
                Image(systemName: "checkmark.square")
                    .font(.system(size: 25))
                
           }
           NavigationView {
               Text("Settings page will be here")
                   .navigationBarTitle("Settings")
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
