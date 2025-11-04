//
//  MotionNetworkManager.swift
//  POCPingPong
//
//  Created by Andrei Rech on 04/11/25.
//


import Foundation
import CoreMotion
import MultipeerConnectivity
import Combine

class MotionNetworkManager: NSObject, ObservableObject {
    
    // Gerenciador do CoreMotion
    private let motionManager = CMMotionManager()
    
    // Gerenciador do Multipeer
    private let serviceType = "pingpong" // DEVE ser o mesmo serviceType do Mac
    private var myPeerID: MCPeerID
    private var session: MCSession
    private var serviceBrowser: MCNearbyServiceBrowser
    
    @Published var connectionState: String = "Desconectado"
    
    override init() {
        let peerName = UIDevice.current.name.isEmpty ? "iPhoneJogador1" : UIDevice.current.name
        self.myPeerID = MCPeerID(displayName: peerName)
        self.session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        
        super.init()
        
        self.session.delegate = self
        self.serviceBrowser.delegate = self
        
        // Inicia a "procura" pelo Mac
        self.serviceBrowser.startBrowsingForPeers()
        print("Iniciando procura por host...")
    }
    
    deinit {
        self.serviceBrowser.stopBrowsingForPeers()
        self.stopMotionUpdates()
    }
    
    // Inicia o envio de dados de movimento
    // Dentro de MotionNetworkManager.swift

    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion não está disponível")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 updates por segundo
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else { return }
            
            guard !self.session.connectedPeers.isEmpty else { return }
            
            // 1. Capture OS DOIS valores
            let roll = motion.attitude.roll   // Para o eixo X
            let pitch = motion.attitude.pitch // Para o eixo Y
            
            // 2. Crie um dicionário com ambos os valores
            let motionData: [String: Double] = [
                "roll": roll,
                "pitch": pitch
            ]
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: motionData, requiringSecureCoding: false)
                
                try self.session.send(data, toPeers: self.session.connectedPeers, with: .unreliable)
            } catch {
                print("Erro ao enviar dados de movimento: \(error.localizedDescription)")
            }
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MotionNetworkManager: MCNearbyServiceBrowserDelegate {
    
    // Encontrou um "host" (o Mac)
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Host encontrado: \(peerID.displayName). Convidando...")
        // Convida automaticamente o host encontrado
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    // Um host "desapareceu" da rede
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Host perdido: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("!!!!!!!!!!!! ERRO NO IPHONE !!!!!!!!!!!!")
        print("Não foi possível iniciar a procura: \(error.localizedDescription)")
    }
}

// MARK: - MCSessionDelegate
extension MotionNetworkManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // Atualiza o status da conexão na UI
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectionState = "Conectado a \(peerID.displayName)"
                // CONECTOU! Inicia o envio de dados de movimento
                self.startMotionUpdates()
            case .connecting:
                self.connectionState = "Conectando a \(peerID.displayName)..."
            case .notConnected:
                self.connectionState = "Desconectado"
                // PAROU. Interrompe o envio de dados
                self.stopMotionUpdates()
            @unknown default:
                self.connectionState = "Estado desconhecido"
            }
        }
    }
    
    // Funções de delegate obrigatórias, mas não usadas nesta POC
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
