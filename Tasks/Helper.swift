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
    static let noDesc: String = "No description provided 😢"
    
    var allTasksComplete: Bool = false
  
    func hoursBetweenDates(d1: Date) -> Int {
        let cal = Calendar.current
        let components = cal.dateComponents([.hour], from: Date().toLocalTime(), to: d1.toLocalTime())
        return components.hour!
    }
    
    func isDueToday(d1: Date) -> Bool {
        let cal = Calendar.current
        let components = cal.dateComponents([.hour], from: Date().toLocalTime(), to: d1.toLocalTime())
        return components.hour! < 24
    }
    
    func isDueThisWeek(d1: Date) -> Bool {
        let cal = Calendar.current
        let components = cal.dateComponents([.day], from: Date().toLocalTime(), to: d1.toLocalTime())
        return components.day! <= 7 && components.day! >= 1
    }
    
    func isDueLater(d1: Date) -> Bool {
        let cal = Calendar.current
        let components = cal.dateComponents([.day], from: Date().toLocalTime(), to: d1.toLocalTime())
        return components.day! > 7
    }
    
    func secondsBetweenDates(d1: Date) -> Int {
        let cal = Calendar.current
        let components = cal.dateComponents([.second], from: Date().toLocalTime(), to: d1.toLocalTime())
        return components.second!
    }
    
    func minutesBetweenDates(d1: Date) -> Int {
        let cal = Calendar.current
        let components = cal.dateComponents([.minute], from: Date().toLocalTime(), to: d1.toLocalTime())
        return components.minute!
    }
    
    func timeBetweenDates(d1: Date) -> (String, Bool) {
        var minutes: Int = minutesBetweenDates(d1: d1)
        var hours: Int = minutes/60
        let late: Bool = (minutes < 0)
        if late {
            minutes = -minutes
            hours = -hours
        }
        if minutes < 60 {
            if minutes == 0 {
                return ("Now", late)
            }
            return (String(minutes) + " M", late)
        }
        if hours < 24 {
            return (String(hours) + " H", late)
        }else{
            var daysFloat: Float = Float(hours)/24.0
            daysFloat.round()
            let days: Int = Int(daysFloat)
            return (String(days) + " D", late)
        }
    }
    
    func clearCoreData(ctx: NSManagedObjectContext){
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "manual == %@", NSNumber(value: false))
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
    
    func deleteIndex(allTasks: FetchedResults<Task>, at offsets: IndexSet) {
        for offset in offsets {
            // find this book in our fetch request
            //print(offset)
            let task = allTasks[offset]
            print(task.title)

            // delete it from the context
            //moc.delete(book)
        }

        // save the context
        //try? moc.save()
    }
    
    func deleteTask(id: String, ctx: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Task")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
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
    
    func addTask(id: String, title: String, description: String, due: Date, manual: Bool, ctx: NSManagedObjectContext) {
        let newTask = Task(context: ctx)
        newTask.id = id
        newTask.title = title
        newTask.summary = description
        newTask.due = due
        newTask.done = false
        newTask.manual = manual
        do {
            try ctx.save()
        } catch {
            print(error)
            print(error.localizedDescription)
        }
    }
    
    func saveContext(ctx: NSManagedObjectContext) {
        do {
            try ctx.save()
        } catch {
            print(error)
            print(error.localizedDescription)
        }
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
        fetchRequest.fetchLimit = 5
        var arr: [taskModel] = [taskModel]()
        do {
            let list = try ctx.fetch(fetchRequest)
            for case let task as NSManagedObject in list  {
                let t: taskModel = taskModel()
                t.title = task.value(forKey: "title") as! String
                t.due = task.value(forKey: "due") as! Date
                t.done = task.value(forKey: "done") as! Bool
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
