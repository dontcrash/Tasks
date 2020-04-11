//
//  Extensions.swift
//  Tasks
//
//  Created by Nick Garfitt on 11/4/20.
//  Copyright © 2020 Nick Garfitt. All rights reserved.
//

import Foundation

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
