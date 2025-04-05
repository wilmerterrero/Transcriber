import SwiftUI

struct NavigationBar: View {
    @State private var searchText = ""
    @State private var selectedSegment = 0
    @State private var showSearchBar = false
    @State private var showSettings = false

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(" yvo")
                    .font(.logoText(size: 30))
                    .foregroundColor(.red)

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        withAnimation {
                            showSearchBar.toggle()
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(textColor)
                            .font(.system(size: 18))
                            .opacity(showSearchBar ? 0.2 : 1)
                    }

                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(textColor)
                            .font(.system(size: 18))
                            .opacity(showSettings ? 0.2 : 1)
                    }
                }
            }
            .padding(.horizontal)

            // Custom divider using Rectangle
            Rectangle()
                .frame(height: 1)  // Thin line
                .foregroundColor(.secondary)

            if showSearchBar {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search", text: $searchText)
                        .font(.golosText(size: 16))

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showSearchBar)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            NavigationBar()
            Text("recurring")
                .font(.largeTitle)
                .foregroundColor(.white)
            Spacer()
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
