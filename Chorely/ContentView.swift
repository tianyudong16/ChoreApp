import SwiftUI

// Make a simple struct for navigation data
struct UserInfo: Hashable {
    let name: String
    let groupName: String
}

struct ContentView: View {
    @State private var showTextFields = false
    @State private var name = ""
    @State private var groupName = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                // App title centered at top
                Text("Welcome to Chorely")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 200)
                
                Spacer()
                
                // Get Started button
                Button("Get Started") {
                    withAnimation {
                        showTextFields.toggle()
                    }
                }
                .foregroundColor(.black)
                .frame(width: 200, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 2)
                )
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                )
                
                Spacer()
                
                // Text Fields
                if showTextFields {
                    VStack(spacing: 20) {
                        TextField("Enter your name", text: $name)
                            .textFieldStyle(.roundedBorder)
                        TextField("Enter your group's name", text: $groupName)
                            .textFieldStyle(.roundedBorder)
                        
                        // NavigationLink now uses a Hashable struct
                        NavigationLink("Let's Go!", value: UserInfo(name: name, groupName: groupName))
                            .fontWeight(.bold)
                            .italic()
                            .disabled(name.isEmpty || groupName.isEmpty)
                    }
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.green.ignoresSafeArea())
            
            // Match the struct type here
            .navigationDestination(for: UserInfo.self) { info in
                HomeView(name: info.name, groupName: info.groupName)
            }
        }
    }
}



#Preview {
    ContentView()
}
