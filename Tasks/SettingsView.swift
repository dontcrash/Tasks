//
//  SettingsView.swift
//  Tasks
//
//  Created by Nick Garfitt on 28/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    var cv: ContentView
    
    var body: some View {
        
        NavigationView {
            Form {
                HStack {
                    NavigationLink(destination: ICSURLView(delegate: cv, showSelf: cv.$showICSSettings), isActive: cv.$showICSSettings) {
                        VStack(alignment: .leading){
                           Button(action: {
                            self.cv.showICSSettings = true
                           }){
                               Text("Configure ICS URL")
                                   .foregroundColor(Color.blue)
                           }
                            
                        }
                    }
                }.padding(.vertical, 30)
                HStack {
                    Toggle(isOn: cv.$userPrefs.showCompleted) {
                        Text("Show completed")
                    }
                }.padding(.vertical, 30)
                HStack {
                    Button(action: {
                        self.cv.showDeleteAlert = true
                    }){
                        Text("Clear all cached tasks")
                            .foregroundColor(Color.red)
                    }
                    .alert(isPresented: cv.$showDeleteAlert) {
                        Alert(title: Text("Are you sure?"), message: Text("This will clear all cached tasks"), primaryButton: .destructive(Text("Clear")) {
                            Helper.shared.clearCoreData(ctx: self.cv.context)
                        }, secondaryButton: .cancel())
                    }
                }.padding(.vertical, 30)
                HStack {
                    Text("Tasks: " + (self.cv.userPrefs.showCompleted ? String(self.cv.allTasks.count) : String(self.cv.incompleteTasks.count)))
                    .foregroundColor(Color.gray)
                }.padding(.vertical, 30)
            }
            .navigationBarItems(trailing: (
                Button(action: {
                    self.cv.showConfigMenu = false
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
    
}
