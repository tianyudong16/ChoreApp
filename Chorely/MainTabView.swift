import SwiftUI

struct MainTabView: View {
    let user: UserInfo
    @State private var selectedTab = 0

    // default initializer for previews
    init(user: UserInfo = UserInfo(name: "", groupName: "")) {
        self.user = user
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            // Wrap HomeView in NavigationStack
            NavigationStack {
                HomeView(name: user.name, groupName: user.groupName)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            // Wrap CalendarView in NavigationStack
            NavigationStack {
                CalendarView()
            }
            .tabItem { Label("Calendar", systemImage: "calendar") }
            .tag(1)

            // Wrap ProfileView in NavigationStack
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(2)
        }
        .tint(.green)
    }
}

#Preview {
    MainTabView()
}
