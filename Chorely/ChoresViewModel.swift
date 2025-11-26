//
//  ChoresViewModel.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/25/25.
//

import Foundation

/// ViewModel for list of chores view
/// Primary location for chores when "View Chores" button is clicked on the home page
class ChoresViewModel: ObservableObject {
    @Published var showingNewChoreView = false
    
    init() {}
}
