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
    
    init() {
        UITabBar.appearance().barTintColor = UIColor.black
        UITabBar.appearance().isTranslucent = true
        df.dateFormat = "dd/M"
    }
    
    struct Task: Identifiable {
        var id: String
        var name: String
        var due: Date
        var done: Bool
    }
    var tasks = [
        Task(id: "1", name: "Chemistry assignment", due: Date(timeIntervalSince1970: 1586446243), done: false),
        Task(id: "2", name: "Biology practical", due: Date(timeIntervalSince1970: 1586583043), done: false),
        Task(id: "3", name: "Science quiz", due: Date(timeIntervalSince1970: 1589038243), done: false),
        Task(id: "4", name: "A really long name for an quiz that is due, this is a test to see how text wraps", due: Date(timeIntervalSince1970: 1589738243), done: false)
    ]
    
    var body: some View {

        TabView {
            NavigationView {
                VStack {
                    List(tasks, id: \.id) { Task in
                      HStack {
                        Text(Task.name)
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
