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

                // How to use
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to use")
                        .font(.headline)
                        .padding(.bottom, 4)

                    StepRow(
                        icon: "checkmark.seal.fill",
                        color: .green,
                        title: "Plugin is active",
                        description: "MarkdownQL is installed and registered with macOS. You do not need to keep this app open."
                    )
                    StepRow(
                        icon: "folder.fill",
                        color: .blue,
                        title: "Open Finder",
                        description: "Navigate to any folder that contains .md files."
                    )
                    StepRow(
                        icon: "space",
                        color: .purple,
                        title: "Press Space",
                        description: "Select a .md file and press the Space bar to see the formatted preview."
                    )
                }
                .padding(28)
                .frame(maxWidth: 460, alignment: .leading)

                Divider()

                // After restart
                VStack(alignment: .leading, spacing: 20) {
                    Text("After a restart")
                        .font(.headline)
                        .padding(.bottom, 4)

                    StepRow(
                        icon: "arrow.clockwise.circle.fill",
                        color: .green,
                        title: "Works automatically",
                        description: "macOS registers the plugin permanently. After restarting your Mac, the preview works right away — no need to relaunch this app."
                    )
                    StepRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        title: "Preview stopped working?",
                        description: "Sometimes macOS resets its Quick Look cache. Simply open MarkdownQL once and the preview will be restored."
                    )
                    StepRow(
                        icon: "terminal.fill",
                        color: .gray,
                        title: "Still not working?",
                        description: "Open Terminal and run the following command to reset the Quick Look engine:"
                    )

                    Text("qlmanage -r")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .padding(.leading, 52)
                }
                .padding(28)
                .frame(maxWidth: 460, alignment: .leading)

                Divider()

                // Footer
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .padding(.top, 1)
                    Text("Keep MarkdownQL.app in your Applications folder. Deleting the app will also remove the preview extension.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: 460, alignment: .leading)
        }
        .frame(width: 500)
    }
}

struct StepRow: View {
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
