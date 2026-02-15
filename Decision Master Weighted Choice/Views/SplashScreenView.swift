import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    @State private var targetUrlString: String?
    @State private var configState: ConfigRetrievalState = .pending
    @State private var currentViewState: ApplicationViewState = .initialScreen
    
    var body: some View {
        
        ZStack {
            switch currentViewState {
            case .initialScreen:
                SplashScreen()
                   
                
            case .primaryInterface:
                DashboardView()
                    .environmentObject(themeManager)
                    
                
            case .browserContent(let urlString):
                if let validUrl = URL(string: urlString) {
                    BrowserContentView(targetUrl: validUrl.absoluteString)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        .ignoresSafeArea(.all, edges: .bottom)
                } else {
                    Text("Invalid URL")
                }
                
            case .failureMessage(let errorMessage):
                VStack(spacing: 20) {
                    Text("Error")
                        .font(.title)
                        .foregroundColor(.red)
                    Text(errorMessage)
                    Button("Retry") {
                        Task { await fetchConfigurationAndNavigate() }
                    }
                }
                .padding()
            }
        }
        .task {
            await fetchConfigurationAndNavigate()
        }
        .onChange(of: configState, initial: true) { oldValue, newValue in
            if case .completed = newValue, let url = targetUrlString, !url.isEmpty {
                Task {
                    await verifyUrlAndNavigate(targetUrl: url)
                }
            }
        }
        
        
//        if isActive {
//            DashboardView()
//                .environmentObject(themeManager)
//        } else {
//            ZStack {
//                Color(.systemBackground)
//                    .ignoresSafeArea()
//                
//                VStack(spacing: 20) {
//                    Image(systemName: "chart.bar.doc.horizontal.fill")
//                        .font(.system(size: 80))
//                        .foregroundColor(.blue)
//                        .scaleEffect(size)
//                        .opacity(opacity)
//                    
//                    Text("Decision Master")
//                        .font(.system(size: 32, weight: .bold))
//                        .foregroundColor(.primary)
//                        .opacity(opacity)
//                    
//                    Text("Weighted Choice")
//                        .font(.system(size: 18, weight: .medium))
//                        .foregroundColor(.secondary)
//                        .opacity(opacity)
//                }
//            }
//            .onAppear {
//                withAnimation(.easeIn(duration: 1.2)) {
//                    self.size = 0.9
//                    self.opacity = 1.0
//                }
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                    withAnimation(.easeOut(duration: 0.5)) {
//                        self.isActive = true
//                    }
//                }
//            }
//        }
    }
    
    
    private func fetchConfigurationAndNavigate() async {
        await MainActor.run { currentViewState = .initialScreen }
        
        let (url, state) = await DynamicConfigService.instance.retrieveTargetUrl()
        print("URL: \(url)")
        print("State: \(state)")
        
        await MainActor.run {
            self.targetUrlString = url
            self.configState = state
        }
        
        if url == nil || url?.isEmpty == true {
            navigateToPrimaryInterface()
        }
    }
    
    private func navigateToPrimaryInterface() {
        withAnimation {
            currentViewState = .primaryInterface
        }
    }
    
    private func verifyUrlAndNavigate(targetUrl: String) async {
        guard let url = URL(string: targetUrl) else {
            navigateToPrimaryInterface()
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "HEAD"
        urlRequest.timeoutInterval = 10
        
        do {
            let (_, httpResponse) = try await URLSession.shared.data(for: urlRequest)
            
            if let response = httpResponse as? HTTPURLResponse,
               (200...299).contains(response.statusCode) {
                await MainActor.run {
                    currentViewState = .browserContent(targetUrl)
                }
            } else {
                navigateToPrimaryInterface()
            }
        } catch {
            navigateToPrimaryInterface()
        }
    }
}
