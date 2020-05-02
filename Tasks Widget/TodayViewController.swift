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
    @Published var tasks: [taskModel] = [taskModel]()
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
    
    func getTasks() -> [taskModel]? {
        do {
            if let data = UserDefaults(suiteName: "group.com.nick.tasks")?.value(forKey:"taskList") as? Data {
                let decodedList = try PropertyListDecoder().decode([taskModel].self, from: data)
                return decodedList
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func getResults() {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Task.due, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "done == %@", NSNumber(value: false))
        fetchRequest.fetchLimit = 5
        shared.model.tasks.removeAll()
        var results: [NSManagedObject] = []
        do {
            results = try CoreDataStack.persistentContainer.viewContext.fetch(fetchRequest)
            for task in results  {
                let t: taskModel = taskModel()
                t.title = task.value(forKey: "title") as! String
                t.due = task.value(forKey: "due") as! Date
                shared.model.tasks.append(t)
            }
        }
        catch {
            print("error executing fetch request: \(error)")
        }
    }
    
    func refreshData(){
        shared.model.lastUpdate = Date()
        getResults()
        //shared.model.tasks = getTasks() ?? [taskModel]()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
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
