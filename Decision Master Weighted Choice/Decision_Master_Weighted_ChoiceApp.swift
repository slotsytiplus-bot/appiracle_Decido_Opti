import SwiftUI
import SwiftData

@main
struct Decision_Master_Weighted_ChoiceApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .preferredColorScheme(themeManager.effectiveColorScheme)
                .environmentObject(themeManager)
        }
        .modelContainer(for: [Decision.self, Option.self, Criteria.self, Score.self])
    }
}
