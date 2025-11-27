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

// MARK: - ProfileColor Enum
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
    
    // Creates a ProfileColor from a string (used when loading from Firebase)
    // Returns .green as default if the string doesn't match any color
    static func fromString(_ string: String) -> ProfileColor {
        return ProfileColor(rawValue: string) ?? .green
    }
    
    // Attempts to match a SwiftUI Color to a ProfileColor
    // Used when saving color selection to Firebase
    static func fromColor(_ color: Color) -> ProfileColor {
        for profileColor in ProfileColor.allCases {
            if profileColor.color == color {
                return profileColor
            }
        }
        return .green // Default fallback
    }
}

// MARK: - ProfileView
struct ProfileView: View {
    // MARK: - Properties
    
    // User's Firebase document ID - passed from MainTabView
    let userID: String
    
    // Callback function to handle logout - navigates back to login screen
    let onLogout: () -> Void
    
    // MARK: - State Variables (User Data)
    @State private var name: String = "User's Name" // User's display name
    @State private var color: Color = .blue // User's chosen color
    @State private var groupCodeDisplay: String = "" // Group code to show/copy
    @State private var groupName: String = "" // Name of user's group
    @State private var isLoading = true // Shows loading spinner while fetching data
    
    // MARK: - State Variables (Notifications)
    @AppStorage("notificationsEnabled") private var notificationsOn = true // Persists notification preference
    @State private var showPermsAlert = false // Shows alert when notification permission denied
    @State private var denied = false // Tracks if notifications are denied in settings
    
    // MARK: - State Variables (Alerts & Sheets)
    @State private var showLogOutAlert = false // Confirmation dialog for logout
    @State private var showJoinAlert = false // Alert to enter group code
    @State private var showLeaveAlert = false // Confirmation dialog for leaving group
    @State private var showImagePicker = false // Photo picker sheet
    
    // MARK: - State Variables (Photo & Input)
    @State private var profileImage: Image? = Image(systemName: "person.circle") // Profile photo
    @State private var selectedPhotoItem: PhotosPickerItem? = nil // Selected photo from picker
    @State private var groupCode: String = "" // Text field input for joining a group
    
    // MARK: - Notification Helper Functions
    /// Requests notification permissions when user enables notifications toggle
    private func handleToggleChange(_ on: Bool) {
        guard on else { return }
        // UNUserNotificationCenter gets the shared notification center to the user's app settings
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            // This closure runs AFTER user responds to permission popup
            // Must update UI on main thread
            DispatchQueue.main.async {
                if !granted {
                    self.notificationsOn = false
                    self.showPermsAlert = true
                }
            }
        }
    }

    /// Checks current notification authorization status from iOS settings
    private func refreshAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            DispatchQueue.main.async {
                self.denied = (s.authorizationStatus == .denied)
                if denied { self.notificationsOn = false }
            }
        }
    }

    /// Opens iOS Settings app so user can enable notifications
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Firebase Functions
    
    // Loads user data from Firebase Firestore
    // Fetches: name, color, group name, and group code
    private func loadUserData() {
        isLoading = true
        
        // Query the Users collection for this user's document
        FirebaseInterface.shared.firestore
            .collection("Users")
            .document(userID)
            .getDocument { snapshot, error in
                // Ensure UI updates happen on main thread
                DispatchQueue.main.async {
                    isLoading = false
                    
                    // Handle any errors
                    if let error = error {
                        print("Error loading user data: \(error)")
                        return
                    }
                    
                    // Make sure we got data back
                    guard let data = snapshot?.data() else {
                        print("No user data found")
                        return
                    }
                    
                    // Extract user fields from the document
                    name = data["Name"] as? String ?? "User"
                    groupName = data["groupName"] as? String ?? "Home"
                    
                    // groupKey can be stored as Int or String, handle both cases
                    if let groupKeyInt = data["groupKey"] as? Int {
                        groupCodeDisplay = String(groupKeyInt)
                    } else if let groupKeyStr = data["groupKey"] as? String {
                        groupCodeDisplay = groupKeyStr
                    }
                    
                    // Convert stored color string to Color
                    let colorString = data["color"] as? String ?? "Green"
                    color = ProfileColor.fromString(colorString).color
                }
            }
    }
    
    /// Saves the user's selected color to Firebase
    // the newColor parameter is the SwiftUI Color to save
    private func saveColorToFirebase(_ newColor: Color) {
        // Convert Color to ProfileColor to get the string value
        let profileColor = ProfileColor.fromColor(newColor)
        
        // Update only the color field in the user's document
        FirebaseInterface.shared.firestore
            .collection("Users")
            .document(userID)
            .updateData(["color": profileColor.rawValue]) { error in
                if let error = error {
                    print("Error saving color: \(error)")
                } else {
                    print("Color saved: \(profileColor.rawValue)")
                }
            }
    }
    
    /// Saves the user's name to Firebase
    // newName parameter is the new name to save
    private func saveNameToFirebase(_ newName: String) {
        FirebaseInterface.shared.firestore
            .collection("Users")
            .document(userID)
            .updateData(["Name": newName]) { error in
                if let error = error {
                    print("Error saving name: \(error)")
                } else {
                    print("Name saved: \(newName)")
                }
            }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: Loading State
                    if isLoading {
                        Spacer()
                        ProgressView("Loading profile...")
                            .padding(.top, 100)
                        Spacer()
                    } else {
                        
                        // MARK: Profile Header Section
                        // Shows profile picture, name, and color picker
                        VStack(spacing: 15) {
                            
                            // Profile Picture with Photo Picker
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
                           
                            // Editable Name Field
                            // Saves to Firebase when user presses return
                            TextField("User's Name", text: $name)
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.words)
                                .padding(.horizontal)
                                .onSubmit {
                                    saveNameToFirebase(name)
                                }
                            
                            // MARK: Color Picker Grid
                            // Two rows of 5 colors each
                            VStack(spacing: 8) {
                                Text("Your Color")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // First row of colors (Red, Blue, Green, Yellow, Orange)
                                HStack(spacing: 12) {
                                    ForEach(ProfileColor.allCases.prefix(5)) { profileColor in
                                        ColorCircleButton(
                                            profileColor: profileColor,
                                            isSelected: color == profileColor.color,
                                            onTap: {
                                                withAnimation {
                                                    color = profileColor.color
                                                    saveColorToFirebase(profileColor.color)
                                                }
                                            }
                                        )
                                    }
                                }
                                
                                // Second row of colors (Purple, Pink, Cyan, Mint, Teal)
                                HStack(spacing: 12) {
                                    ForEach(ProfileColor.allCases.suffix(5)) { profileColor in
                                        ColorCircleButton(
                                            profileColor: profileColor,
                                            isSelected: color == profileColor.color,
                                            onTap: {
                                                withAnimation {
                                                    color = profileColor.color
                                                    saveColorToFirebase(profileColor.color)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.top, 20)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // MARK: Group Info Section
                        // Shows current group name and code with copy button
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
                        
                        // MARK: Group Actions Section
                        // Join group, about group, and leave group buttons
                        VStack(spacing: 15) {
                            
                            // Join Group Button
                            Button {
                                showJoinAlert = true
                            } label: {
                                ProfileRow(icon: "person.3", label: "Join Group")
                            }
                            .alert("Join Group", isPresented: $showJoinAlert) {
                                TextField("Group code", text: $groupCode)
                                Button("Cancel", role: .cancel) {}
                                Button("Join") {
                                    // TODO: Implement join group functionality
                                }
                            } message: {
                                Text("Enter group code to join.")
                            }
                            
                            // About Group Navigation Link
                            NavigationLink(destination: AboutGroupView()) {
                                ProfileRow(icon: "info.circle", label: "About Group")
                            }
                            
                            // Leave Group Button
                            Button {
                                showLeaveAlert = true
                            } label: {
                                ProfileRow(icon: "rectangle.portrait.and.arrow.right", label: "Leave Group", color: .red)
                            }
                            .alert("Leave Group?", isPresented: $showLeaveAlert) {
                                Button("Cancel", role: .cancel) {}
                                Button("Leave", role: .destructive) {
                                    // TODO: Implement leave group functionality
                                }
                            } message: {
                                Text("Are you sure you want to leave this group?")
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: Notifications Toggle
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
                        
                        // MARK: Logout Button
                        Button {
                            showLogOutAlert = true
                        } label: {
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
                                // Sign out from Firebase and trigger logout callback
                                FirebaseInterface.shared.signOut()
                                onLogout()
                            }
                        } message: {
                            Text("Are you sure you want to log out?")
                        }
                        
                        // Bottom padding to ensure content isn't hidden by tab bar
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                // Check notification status and load user data when view appears
                refreshAuthStatus()
                loadUserData()
            }
            // Alert for when notifications are disabled in iOS settings
            .alert("Notifications are disabled in Settings", isPresented: $showPermsAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Open Settings") { openSettings() }
            } message: {
                Text("To enable notifications, allow them in iOS Settings.")
            }
            // Handle photo selection from PhotosPicker
            .onChange(of: selectedPhotoItem, initial: false) { oldItem, newItem in
                guard let newItem else { return }
                
                Task {
                    // Load the selected image data and convert to Image
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
}

// MARK: - Color Circle Button
// A reusable component for the color picker circles
struct ColorCircleButton: View {
    let profileColor: ProfileColor // The color this button represents
    let isSelected: Bool // Whether this color is currently selected
    let onTap: () -> Void // Action to perform when tapped
    
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
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Profile Row
// A reusable row component for profile menu items
struct ProfileRow: View {
    let icon: String             // SF Symbol name
    let label: String            // Text to display
    var color: Color = .primary  // Color for icon and text (default: primary)
    
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

// MARK: - Status Chip
// A small badge showing ON/OFF status
struct StatusChip: View {
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

// MARK: - Edit Profile View
// Separate view for editing profile details (currently unused)
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

// MARK: - About Group View
// Shows information about the user's current group
struct AboutGroupView: View {
    var body: some View {
        Text("Group Info and Members")
            .navigationTitle("About Group")
    }
}

// MARK: - Preview
#Preview {
    ProfileView(userID: "test", onLogout: {})
}
