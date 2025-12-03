//
//  ChoreItem.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/25/25.
//

import Foundation



struct ChoreItem: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let dueDate: TimeInterval
    let createdDate: TimeInterval
    var isDone: Bool
    
    mutating func setDone(_ state: Bool) {
        isDone = state
    }
}
