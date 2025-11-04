import SwiftUI

struct ContentView: View {
    
    // Cria uma instância do nosso gerenciador
    @StateObject private var motionNetworkManager = MotionNetworkManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Raquete Ping Pong (POC)")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
            
            Image(systemName: "iphone.gen2.landscape")
                .font(.system(size: 100))
            
            Text("Incline o celular para os lados")
                .font(.title2)
            
            Text(motionNetworkManager.connectionState)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
        }
        .padding()
    }
}
