//
//  ModalView.swift
//  Tasks
//
//  Created by Nick Garfitt on 11/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import CoreData
import SwiftUI

struct MenuView: View {
    
    @ObservedObject var userPrefs: UserPrefs
    var incompleteTasks: FetchedResults<Task>
    var allTasks: FetchedResults<Task>
    
    var body: some View {
        VStack(alignment: .leading) {
            /*
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.gray)
                    .imageScale(.large)
                Text("Tasks")
                    .foregroundColor(.gray)
                    .font(.headline)
            }
            .padding(.top, 100)
            */
            HStack {
                Image(systemName: "gear")
                    //.foregroundColor(.gray)
                    .imageScale(.large)
                Text("Settings")
                    //.foregroundColor(.gray)
                    .font(.headline)
            }
            .padding(.top, 100)
            Divider()
           .padding(.top, 30)
            HStack {
                Toggle(isOn: self.$userPrefs.showCompleted) {
                    Text("Show completed")
                }
            }
            .padding(.top, 30)
            Divider()
            .padding(.top, 30)
            Text("Total " + (self.userPrefs.showCompleted ? String(allTasks.count) : String(incompleteTasks.count)))
                .foregroundColor(Color.gray)
                .padding(.bottom, 50)
                .padding(.top, 30)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 32/255, green: 32/255, blue: 32/255))
        .edgesIgnoringSafeArea(.all)
    }
    
}
