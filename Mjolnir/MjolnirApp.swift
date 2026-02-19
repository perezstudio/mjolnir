import SwiftUI
import SwiftData

@main
struct MjolnirApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Project.self,
            Chat.self,
            Message.self,
            ToolCall.self,
            UserSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
        }
        .modelContainer(sharedModelContainer)

        Settings {
            Text("Settings")
                .frame(width: 400, height: 300)
        }
    }
}
