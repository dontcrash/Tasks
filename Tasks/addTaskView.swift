//
//  addTaskView.swift
//  Tasks
//
//  Created by Nick Garfitt on 27/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import Foundation
import SwiftUI

struct addTaskView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("\n\nThanks for downloading my app, this app is intended for use with an iCalendar/ICS feed URL to keep track of assignments/tasks.\n\nThis app will automatically take all the data from your feed URL and convert it into an easy to use list, some Universities/Colleges provide this, consult with your individual institution to check if this is something that is offered to you. 😃").padding(.all, 15)
                Spacer()
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Thanks!")
                }.padding(.bottom, 50)
            }.navigationBarTitle("Help")
        }
    }
    
}

struct addTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return TutorialView().environment(\.managedObjectContext, context)
    }
}
