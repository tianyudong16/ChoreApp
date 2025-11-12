//
//  ChoresView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/12/25.
//

import SwiftUI

// Navigates to the chores page
struct ChoresView: View {
    var body: some View {
        Text("Chores List will go here!")
            .navigationTitle("Chores")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ChoresView()
    }
}
