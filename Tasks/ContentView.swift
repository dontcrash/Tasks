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
    
    init() {
        UITabBar.appearance().barTintColor = UIColor.black
        UITabBar.appearance().tintColor = UIColor.red
        UITabBar.appearance().isTranslucent = true
    }
    
    var body: some View {
        TabView {
            NavigationView {
                Text("Tasks list will be here")
                    .navigationBarTitle("Tasks")
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
        ContentView()
    }
}
