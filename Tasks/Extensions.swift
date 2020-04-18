//
//  Extensions.swift
//  Tasks
//
//  Created by Nick Garfitt on 11/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import Foundation
import CoreData

extension Date {

    func toGlobalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = -TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }

}

extension String {
    var nsString: NSString { return self as NSString }
    var length: Int { return nsString.length }
    var nsRange: NSRange { return NSRange(location: 0, length: length) }
    var detectDates: [Date]? {
        return try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
            .matches(in: self, range: nsRange)
            .compactMap{$0.date}
    }
}

extension Collection where Iterator.Element == String {
    var dates: [Date] {
        return compactMap{$0.detectDates}.flatMap{$0}
    }
}

extension NSFetchRequest {
    @objc func andPredicate(predicate: NSPredicate) {
    guard let currentPredicate = self.predicate else {
        self.predicate = predicate
        return
    }
    self.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [currentPredicate, predicate])
  }
}

extension Task {
    
    static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Task.due, ascending: true)]
    }
    
    static var sortedFetchRequest: NSFetchRequest<Task> {
        let request: NSFetchRequest<Task> = Task.fetchRequest() as! NSFetchRequest<Task>
        request.sortDescriptors = Task.defaultSortDescriptors
        return request
    }
    
    static var completedTasksRequest: NSFetchRequest<Task> {
      let request = Task.sortedFetchRequest
      request.predicate = NSPredicate(format: "done == true")
      return request
    }
    
}
