//
//  ConnectivityManager.swift
//  POCPingPong
//
//  Created by Andrei Rech on 04/11/25.
//


import Foundation
import MultipeerConnectivity
import Combine

// Este objeto será observável pelo SwiftUI para atualizar a UI
class ConnectivityManager: NSObject, ObservableObject {
    
    // @Published notificará a UI (ContentView) sempre que este valor mudar
    @Published var paddlePositionX: CGFloat = 0.0 // Era 'paddlePosition'
        @Published var paddlePositionY: CGFloat = 0.0 // A nova posição Y
    
    private let serviceType = "pingpong" // Identificador único do seu jogo
    private var myPeerID: MCPeerID
    private var serviceAdvertiser: MCNearbyServiceAdvertiser
    private var session: MCSession
    
    override init() {
        // Usa o nome do dispositivo Mac como identificador
        self.myPeerID = MCPeerID(displayName: Host.current().name ?? "MacHost")
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        
        super.init()
        
        self.session.delegate = self
        self.serviceAdvertiser.delegate = self
        
        // Inicia o "anúncio" do jogo na rede
        self.serviceAdvertiser.startAdvertisingPeer()
        print("Iniciando anúncio do jogo...")
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
    }
}

// MARK: - MCSessionDelegate
extension ConnectivityManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // Monitora o status da conexão
        switch state {
        case .connected:
            print("Conectado: \(peerID.displayName)")
        case .connecting:
            print("Conectando: \(peerID.displayName)")
        case .notConnected:
            print("Não conectado: \(peerID.displayName)")
        @unknown default:
            fatalError("Estado desconhecido")
        }
    }
    
    // AQUI A MÁGICA ACONTECE (Recebimento de Dados)
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
            
            // 2. Tente decodificar como um Dicionário [String: Double]
            if let motionData = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: Double] {
                
                // 3. Extraia os valores 'roll' e 'pitch' do dicionário
                guard let roll = motionData["roll"],
                      let pitch = motionData["pitch"] else {
                    print("Dados de movimento recebidos em formato inesperado")
                    return
                }
                
                // 4. Atualize a UI na thread principal com AMBOS os valores
                DispatchQueue.main.async {
                    // O 'roll' controla o eixo X
                    self.paddlePositionX = CGFloat(roll) * 300.0
                    
                    // O 'pitch' controlará o eixo Y
                    // Nota: O pitch (frente/trás) pode parecer "invertido"
                    // Talvez você queira usar um multiplicador negativo (ex: * -300.0)
                    // ou um multiplicador diferente, dependendo da sensibilidade desejada.
                    self.paddlePositionY = CGFloat(pitch) * 300.0 * -1
                }
            }
        }
    
    // Funções de delegate obrigatórias, mas não usadas nesta POC
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension ConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    
    // Gerencia convites de conexão
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Aceita automaticamente qualquer convite (apenas para esta POC)
        print("Recebendo convite de \(peerID.displayName)")
        invitationHandler(true, self.session)
    }
    
    // No final da extensão MCNearbyServiceAdvertiserDelegate
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("!!!!!!!!!!!! ERRO NO MAC !!!!!!!!!!!!")
        print("Não foi possível anunciar o serviço: \(error.localizedDescription)")
    }
}
