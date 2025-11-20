//
//  NewChoreView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/12/25.
//

import SwiftUI

// Navigates to the chores page
struct NewChoreView: View {
    var body: some View {
        VStack {
            Text("Chores")
                .bold()
                .font(.headline)
            Text("Chores List will go here!")
        }
    }
}

#Preview {
    NavigationStack {
        NewChoreView()
    }
}
