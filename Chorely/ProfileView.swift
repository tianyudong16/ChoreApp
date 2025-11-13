import SwiftUI
import PhotosUI // Needed for the photo picker

struct ProfileView: View {
    var user: UserInfo
    @State private var profileColor: Color = .pink
    @State private var notificationsOn = true

    // Editable name & photo states
    @State private var username: String
    @State private var isEditingName = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: Image? = nil

    // Initialize the username from the logged-in user
    init(user: UserInfo) {
        self.user = user
        _username = State(initialValue: user.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {

            // Profile header
            HStack(alignment: .center, spacing: 15) {
                
                // Tappable profile icon with "Edit Photo" overlay
                VStack(spacing: 4) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            // Display selected or placeholder image
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(profileColor.opacity(0.3))
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 45, height: 45)
                                            .foregroundColor(.gray)
                                    )
                            }

                            // Camera icon overlay
                            Circle()
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(.gray)
                                )
                                .offset(x: 6, y: 6)
                        }
                    }
                    // Handle photo picker
                    .onChange(of: selectedPhoto) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                profileImage = Image(uiImage: uiImage)
                            }
                        }
                    }

                    // "Edit Photo" label underneath
                    Text("Edit Photo")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Editable name field with pencil icon
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if isEditingName {
                            TextField("Enter name", text: $username)
                                .font(.title2.bold())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 180)
                        } else {
                            Text(username)
                                .font(.title2.bold())
                        }

                        Button(action: {
                            isEditingName.toggle()
                        }) {
                            Image(systemName: isEditingName ? "checkmark.circle.fill" : "pencil.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                // Color picker on right
                ColorPicker("", selection: $profileColor, supportsOpacity: false)
                    .labelsHidden()
            }
            .padding(.top)

            Divider()

            // Profile menu
            VStack(spacing: 16) {
                ProfileOptionRow(label: "Join Group", color: .blue, icon: "person.2.fill")
                ProfileOptionRow(label: "About \(user.groupName)", color: .green, icon: "info.circle.fill")

                Button(role: .destructive) {
                    // TODO: add leave group logic
                } label: {
                    Text("Leave Group")
                        .font(.headline)
                        .foregroundColor(.red)
                }

                Divider()

                HStack {
                    Text("Notifications")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: $notificationsOn)
                        .labelsHidden()
                }
                .padding(.horizontal)

                Button(role: .destructive) {
                    // handles logout
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

// Row components
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

// Preview view
#Preview {
    NavigationStack {
        ProfileView(user: UserInfo(name: "Preview User", groupName: "Preview Group"))
    }
}
