import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ProfileView()
                .tabItem { Label("Profile", systemImage: "figure.golf") }
            SwingListView()
                .tabItem { Label("Swings", systemImage: "video") }
        }
    }
}
