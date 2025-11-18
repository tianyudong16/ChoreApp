//
//  RegisterView.swift
//  Chorely
//
//  Created by Tian Yu Dong on 11/17/25.
//

import SwiftUI

struct RegisterView: View {
    var body: some View {
        VStack {
            // Header
            HeaderView(title: "Create An Account",
                       subtitle: "Organize your chores today!",
                       angle: -15,
                       background: .yellow)
            
            Spacer()
        }
    }
}

#Preview {
    RegisterView()
}
