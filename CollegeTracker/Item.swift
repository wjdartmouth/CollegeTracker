//
//  Item.swift
//  CollegeTracker
//
//  Created by Jian Wang on 12/4/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
