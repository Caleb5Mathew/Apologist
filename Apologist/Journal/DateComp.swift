//
//  DateComp.swift
//  Apologist
//
//  Created by Caleb Matthews  on 1/17/25.
//

import Foundation

extension DateComponents {
    func isSameDayAs(_ other: DateComponents) -> Bool {
        guard let selfDate = Calendar.current.date(from: self),
              let otherDate = Calendar.current.date(from: other) else {
            return false
        }
        return Calendar.current.isDate(selfDate, inSameDayAs: otherDate)
    }
}
