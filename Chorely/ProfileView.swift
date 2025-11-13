import SwiftUI

struct ProfileView: View {
    @State private var username: String = "User's Name"
    @State private var profileColor: Color = .pink
    @State private var notificationsOn = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {

            // Profile Header
            HStack(alignment: .center, spacing: 15) {
                // Profile icon on left
                ZStack {
                    Circle()
                        .fill(profileColor.opacity(0.3))
                        .frame(width: 80, height: 80)
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                }
                .overlay(
                    Text("click to edit")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .offset(y: 45)
                        .padding(.top, 10)
                )
                .onTapGesture {
                    // TODO: open image picker later
                }
                
                // Username text
                VStack(alignment: .leading, spacing: 8) {
                    Text(username)
                        .font(.title2.bold())
                }
                
                Spacer()
                
                // Color picker on right
                ColorPicker("", selection: $profileColor, supportsOpacity: false)
                    .labelsHidden()
            }
            .padding(.top)
            
            Divider()
            
            // MARK: - Profile Menu Options
            VStack(spacing: 16) {
                ProfileOptionRow(label: "Join Group", color: .blue, icon: "person.2.fill")
                ProfileOptionRow(label: "About Group", color: .green, icon: "info.circle.fill")
                
                Button(role: .destructive) {
                    // TODO: add leave group logic
                } label: {
                    Text("Leave Group")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                
                Divider()
                
                // Notifications toggle
                HStack {
                    Text("Notifications")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: $notificationsOn)
                        .labelsHidden()
                }
                .padding(.horizontal)
                
                // Log out
                Button(role: .destructive) {
                    // TODO: handle logout
                } label: {
                    HStack {
                        Text("LOG OUT")
                            .font(.headline)
                            .foregroundColor(.red)
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
    }
}

// MARK: - Reusable Row Component
struct ProfileOptionRow: View {
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .clipShape(Circle())
            
            Text(label)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
