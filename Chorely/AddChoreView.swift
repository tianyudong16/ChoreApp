//
//  AddChoreView.swift
//  Chorely
//
//  Created by Brooke Tanner on 11/19/25.
// used this tutorial //https://www.youtube.com/watch?v=EEcmRaeZ7ik

import SwiftUI

struct AddChoreView: View {
    var body: some View {
        VStack{
            Menu{
                Button("Chore"){
                    
                }
                Button("Chore 2"){
                    
                }
                Button("Chore 3"){
                    
                }
            }
            label:{
                Label("Select Chore", systemImage: "menucard")
            }
        }
        .padding()
    }
}

#Preview {
    AddChoreView()
}
