import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 52))
                    .foregroundStyle(.tint)
                Text("MarkdownQL")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Quick Look Preview for Markdown files")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)

            Divider()

            // Steps
            VStack(alignment: .leading, spacing: 20) {
                Text("How to use")
                    .font(.headline)
                    .padding(.bottom, 4)

                StepRow(
                    number: "1",
                    icon: "checkmark.seal.fill",
                    color: .green,
                    title: "Plugin is active",
                    description: "MarkdownQL is installed and running in the background."
                )
                StepRow(
                    number: "2",
                    icon: "folder.fill",
                    color: .blue,
                    title: "Open Finder",
                    description: "Navigate to any folder that contains .md files."
                )
                StepRow(
                    number: "3",
                    icon: "space",
                    color: .purple,
                    title: "Press Space",
                    description: "Select a .md file and press the Space bar to see the formatted preview."
                )
            }
            .padding(28)
            .frame(maxWidth: 460)

            Divider()

            // Footer
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("This app must stay installed for the preview to work. You can keep it in the Dock or just leave it in Applications.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: 460)
        }
        .frame(width: 500)
    }
}

struct StepRow: View {
    let number: String
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ContentView()
}
