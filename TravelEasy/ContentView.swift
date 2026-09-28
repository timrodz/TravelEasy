import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            Text("Sidebar")
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            Text("Select a country")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ContentView()
}
