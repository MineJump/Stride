import SwiftUI

struct ProfileFormView: View {
    @EnvironmentObject var vm: ShoesViewModel

    var body: some View {
        Form {
            Section("Health") {
                Button {
                    Task { await vm.requestHealthAccess() }
                } label: {
                    HStack {
                        Image(systemName: vm.isAuthorized ? "checkmark.shield" : "shield")
                            .foregroundStyle(vm.isAuthorized ? .green : .primary)
                        Text(vm.isAuthorized ? "Health Connected" : "Connect Health")
                    }
                }
            }

            Section("About") {
                LabeledContent("App") { Text("Stride").foregroundStyle(.secondary) }
                LabeledContent("Developer") {
                    Link(destination: URL(string: "https://www.jaritz.com/wp/hendrik-jaritz/")!) {
                        Text("Hendrik Jaritz")
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
