//
//  ProfileView.swift
//  Chorely
//
// Created by Tian Yu Dong and Brooke Tanner
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct ProfileView: View {
    
    @State var user: UserInfo
    
    @State private var username: String
    @State private var selectedColor: Color
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: Image? = nil
    
    @State private var showJoinAlert = false
    @State private var showLeaveAlert = false
    @State private var showAboutGroup = false
    @State private var showLogoutAlert = false
    
    // Add environment to dismiss the view hierarchy
    @Environment(\.dismiss) private var dismiss
    
    init(user: UserInfo) {
        _user = State(initialValue: user)
        _username = State(initialValue: user.name)
        _selectedColor = State(initialValue: user.color)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    
                    // MARK: - PROFILE HEADER
                    VStack(spacing: 15) {
                        
                        // Profile Picture
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                if let profileImage {
                                    profileImage
                                        .resizable()
                                        .scaledToFill()
                                } else if !user.photoURL.isEmpty {
                                    AsyncImage(url: URL(string: user.photoURL)) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                } else {
                                    Circle()
                                        .fill(selectedColor)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(radius: 5)
                        }
                        
                        Text("click to edit")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        // Name with edit icon
                        HStack {
                            TextField("User's Name", text: $username)
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)
                            Image(systemName: "pencil")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                    
                    // MARK: - MENU OPTIONS
                    VStack(spacing: 0) {
                        
                        // Edit Section with Color Picker
                        NavigationLink {
                            EditProfileView(username: $username, selectedColor: $selectedColor, onSave: {
                                saveProfileChanges()
                            })
                        } label: {
                            HStack(spacing: 15) {
                                Image(systemName: "paintpalette")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                
                                Text("Edit")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Show current color
                                Circle()
                                    .fill(selectedColor)
                                    .frame(width: 20, height: 20)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(selectedColor.opacity(0.2))
                        }
                        
                        Divider().padding(.leading, 60)
                        
                        // Join Group
                        menuItem(
                            icon: "person.2.fill",
                            title: "Join Group",
                            showDisclosure: false
                        ) {
                            showJoinAlert = true
                        }
                        
                        Divider().padding(.leading, 60)
                        
                        // About Group
                        menuItem(
                            icon: "info.circle",
                            title: "About Group",
                            showDisclosure: false
                        ) {
                            showAboutGroup = true
                        }
                        
                        Divider().padding(.leading, 60)
                        
                        // Leave Group (Red)
                        menuItem(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Leave Group",
                            showDisclosure: false,
                            titleColor: .red
                        ) {
                            showLeaveAlert = true
                        }
                        
                        Divider().padding(.leading, 60)
                        
                        // Notifications Toggle
                        HStack(spacing: 15) {
                            Image(systemName: "bell.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            Text("Notifications")
                                .font(.body)
                            
                            Spacer()
                            
                            Toggle("", isOn: .constant(true))
                                .labelsHidden()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        
                        Divider().padding(.leading, 60)
                        
                        // Log Out (Red)
                        menuItem(
                            icon: "rectangle.portrait.and.arrow.right.fill",
                            title: "LOG OUT",
                            showDisclosure: false,
                            titleColor: .red
                        ) {
                            showLogoutAlert = true
                        }
                    }
                    .background(Color(.systemBackground))
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .alert("Join Group", isPresented: $showJoinAlert) {
                TextField("Group Code", text: .constant(""))
                Button("Join", action: {})
                Button("Cancel", role: .cancel, action: {})
            } message: {
                Text("Enter the group code to join")
            }
            .alert("Leave Group", isPresented: $showLeaveAlert) {
                Button("Leave", role: .destructive, action: {})
                Button("Cancel", role: .cancel, action: {})
            } message: {
                Text("Are you sure you want to leave your group?")
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    signOut()
                }
                Button("Cancel", role: .cancel, action: {})
            } message: {
                Text("Are you sure you want to log out?")
            }
            .sheet(isPresented: $showAboutGroup) {
                aboutGroupSheet()
            }
            .onChange(of: selectedPhoto) { _, newPhoto in
                guard let newPhoto = newPhoto else { return }
                loadAndUploadPhoto(item: newPhoto)
            }
            .onChange(of: username) { _, _ in
                saveProfileChanges()
            }
            .onChange(of: selectedColor) { _, _ in
                saveProfileChanges()
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - MENU ITEM
    @ViewBuilder
    func menuItem(
        icon: String,
        title: String,
        showDisclosure: Bool,
        backgroundColor: Color = .clear,
        titleColor: Color = .primary,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(titleColor)
                
                Spacer()
                
                if showDisclosure {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(backgroundColor)
        }
    }
    
    // MARK: - ABOUT GROUP SHEET
    @ViewBuilder
    func aboutGroupSheet() -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Group Information")
                    .font(.title2.bold())
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Show group info, true members, and also their group code")
                        .foregroundColor(.gray)
                        .padding()
                }
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showAboutGroup = false
                    }
                }
            }
        }
    }
    
    // MARK: - HELPER FUNCTIONS
    
    private func saveProfileChanges() {
        user.name = username
        let newColorData = UIColor(selectedColor).toData()
        user.colorData = newColorData ?? user.colorData
        
        FirebaseInterface.shared.updateUserName(
            uid: user.uid,
            groupID: user.groupID,
            newName: username
        )
        FirebaseInterface.shared.updateUserColor(
            uid: user.uid,
            groupID: user.groupID,
            color: selectedColor
        )
    }
    
    private func loadAndUploadPhoto(item: PhotosPickerItem) {
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                return
            }
            
            self.profileImage = Image(uiImage: uiImage)
            
            FirebaseInterface.shared.uploadUserPhoto(
                uid: user.uid,
                groupID: user.groupID,
                image: uiImage
            ) { result in
                if case .success(let url) = result {
                    user.photoURL = url
                }
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            // Exit the entire app navigation to return to login
            exit(0)
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

// MARK: - EDIT PROFILE VIEW
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var username: String
    @Binding var selectedColor: Color
    var onSave: () -> Void
    
    var body: some View {
        Form {
            Section("Name") {
                TextField("Your Name", text: $username)
                    .textInputAutocapitalization(.words)
            }
            
            Section("Color") {
                ColorPicker("Select your color", selection: $selectedColor, supportsOpacity: false)
                
                HStack {
                    Text("Preview")
                    Spacer()
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave()
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ProfileView(
        user: UserInfo(
            uid: "123",
            name: "Preview User",
            email: "test@email.com",
            groupID: "group1",
            photoURL: "",
            colorData: UIColor.systemPink.toData() ?? Data()
        )
    )
}
