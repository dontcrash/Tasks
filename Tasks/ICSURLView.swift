//
//  ICSURLView.swift
//  Tasks
//
//  Created by Nick Garfitt on 28/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import SwiftUI

struct ICSURLView: View {
    
    var delegate: ContentView
    @State var changed: Bool = false
    
    @Binding var showSelf: Bool
    @ObservedObject var userPrefs = UserPrefs()
    
    var body: some View {
        Form {
            Section {
                TextField("website.com/file.ics", text: $userPrefs.icsURL, onEditingChanged: {_ in
                    self.delegate.userPrefs.icsURL = self.userPrefs.icsURL
                    self.changed = true
                }, onCommit: {
                    self.showSelf = false
                    
                })
                 .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            Section {
                Text("Please paste your iCalendar/ICS feed URL above, this will be the URL that the app updates your task list from")
            }
        }
        .navigationBarTitle(Text("ICS URL"), displayMode: .inline)
        .onDisappear(perform: {
            if self.changed {
                Helper.shared.clearCoreData(ctx: self.delegate.context)
                self.delegate.loadData(icsURL: self.delegate.userPrefs.icsURL)
            }
        })
    }
}
