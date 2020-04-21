//
//  TodayViewController.swift
//  Tasks Widget
//
//  Created by Nick Garfitt on 19/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import UIKit
import SwiftUI
import NotificationCenter

class widgetData : ObservableObject {

    @Published var lastUpdate: Date = Date()
    @Published var due: Date = Date()
    @Published var tasks: [taskModel] = [taskModel]()
    @Published var isExpanded: Bool = false
    
}

class TodayViewController: UIViewController, NCWidgetProviding {
    
    let shared = WidgetView()
    var uiview: UIHostingController<TodayViewController.WidgetView>?
    
    struct WidgetView : View {
        
        @ObservedObject var model = widgetData()

        var body: some View {
            HStack {
                if model.tasks.count > 0 && model.isExpanded {
                    List(model.tasks) { task in
                        HStack {
                            Text(task.title)
                            Spacer()
                            if (["Late","Now"].contains (Helper.shared.timeBetweenDates(d1: task.due))) {
                                  Text(Helper.shared.timeBetweenDates(d1: task.due))
                                  .foregroundColor(.red)
                                  .bold()
                            }else{
                                Text(Helper.shared.timeBetweenDates(d1: task.due))
                                .bold()
                            }
                        }
                        .padding(.vertical, 3)
                    }
                } else if model.tasks.count > 0 {
                    List {
                        HStack {
                            Text(model.tasks[0].title)
                            Spacer()
                            if (["Late","Now"].contains (Helper.shared.timeBetweenDates(d1: model.tasks[0].due))) {
                                  Text(Helper.shared.timeBetweenDates(d1: model.tasks[0].due))
                                  .foregroundColor(.red)
                                  .bold()
                            }else{
                                Text(Helper.shared.timeBetweenDates(d1: model.tasks[0].due))
                                .bold()
                            }
                        }
                        .padding(.vertical, 3)
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
        return uiview
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
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
    
    func refreshData(){
        shared.model.lastUpdate = Date()
        shared.model.tasks = getTasks() ?? [taskModel]()
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
