//
//  ContentView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 10/29/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            
            // App title centered at top
            Text("Welcome to Chorely")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding() // distance from the top edge
            
            Spacer()
            
            Button("Get Started") {
                print("hey there")
            }
            .foregroundColor(.black) // changes text color
            .frame(width: 200, height: 50) // size of button
            .background(Color.green.opacity(4.0)) // fill color
            .border(Color.blue, width: 1) // border color

            Spacer() // pushes rest of content down
            
            
            // Image of the globe
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
             // Label
             Text("Hello World!")
                
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
