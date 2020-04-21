//
//  Helper.swift
//  Tasks
//
//  Created by Nick Garfitt on 19/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import UIKit
import SwiftUI
import CoreData
import Foundation

class Helper {
    
    static let shared = Helper()
    
    static let unopenedString: String = "Please open the Tasks app"
    static let allCompleted: String = "No tasks due 😊"
    var allTasksComplete: Bool = false
    var refreshControl: UIRefreshControl?
  
    func hoursBetweenDates(d1: Date) -> Int {
        let cal = Calendar.current
        let components = cal.dateComponents([.hour], from: Date().toLocalTime(), to: d1.toLocalTime())
        return components.hour!
    }
    
    func secondsBetweenDates(d1: Date) -> Int {
        let cal = Calendar.current
        let components = cal.dateComponents([.second], from: Date().toLocalTime(), to: d1.toLocalTime())
        return components.second!
    }
    
    func timeBetweenDates(d1: Date) -> String {
        let hours: Int = hoursBetweenDates(d1: d1)
        if hours < 24 {
            if hours <= 0 {
                return "Late"
            }
            if hours == 1 {
                return "Now"
            }
            return String(hours) + " hours"
        }else{
            var daysFloat: Float = Float(hours)/24.0
            daysFloat.round()
            let days: Int = Int(daysFloat)
            if days == 1 {
                return String(hours) + " hours"
                //return "1 day"
            }
            return String(days) + " days"
        }
    }
    
    func clearCoreData(ctx: NSManagedObjectContext){
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        var results: [NSManagedObject] = []
        do {
            results = try ctx.fetch(fetchRequest)
            for object in results {
                ctx.delete(object)
            }
        }
        catch {
            print("error executing fetch request: \(error)")
        }
        do {
            try ctx.save()
            
        } catch {
            print(error)
            print(error.localizedDescription)
        }
        setNextTask(ctx: ctx)
    }
    
    func taskExists(id: String, ctx: NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        var results: [NSManagedObject] = []
        do {
            results = try ctx.fetch(fetchRequest)
        }
        catch {
            print("error executing fetch request: \(error)")
        }
        return results.count > 0
    }
    
    func setNextTask(ctx: NSManagedObjectContext){
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Task")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Task.due, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "done == %@", NSNumber(value: false))
        fetchRequest.fetchLimit = 3
        var arr: [taskModel] = [taskModel]()
        do {
            let list = try ctx.fetch(fetchRequest)
            for case let task as NSManagedObject in list  {
                let t: taskModel = taskModel()
                t.title = task.value(forKey: "title") as! String
                t.due = task.value(forKey: "due") as! Date
                arr.append(t)
            }
            UserDefaults(suiteName: "group.com.nick.tasks")?.set(try? PropertyListEncoder().encode(arr), forKey: "taskList")
            UserDefaults(suiteName: "group.com.nick.tasks")?.synchronize()
            //UserDefaults(suiteName: "group.com.nick.tasks").encode(for: arr, using: String(describing: taskModel.self))
            /*
            if list.count > 0 {
                let taskUpdate = list[0] as! NSManagedObject
                nextTask = taskUpdate.value(forKey: "title") as! String
                nextDue = taskUpdate.value(forKey: "due") as! Date
            }else{
                nextTask = Helper.allCompleted
            }
            */
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        //SharedData.shared.saveData(value: nextTask, key: "nextTask")
        //SharedData.shared.saveData(value: nextDue, key: "nextDue")
    }
    
    func changeTaskStatus(task: Task, done: Bool, ctx: NSManagedObjectContext){
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        fetchRequest.fetchLimit = 1
        do {
            let test = try ctx.fetch(fetchRequest)
            let taskUpdate = test[0] as! NSManagedObject
            taskUpdate.setValue(done, forKey: "done")
            try ctx.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        Helper.shared.setNextTask(ctx: ctx)
    }
    
    func updateTask(id: String, due: Date, title: String, desc: String, ctx: NSManagedObjectContext){
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        do {
            let test = try ctx.fetch(fetchRequest)
            let taskUpdate = test[0] as! NSManagedObject
            taskUpdate.setValue(due, forKey: "due")
            taskUpdate.setValue(title, forKey: "title")
            taskUpdate.setValue(desc, forKey: "summary")
            try ctx.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        Helper.shared.setNextTask(ctx: ctx)
    }
    
}