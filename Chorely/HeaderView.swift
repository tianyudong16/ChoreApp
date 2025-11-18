//
//  HeaderView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/17/25.
//
//   I (Tian) created a new file to contain the header design elements

import SwiftUI

struct HeaderView: View {
    let title: String
    let subtitle: String
    let angle: Double
    let background: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .foregroundColor(background)
                .rotationEffect(Angle(degrees: angle))
            
            VStack {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color.white)
                    .padding(.top)
                
                Text(subtitle)
                    .font(.system(size: 30))
                    .foregroundColor(Color.white)
            }
            .padding(.top, 80)
        }
        .frame(width: UIScreen.main.bounds.width * 3, height: 300)
        .offset(y: -150)
    }
}

#Preview {
    HeaderView(title: "Title",
               subtitle: "Subtitle",
               angle: 15,
               background: .blue)
}
