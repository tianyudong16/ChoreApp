//
//  ChorelyButton.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/17/25.
//
// This file contains the default button styles and the actions are just defined within its respective function instead. This is just to have a consistent UI style for the buttons

import SwiftUI

struct ChorelyButton: View {
    let title: String
    let background: Color
    let action: () -> Void // default button takes no arguments
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(background)
                
                Text(title)
                    .foregroundColor(Color.white)
                    .bold()
            }
        }
    }
}

#Preview {
    ChorelyButton(title: "Value",
                  background: .blue) {
        // Action
    }
}
