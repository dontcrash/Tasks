//
//  TodayViewController.swift
//  Tasks Widget
//
//  Created by Nick Garfitt on 19/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    //let NC = NotificationCenter.default
        
    @IBOutlet weak var Label: UILabel!
    var lastString: String = ""
    var lastUpdate: Date = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //self.NC.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil, using: self.taskListUpdate(_:))
        lastString = SharedData.shared.retrieveData(key: "nextTask") as? String ?? "Please open the Tasks app"
        lastUpdate = Date()
        self.Label.text = lastString + " - " + getDueTime()
    }
    
    func getDueTime() -> String {
        return Helper.shared.timeBetweenDates(d1: SharedData.shared.retrieveData(key: "nextDue") as? Date ?? Date())
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        let newString: String = SharedData.shared.retrieveData(key: "nextTask") as? String ?? "Please open the Tasks app"
        let secondsSinceUpdate = Helper.shared.secondsBetweenDates(d1: lastUpdate)
        if lastString == newString && secondsSinceUpdate < 600 {
            lastUpdate = Date()
            completionHandler(NCUpdateResult.noData)
        }else{
            lastUpdate = Date()
            lastString = newString
            self.Label.text = lastString + " - " + getDueTime()
            completionHandler(NCUpdateResult.newData)
        }
    }
    
}
