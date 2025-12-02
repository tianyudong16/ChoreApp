//
//  ProfileView.swift
//  Chorely
//
//  Created by Brooke Tanner on 11/9/25.
//

import SwiftUI
import UserNotifications
import PhotosUI
import FirebaseFirestore

// ProfileColor enum is defined in ProfileColor.swift

// User profile screen showing personal info, group info, and settings
struct ProfileView: View {
    let userID: String       // Firebase user ID
    let onLogout: () -> Void // Callback to handle logout
    
    // User data state
    @State private var name: String = "User's Name"
    @State private var color: Color = .blue
    @State private var groupCodeDisplay: String = ""
    @State private var groupName: String = ""
    @State private var isLoading = true
    
    // Notification settings (persisted across app launches)
    @AppStorage("notificationsEnabled") private var notificationsOn = true
    @State private var showPermsAlert = false
    @State private var denied = false
    
    // Alert states
    @State private var showLogOutAlert = false
    @State private var showJoinAlert = false
    @State private var showLeaveAlert = false
    @State private var showImagePicker = false
    
    // Profile photo state
    @State private var profileImage: Image? = Image(systemName: "person.circle")
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var groupCode: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        loadingSection
                    } else {
                        profileHeaderSection
                        Divider().padding(.horizontal)
                        groupInfoSection
                        groupActionsSection
                        notificationsSection
                        logoutSection
                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                refreshAuthStatus()
                fetchUserData()
            }
            // Alert for notification permissions
            .alert("Notifications are disabled in Settings", isPresented: $showPermsAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Open Settings") { openSettings() }
            } message: {
                Text("To enable notifications, allow them in iOS Settings.")
            }
            // Handle photo selection
            .onChange(of: selectedPhotoItem, initial: false) { oldItem, newItem in
                handlePhotoSelection(newItem)
            }
        }
    }
    
    // Loading spinner while fetching user data
    private var loadingSection: some View {
        VStack {
            Spacer()
            ProgressView("Loading profile...")
                .padding(.top, 100)
            Spacer()
        }
    }
    
    // Profile picture, name, and color picker
    private var profileHeaderSection: some View {
        VStack(spacing: 15) {
            profilePicturePicker
            nameTextField
            colorPickerGrid
        }
        .padding(.top, 20)
    }
    
    // Tappable profile picture with edit indicator
    private var profilePicturePicker: some View {
        PhotosPicker(selection: $selectedPhotoItem,
                     matching: .images,
                     photoLibrary: .shared()) {
            ZStack(alignment: .bottomTrailing) {
                // Colored circle with user's initial
                Circle()
                    .fill(color)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(String(name.prefix(1)).uppercased())
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: color.opacity(0.4), radius: 4, y: 2)

                // Edit pencil icon
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.blue)
                    .offset(x: 8, y: 4)
            }
        }
    }
    
    // Editable name field - saves on submit
    private var nameTextField: some View {
        TextField("User's Name", text: $name)
            .font(.title2)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.words)
            .padding(.horizontal)
            .onSubmit {
                saveNameToFirebase(name)
            }
    }
    
    // Grid of color options (2 rows of 5)
    private var colorPickerGrid: some View {
        VStack(spacing: 8) {
            Text("Your Color")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // First row: Red, Blue, Green, Yellow, Orange
            HStack(spacing: 12) {
                ForEach(ProfileColor.allCases.prefix(5)) { profileColor in
                    ColorCircleButton(
                        profileColor: profileColor,
                        isSelected: color == profileColor.color,
                        onTap: { selectColor(profileColor) }
                    )
                }
            }
            
            // Second row: Purple, Pink, Cyan, Mint, Teal
            HStack(spacing: 12) {
                ForEach(ProfileColor.allCases.suffix(5)) { profileColor in
                    ColorCircleButton(
                        profileColor: profileColor,
                        isSelected: color == profileColor.color,
                        onTap: { selectColor(profileColor) }
                    )
                }
            }
        }
        .padding(.top, 8)
    }
    
    // Shows group name and code with copy button
    private var groupInfoSection: some View {
        Group {
            if !groupCodeDisplay.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Group: \(groupName)")
                            .font(.headline)
                        Text("Code: \(groupCodeDisplay)")
                            .font(.subheadline.monospaced())
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // Copy to clipboard button
                    Button {
                        UIPasteboard.general.string = groupCodeDisplay
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    // Join Group, About Group, and Leave Group buttons
    private var groupActionsSection: some View {
        VStack(spacing: 15) {
            // Join Group button with alert
            Button { showJoinAlert = true } label: {
                ProfileRow(icon: "person.3", label: "Join Group")
            }
            .alert("Join Group", isPresented: $showJoinAlert) {
                TextField("Group code", text: $groupCode)
                Button("Cancel", role: .cancel) {}
                Button("Join") { /* TODO: Implement join functionality */ }
            } message: {
                Text("Enter group code to join.")
            }
            
            // About Group navigation link
            NavigationLink(destination: AboutGroupView()) {
                ProfileRow(icon: "info.circle", label: "About Group")
            }
            
            // Leave Group button with confirmation
            Button { showLeaveAlert = true } label: {
                ProfileRow(icon: "rectangle.portrait.and.arrow.right", label: "Leave Group", color: .red)
            }
            .alert("Leave Group?", isPresented: $showLeaveAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Leave", role: .destructive) { /* TODO: Implement leave functionality */ }
            } message: {
                Text("Are you sure you want to leave this group?")
            }
        }
        .padding(.horizontal)
    }
    
    // Notifications toggle
    private var notificationsSection: some View {
        HStack {
            Label("Notifications", systemImage: notificationsOn ? "bell.fill" : "bell.slash.fill")
                .font(.headline)
            Spacer()
            Toggle("", isOn: $notificationsOn)
                .onChange(of: notificationsOn) { _, newValue in
                    handleToggleChange(newValue)
                }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
    
    // Logout button with confirmation
    private var logoutSection: some View {
        Button { showLogOutAlert = true } label: {
            Text("Log Out")
                .font(.headline)
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 8).stroke(.red))
        }
        .padding(.horizontal)
        .alert("Log Out?", isPresented: $showLogOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                // Sign out using pre-existing function
                FirebaseInterface.shared.signOut()
                onLogout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
    
    // Handles notification toggle - requests permission if enabling
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

    // Checks current notification authorization status
    private func refreshAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            DispatchQueue.main.async {
                self.denied = (s.authorizationStatus == .denied)
                if denied { self.notificationsOn = false }
            }
        }
    }

    // Opens iOS Settings app for notification permissions
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    // Updates color state and saves to Firebase
    private func selectColor(_ profileColor: ProfileColor) {
        withAnimation {
            color = profileColor.color
            saveColorToFirebase(profileColor.color)
        }
    }
    
    // Handles photo picker selection
    private func handlePhotoSelection(_ newItem: PhotosPickerItem?) {
        guard let newItem else { return }
        
        Task {
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                profileImage = Image(uiImage: uiImage)
            }
        }
    }
    
    // Fetches user profile data from Firebase
    private func fetchUserData() {
        isLoading = true
        
        Task {
            do {
                // Use pre-existing getUserData function
                let userData = try await FirebaseInterface.shared.getUserData(uid: userID)
                
                await MainActor.run {
                    isLoading = false
                    
                    // Extract user fields from Firebase data
                    name = userData["Name"] as? String ?? "User"
                    groupName = userData["groupName"] as? String ?? "Home"
                    
                    // Extract group key using pre-existing helper
                    let keys = FirebaseInterface.shared.extractGroupKey(from: userData)
                    groupCodeDisplay = keys.string ?? ""
                    
                    // Convert color string to Color
                    let colorString = userData["color"] as? String ?? "Green"
                    color = ProfileColor.fromString(colorString).color
                }
            } catch {
                await MainActor.run {
                    print("Error loading user data: \(error)")
                    isLoading = false
                }
            }
        }
    }
    
    // Saves user's color choice to Firebase
    private func saveColorToFirebase(_ newColor: Color) {
        let profileColor = ProfileColor.fromColor(newColor)
        // Use pre-existing updateUserField function
        FirebaseInterface.shared.updateUserField(
            userID: userID,
            field: "color",
            value: profileColor.rawValue
        ) { error in
            if error == nil {
                print("Color saved: \(profileColor.rawValue)")
            }
        }
    }
    
    // Saves user's name to Firebase
    private func saveNameToFirebase(_ newName: String) {
        // Use pre-existing updateUserField function
        FirebaseInterface.shared.updateUserField(
            userID: userID,
            field: "Name",
            value: newName
        ) { error in
            if error == nil {
                print("Name saved: \(newName)")
            }
        }
    }
}

// Tappable color circle for the color picker
struct ColorCircleButton: View {
    let profileColor: ProfileColor
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Circle()
            .fill(profileColor.color)
            .frame(width: 36, height: 36)
            .overlay(
                // Show border when selected
                Circle()
                    .strokeBorder(Color.primary, lineWidth: isSelected ? 3 : 0)
            )
            .shadow(color: profileColor.color.opacity(0.3), radius: 2, y: 1)
            .onTapGesture { onTap() }
    }
}

// Reusable row for profile menu items
struct ProfileRow: View {
    let icon: String // SF Symbol name
    let label: String // Text label
    var color: Color = .primary // Icon and text color
    
    var body: some View {
        HStack {
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

// Shows ON/OFF status badge for notifications
struct NotificationToggle: View {
    let isOn: Bool
    
    var body: some View {
        Text(isOn ? "ON" : "OFF")
            .font(.caption).bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background((isOn ? Color.green : Color.red).opacity(0.18))
            .foregroundStyle(isOn ? .green : .red)
            .clipShape(Capsule())
            .accessibilityLabel("Notifications \(isOn ? "On" : "Off")")
    }
}

// Profile editing view (for future use)
struct EditProfileView: View {
    @Binding var name: String
    @Binding var color: Color
    
    var body: some View {
        Form {
            TextField("Name", text: $name)
            ColorPicker("Select Color", selection: $color)
        }
        .navigationTitle("Edit Profile")
    }
}

// Shows group information (placeholder for future implementation)
struct AboutGroupView: View {
    var body: some View {
        Text("Group Info and Members")
            .navigationTitle("About Group")
    }
}

#Preview {
    ProfileView(userID: "test", onLogout: {})
}
