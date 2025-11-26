//
//  ChoresView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/12/25.
//

import SwiftUI

// Navigates to the chores page
struct ChoresView: View {
    @StateObject var viewModel = ChoresViewModel()
    
    private let userID: String
    
    init(userID: String) {
        self.userID = userID
    }
    
    
    var body: some View {
        VStack {
            
        }
        .navigationTitle(Text("Chores"))
        .toolbar {
            Button {
                // Action
                viewModel.showingNewChoreView = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $viewModel.showingNewChoreView) {
            NewChoreView(newChorePresented: $viewModel.showingNewChoreView)
        }
    }
}

#Preview {
    NavigationStack {
        ChoresView(userID: "")
    }
}
