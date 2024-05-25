import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("iOS application in SwiftUI!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
