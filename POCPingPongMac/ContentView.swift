import SwiftUI

struct ContentView: View {
    
    // Cria uma instância do nosso gerenciador de conectividade
    @StateObject private var connectivityManager = ConnectivityManager()
    
    var body: some View {
        VStack {
            Text("Ping Pong Tela (POC)")
                .font(.largeTitle)
                .padding()
            
            Spacer()
            
            Rectangle()
                .fill(Color.blue)
                .frame(width: 100, height: 100)
                .offset(x: connectivityManager.paddlePositionX, y: connectivityManager.paddlePositionY)
                .animation(.linear(duration: 0.1), value: connectivityManager.paddlePositionX)
                .animation(.linear(duration: 0.1), value: connectivityManager.paddlePositionY)
            
            Spacer()
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
