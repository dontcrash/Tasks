//
//  fetchTasks.swift
//  Tasks
//
//  Created by Nick Garfitt on 11/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import Foundation

public class fetchTasks: ObservableObject {

    @Published var tasks = [Task]()
    
    init(){
        load()
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
    
    func parseICS(data: String) -> Array<Task> {
        var tasks = [Task]()
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
    
    func load() {
        //TODO
        //change to userPrefs.icsURL
        let url = URL(string: "https://myuni.adelaide.edu.au/feeds/calendars/user_RcoYVOeuxsNidrtJiEH0sd4fSIFLWlCchET0tDY6.ics")!
    
        URLSession.shared.dataTask(with: url) {(data,response,error) in
            do {
                if let d = data {
                    DispatchQueue.main.async {
                        self.tasks = self.parseICS(data: String(data: d, encoding: .utf8) ?? "")
                    }
                }else {
                    print("No ICS data found")
                }
            }
        }.resume()
         
    }
}
