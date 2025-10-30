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
            
            Spacer()
    
            // When pressed, text fields will show
            Button("Get Started") {
                print("hey there") // used for testing. Message will pop up in console when button is pressed in simulator
            }
            .foregroundColor(.black) // changes text color
            .frame(width: 200, height: 50) // size of button
            .background(Color.green.opacity(4.0)) // fill color
            .border(Color.black, width: 2) // border color

            Spacer() // pushes rest of content down
            
            TextField("Enter your name", text: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Value@*/.constant("")/*@END_MENU_TOKEN@*/)
            TextField("Enter your group's name", text: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Value@*/.constant("")/*@END_MENU_TOKEN@*/)
            
            Spacer()


            
            
            /*
            // Image of the globe
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
             // Label
             Text("Hello World!")
             */
                
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
