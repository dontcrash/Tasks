//
//  TodayViewController.swift
//  Tasks Widget
//
//  Created by Nick Garfitt on 19/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import UIKit
import SwiftUI
import CoreData
import NotificationCenter

class widgetData : UIViewController, ObservableObject {

    @Published var lastUpdate: Date = Date()
    @Published var due: Date = Date()
    @Published var tasks: [Task] = []
    @Published var isExpanded: Bool = false
    
}

class TodayViewController: UIViewController, NCWidgetProviding {
    
    func openMainApp(){
        print("method worked")
        extensionContext?.open(URL(string: "tasksics://")!)
    }
    
    let shared = WidgetView()
    var uiview: UIHostingController<TodayViewController.WidgetView>?
    
    struct WidgetView : View {
        
        @ObservedObject var model = widgetData()

        var body: some View {
            
            HStack {
                if model.tasks.count > 0 {
                    List(model.tasks) { task in
                        HStack {
                            //Image(systemName: task.done ? "checkmark.square" : "square")
                            //.padding(.trailing, 15)
                            Text(task.title)
                            .padding(.trailing, 15)
                            .truncationMode(.tail)
                            .lineLimit(1)
                            Spacer()
                            if task.done {
                                Text(Helper.shared.timeBetweenDates(d1: task.due).0)
                                .foregroundColor(.green)
                                .bold()
                                .font(.system(size: 14))
                            }else{
                                Text(Helper.shared.timeBetweenDates(d1: task.due).0)
                                .foregroundColor((Helper.shared.timeBetweenDates(d1: task.due).1) ? .red : .blue)
                                .bold()
                                .font(.system(size: 14))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    Text(Helper.allCompleted)
                }
            }
        }
        
    }
        
    @IBSegueAction func addSwiftUIView(_ coder: NSCoder) -> UIViewController? {
        uiview = UIHostingController(coder: coder, rootView: shared)!
        uiview?.view.backgroundColor = .clear
        //shared.body.onTapGesture {
        //    self.openMainApp()
        //}
        return uiview
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        UITableView.appearance().separatorStyle = .none
        refreshData()
    }
    
    func getResults() {
        let fetchRequest = NSFetchRequest<Task>(entityName: "Task")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Task.due, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "done == %@", NSNumber(value: false))
        fetchRequest.fetchLimit = 5
        do {
            shared.model.tasks = try CoreDataStack.persistentContainer.viewContext.fetch(fetchRequest)
        }
        catch {
            print("error executing fetch request: \(error)")
        }
    
    }
    
    func refreshData(){
        shared.model.lastUpdate = Date()
        getResults()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        let secondsSinceUpdate = Helper.shared.secondsBetweenDates(d1: shared.model.lastUpdate)
        if secondsSinceUpdate >= 600 {
            refreshData()
            completionHandler(NCUpdateResult.newData)
        }else{
             completionHandler(NCUpdateResult.noData)
        }
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize){
        if activeDisplayMode == .expanded {
            preferredContentSize = CGSize(width: 0.0, height: 250.0)
            shared.model.isExpanded = true
        } else {
            preferredContentSize = maxSize
            shared.model.isExpanded = false
        }
    }
    
}
