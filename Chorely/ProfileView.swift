//
//  ProfileView.swift
//  Chorely
//
//  Created by Brooke Tanner on 11/9/25.
//

import SwiftUI
import UserNotifications

struct ProfileView: View {
    @State private var name: String = "User's Name"
    @State private var color: Color = .blue
    @AppStorage("notificationsEnabled") private var notificationsOn = true
    @State private var showPermsAlert = false
    @State private var denied = false
    @State private var showLogOutAlert = false
    @State private var showJoinAlert = false
    @State private var showLeaveAlert = false
    @State private var showImagePicker = false
    @State private var profileImage: Image? = Image(systemName: "person.circle")
    
    private func handleToggleChange(_ on: Bool) {
        guard on else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if !granted {
                    self.notificationsOn = false
                    self.showPermsAlert = true
                }
            }
        }
    }

    private func refreshAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            DispatchQueue.main.async {
                self.denied = (s.authorizationStatus == .denied)
                if denied { self.notificationsOn = false }
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 20){
                
                VStack{
                    ZStack(alignment: .bottomTrailing){
                        profileImage?
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            .onTapGesture{showImagePicker.toggle() }
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.blue)
                            .offset(x: 8, y: 4)
                    }
                    TextField("User's Name", text: $name)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal)
                    
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(.gray, lineWidth: 1))
                    
                    Button("Change Color"){
                        //open color picker
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                VStack(spacing: 15){
                    NavigationLink(destination: EditProfileView(name: $name, color: $color)) {
                        ProfileRow(icon: "square.and.pencil", label: "Edit")
                    }
                    
                    Button{
                        showJoinAlert = true
                    } label: {
                        ProfileRow(icon: "person.3", label: "Join Group")
                    }
                    .alert("Join Group", isPresented: $showJoinAlert){
                        Button("Cancel", role: .cancel) {}
                        Button("Join", role: .none) {}
                    }message: {
                        Text("Enter group code to join.")
                    }
                    
                    NavigationLink(destination: AboutGroupView()){
                        ProfileRow(icon: "info.circle", label: "About Group")
                    }
                    
                    Button{
                        showLeaveAlert = true
                    } label: {
                        ProfileRow(icon: "rectangle.portrait.and.arrow.right", label: "Leave Group", color: .red)
                    }
                    .alert("Leave Group?", isPresented: $showLeaveAlert){
                        Button("Cancel", role: .cancel) {}
                        Button("Leave", role: .destructive) {}
                    }message: {
                        Text("Are you sure you want to leave this group?")
                    }
                }
                
                .padding(.horizontal)
                
                VStack(spacing: 8){
                    HStack {
                        Label("Notifications", systemImage: notificationsOn ? "bell.fill" : "bell.slash.fill")
                            .font(.headline)
                        Spacer()
                        Toggle(" ", isOn: $notificationsOn)
                            .padding(.horizontal, 24)
                    }
                    .padding(.horizontal,24)
                    
                        }
                }
                
                        
                Button{
                    showLogOutAlert = true
                }label:{
                    Text("Log Out")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(.red))
                }
                .alert("Log Out?", isPresented: $showLogOutAlert){
                    Button("Cancel", role: .cancel) {}
                    Button("Log Out", role: .destructive){}
                }message: {
                    Text("Are you sure you want to log out?")
                }
            NavigationView{
                NavigationLink(destination: HomeView(name: "", groupName: "")){
                    
                }
            }
                .padding(.vertical)
                .padding(.horizontal)
            }
            .navigationTitle("Profile")
            .onAppear { refreshAuthStatus() }
            .alert("Notifications are disabled in Settings", isPresented: $showPermsAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Open Settings") { openSettings() }
            } message: {
                Text("To enable notifications, allow them in iOS Settings.")
            }
        }
    }


struct ProfileRow: View{
    let icon: String
    let label: String
    var color: Color = .primary
    
    var body: some View{
        HStack{
            Image(systemName: icon)
                .foregroundColor(color)
            Text(label)
                .foregroundColor(color)
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct StatusChip: View {
    let isOn: Bool
    var body: some View{
        Text(isOn ? "ON" : "OFF")
            .font(.caption).bold()
            .padding(.horizontal,10).padding(.vertical,4)
            .background((isOn ? Color.green : Color.red).opacity(0.18))
            .foregroundStyle(isOn ? .green : .red)
            .clipShape(Capsule())
            .accessibilityLabel("Notifications \(isOn ? "On" : "Off")")
    }
}


struct EditProfileView: View{
    @Binding var name: String
    @Binding var color: Color
    var body: some View{
        Form{
            TextField("Name", text: $name)
            ColorPicker("Select Color", selection: $color)
        }
        .navigationTitle("Edit Profile")
        }
    }

struct AboutGroupView: View{
    var body: some View{
        Text("Group Info and Members")
            .navigationTitle("About Group")
    }
}


#Preview {
    ProfileView()
}
