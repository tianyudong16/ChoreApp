//
//  HomeView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/30/25.
//

import SwiftUI

// Home Screen
struct HomeView: View {
    var name: String
    var groupName: String
    
    var body: some View {
        VStack {
            Text("Welcome \(name)!")
                .font(.title.bold())
            
            Text("Group: \(groupName)")
                .font(.title)
                .foregroundColor(.secondary)
                .padding(.bottom, 30)
            
            Text("House Group Dashboard")
                .fontWeight(.heavy)
                .font(.system(size: 30))
            
            Spacer()
        }
        .padding()
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HomeView(name: "", groupName: "")
}
