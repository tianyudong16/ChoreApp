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

// Defines the available colors users can choose for their profile
// These colors are used to identify users in the group
// I only picked these few colors for simplicity. Realistically, there wouldn't be more than these number of people but can be adjusted in the future
enum ProfileColor: String, CaseIterable, Identifiable {
    case red = "Red"
    case blue = "Blue"
    case green = "Green"
    case yellow = "Yellow"
    case orange = "Orange"
    case purple = "Purple"
    case pink = "Pink"
    case cyan = "Cyan"
    case mint = "Mint"
    case teal = "Teal"
    
    // Required for Identifiable protocol - allows ForEach to iterate over colors
    var id: String { rawValue }
    
    // Converts the enum case to a SwiftUI Color for display
    var color: Color {
        switch self {
        case .red:
            return .red
        case .blue:
            return .blue
        case .green:
            return .green
        case .yellow:
            return .yellow
        case .orange:
            return .orange
        case .purple:
            return .purple
        case .pink:
            return .pink
        case .cyan:
            return .cyan
        case .mint:
            return .mint
        case .teal:
            return .teal
        }
    }
    
    static func fromString(_ string: String) -> ProfileColor {
        return ProfileColor(rawValue: string) ?? .green
    }
    
    static func fromColor(_ color: Color) -> ProfileColor {
        for profileColor in ProfileColor.allCases {
            if profileColor.color == color {
                return profileColor
            }
        }
        return .green
    }
}

struct ProfileView: View {
    let userID: String
    let onLogout: () -> Void
    
    @State private var name: String = "User's Name"
    @State private var color: Color = .blue
    @State private var groupCodeDisplay: String = ""
    @State private var groupName: String = ""
    @State private var isLoading = true
    
    @AppStorage("notificationsEnabled") private var notificationsOn = true
    @State private var showPermsAlert = false
    @State private var denied = false
    
    @State private var showLogOutAlert = false
    @State private var showJoinAlert = false
    @State private var showLeaveAlert = false
    @State private var showImagePicker = false
    
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
            .alert("Notifications are disabled in Settings", isPresented: $showPermsAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Open Settings") { openSettings() }
            } message: {
                Text("To enable notifications, allow them in iOS Settings.")
            }
            .onChange(of: selectedPhotoItem, initial: false) { oldItem, newItem in
                handlePhotoSelection(newItem)
            }
        }
    }
    
    private var loadingSection: some View {
        VStack {
            Spacer()
            ProgressView("Loading profile...")
                .padding(.top, 100)
            Spacer()
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: 15) {
            profilePicturePicker
            nameTextField
            colorPickerGrid
        }
        .padding(.top, 20)
    }
    
    private var profilePicturePicker: some View {
        PhotosPicker(selection: $selectedPhotoItem,
                     matching: .images,
                     photoLibrary: .shared()) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(color)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(String(name.prefix(1)).uppercased())
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: color.opacity(0.4), radius: 4, y: 2)

                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.blue)
                    .offset(x: 8, y: 4)
            }
        }
    }
    
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
    
    private var colorPickerGrid: some View {
        VStack(spacing: 8) {
            Text("Your Color")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach(ProfileColor.allCases.prefix(5)) { profileColor in
                    ColorCircleButton(
                        profileColor: profileColor,
                        isSelected: color == profileColor.color,
                        onTap: { selectColor(profileColor) }
                    )
                }
            }
            
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
    
    private var groupActionsSection: some View {
        VStack(spacing: 15) {
            Button { showJoinAlert = true } label: {
                ProfileRow(icon: "person.3", label: "Join Group")
            }
            .alert("Join Group", isPresented: $showJoinAlert) {
                TextField("Group code", text: $groupCode)
                Button("Cancel", role: .cancel) {}
                Button("Join") { }
            } message: {
                Text("Enter group code to join.")
            }
            
            NavigationLink(destination: AboutGroupView()) {
                ProfileRow(icon: "info.circle", label: "About Group")
            }
            
            Button { showLeaveAlert = true } label: {
                ProfileRow(icon: "rectangle.portrait.and.arrow.right", label: "Leave Group", color: .red)
            }
            .alert("Leave Group?", isPresented: $showLeaveAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Leave", role: .destructive) { }
            } message: {
                Text("Are you sure you want to leave this group?")
            }
        }
        .padding(.horizontal)
    }
    
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
                FirebaseInterface.shared.signOut()
                onLogout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
    
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
    
    private func selectColor(_ profileColor: ProfileColor) {
        withAnimation {
            color = profileColor.color
            saveColorToFirebase(profileColor.color)
        }
    }
    
    private func handlePhotoSelection(_ newItem: PhotosPickerItem?) {
        guard let newItem else { return }
        
        Task {
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                profileImage = Image(uiImage: uiImage)
            }
        }
    }
    
    private func fetchUserData() {
        isLoading = true
        
        Task {
            do {
                let userData = try await FirebaseInterface.shared.getUserData(uid: userID)
                
                await MainActor.run {
                    isLoading = false
                    
                    name = userData["Name"] as? String ?? "User"
                    groupName = userData["groupName"] as? String ?? "Home"
                    
                    let keys = FirebaseInterface.shared.extractGroupKey(from: userData)
                    groupCodeDisplay = keys.string ?? ""
                    
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
    
    private func saveColorToFirebase(_ newColor: Color) {
        let profileColor = ProfileColor.fromColor(newColor)
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
    
    private func saveNameToFirebase(_ newName: String) {
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

struct ColorCircleButton: View {
    let profileColor: ProfileColor
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Circle()
            .fill(profileColor.color)
            .frame(width: 36, height: 36)
            .overlay(
                Circle()
                    .strokeBorder(Color.primary, lineWidth: isSelected ? 3 : 0)
            )
            .shadow(color: profileColor.color.opacity(0.3), radius: 2, y: 1)
            .onTapGesture { onTap() }
    }
}

struct ProfileRow: View {
    let icon: String
    let label: String
    var color: Color = .primary
    
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

struct AboutGroupView: View {
    var body: some View {
        Text("Group Info and Members")
            .navigationTitle("About Group")
    }
}

#Preview {
    ProfileView(userID: "test", onLogout: {})
}
