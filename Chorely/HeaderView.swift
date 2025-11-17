//
//  HeaderView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/17/25.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .foregroundColor(Color(hue: 0.353, saturation: 1.0, brightness: 0.569))
                .rotationEffect(Angle(degrees: 15))
            
            VStack {
                Text("Welcome to Chorely")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color.white)
                    .padding(.top)
                    
            }
            .padding(.top, 30)
        }
        .frame(width: UIScreen.main.bounds.width * 3, height: 300)
        .offset(y: -100)
    }
}

#Preview {
    HeaderView()
}
