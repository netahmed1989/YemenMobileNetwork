//
//  NetworkManager.swift
//  Yemen Mobile Network Assistant
//

import Foundation
import CoreTelephony
import Network
import CallKit

class NetworkManager: ObservableObject {
    @Published var carrierName: String = "Unknown"
    @Published var networkType: String = "Unknown"
    @Published var signalStrength: String = "Unknown"
    @Published var connectionStatus: String = "Disconnected"
    @Published var isConnected: Bool = false
    @Published var isYemenMobileDetected: Bool = false
    
    private let telephonyInfo = CTTelephonyNetworkInfo()
    private let callObserver = CXCallObserver()
    private var networkMonitor: NWPathMonitor?
    private let dispatchQueue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        setupTelephonyMonitoring()
        setupCallMonitoring()
    }
    
    func startMonitoring() {
        updateNetworkInfo()
        startNetworkPathMonitoring()
    }
    
    private func setupTelephonyMonitoring() {
        // Monitor carrier changes
        telephonyInfo.serviceSubscriberCellularProvidersDidUpdateNotifier = { [weak self] carrierInfo in
            DispatchQueue.main.async {
                self?.updateCarrierInfo(carrierInfo)
            }
        }
        
        // Monitor service changes
        telephonyInfo.serviceCurrentRadioAccessTechnologyDidUpdateNotifier = { [weak self] serviceId, radioTech in
            DispatchQueue.main.async {
                self?.updateRadioTechnology(serviceId: serviceId, radioTech: radioTech)
            }
        }
    }
    
    private func setupCallMonitoring() {
        callObserver.setDelegate(self, queue: nil)
    }
    
    private func startNetworkPathMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path: path)
            }
        }
        networkMonitor?.start(queue: dispatchQueue)
    }
    
    private func updateNetworkInfo() {
        // Update carrier information
        if let carriers = telephonyInfo.serviceSubscriberCellularProviders {
            for (_, carrier) in carriers {
                updateCarrierDetails(carrier)
            }
        }
        
        // Update radio access technology
        if let radioTechs = telephonyInfo.serviceCurrentRadioAccessTechnology {
            for (serviceId, radioTech) in radioTechs {
                updateRadioTechnology(serviceId: serviceId, radioTech: radioTech)
            }
        }
    }
    
    private func updateCarrierInfo(_ carrierInfo: [String: CTCarrier]?) {
        guard let carriers = carrierInfo else { return }
        
        for (_, carrier) in carriers {
            updateCarrierDetails(carrier)
        }
    }
    
    private func updateCarrierDetails(_ carrier: CTCarrier) {
        let name = carrier.carrierName ?? "Unknown"
        let mcc = carrier.mobileCountryCode ?? "Unknown"
        let mnc = carrier.mobileNetworkCode ?? "Unknown"
        
        DispatchQueue.main.async {
            self.carrierName = name
            
            // Check if this is Yemen Mobile
            self.isYemenMobileDetected = (mcc == "421" && mnc == "03") || 
                                        name.lowercased().contains("yemen") ||
                                        name.lowercased().contains("ymobile")
            
            if self.isYemenMobileDetected {
                self.carrierName = "Yemen Mobile"
                self.sendYemenMobileDetectedNotification()
            }
        }
    }
    
    private func updateRadioTechnology(serviceId: String, radioTech: String?) {
        guard let tech = radioTech else { return }
        
        var displayTech = "Unknown"
        switch tech {
        case CTRadioAccessTechnologyGPRS:
            displayTech = "GPRS (2G)"
        case CTRadioAccessTechnologyEdge:
            displayTech = "EDGE (2G)"
        case CTRadioAccessTechnologyWCDMA:
            displayTech = "WCDMA (3G)"
        case CTRadioAccessTechnologyCDMA1x:
            displayTech = "CDMA 1x"
        case CTRadioAccessTechnologyCDMAEVDORev0:
            displayTech = "CDMA EVDO Rev0"
        case CTRadioAccessTechnologyCDMAEVDORevA:
            displayTech = "CDMA EVDO RevA"
        case CTRadioAccessTechnologyCDMAEVDORevB:
            displayTech = "CDMA EVDO RevB"
        case CTRadioAccessTechnologyeHRPD:
            displayTech = "eHRPD"
        case CTRadioAccessTechnologyLTE:
            displayTech = "LTE (4G)"
        default:
            displayTech = "Other (\(tech))"
        }
        
        DispatchQueue.main.async {
            self.networkType = displayTech
            
            // Yemen Mobile typically uses CDMA technologies
            if displayTech.contains("CDMA") || displayTech.contains("EVDO") {
                self.detectYemenMobileCDMA()
            }
        }
    }
    
    private func updateConnectionStatus(path: NWPath) {
        isConnected = path.status == .satisfied
        
        if path.status == .satisfied {
            if path.usesInterfaceType(.cellular) {
                connectionStatus = "Connected (Cellular)"
            } else if path.usesInterfaceType(.wifi) {
                connectionStatus = "Connected (WiFi)"
            } else {
                connectionStatus = "Connected"
            }
        } else {
            connectionStatus = "Disconnected"
        }
    }
    
    private func detectYemenMobileCDMA() {
        // Additional detection logic for Yemen Mobile CDMA
        if networkType.contains("CDMA") && !isYemenMobileDetected {
            // This might be Yemen Mobile on CDMA
            carrierName = "Yemen Mobile (CDMA)"
            isYemenMobileDetected = true
            sendYemenMobileDetectedNotification()
        }
    }
    
    private func sendYemenMobileDetectedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Yemen Mobile Detected!"
        content.body = "Yemen Mobile network has been detected. You can now configure your settings."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "yemenMobileDetected", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Public Methods
    
    func applyYemenMobileSettings() {
        // Open Settings app to cellular configuration
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func forceNetworkSelection() {
        // Open Settings app to network selection
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func exportLogs() {
        let logs = generateNetworkLogs()
        print("Network Logs:")
        print(logs)
    }
    
    func resetNetworkSettings() {
        // Guide user to reset network settings
        print("Guide user to reset network settings in iOS Settings")
    }
    
    func generateNetworkLogs() -> String {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        
        return """
        Yemen Mobile Network Logs
        Generated: \(timestamp)
        
        === CURRENT STATUS ===
        Carrier: \(carrierName)
        Network Type: \(networkType)
        Signal Strength: \(signalStrength)
        Connection: \(connectionStatus)
        Yemen Mobile Detected: \(isYemenMobileDetected ? "YES" : "NO")
        
        === CARRIER DETAILS ===
        \(getCarrierDetails())
        
        === RADIO ACCESS TECHNOLOGY ===
        \(getRadioTechnologyDetails())
        """
    }
    
    private func getCarrierDetails() -> String {
        guard let carriers = telephonyInfo.serviceSubscriberCellularProviders else {
            return "No carrier information available"
        }
        
        var details = ""
        for (serviceId, carrier) in carriers {
            details += """
            Service ID: \(serviceId)
            Carrier Name: \(carrier.carrierName ?? "Unknown")
            MCC: \(carrier.mobileCountryCode ?? "Unknown")
            MNC: \(carrier.mobileNetworkCode ?? "Unknown")
            ISO Country Code: \(carrier.isoCountryCode ?? "Unknown")
            Allows VoIP: \(carrier.allowsVOIP ? "YES" : "NO")
            
            """
        }
        
        return details
    }
    
    private func getRadioTechnologyDetails() -> String {
        guard let radioTechs = telephonyInfo.serviceCurrentRadioAccessTechnology else {
            return "No radio technology information available"
        }
        
        var details = ""
        for (serviceId, tech) in radioTechs {
            details += "Service ID: \(serviceId), Technology: \(tech ?? "Unknown")\n"
        }
        
        return details
    }
}

// MARK: - CXCallObserverDelegate

extension NetworkManager: CXCallObserverDelegate {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.isOutgoing && call.hasEnded {
            // Emergency call ended, check for network changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.updateNetworkInfo()
            }
        }
    }
}