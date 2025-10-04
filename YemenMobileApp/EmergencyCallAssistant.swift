//
//  EmergencyCallAssistant.swift
//  Yemen Mobile Network Assistant
//

import Foundation
import CoreTelephony
import CallKit
import UserNotifications

class EmergencyCallAssistant: ObservableObject {
    @Published var isMonitoring: Bool = false
    @Published var emergencySequenceActive: Bool = false
    @Published var lastEmergencyCallTime: Date?
    @Published var networkRegistrationDetected: Bool = false
    
    private let callObserver = CXCallObserver()
    private let telephonyInfo = CTTelephonyNetworkInfo()
    private var registrationTimer: Timer?
    private var monitoringTimer: Timer?
    
    init() {
        setupCallObserver()
    }
    
    private func setupCallObserver() {
        callObserver.setDelegate(self, queue: nil)
    }
    
    // MARK: - Emergency Sequence Management
    
    func startEmergencySequence() {
        emergencySequenceActive = true
        
        // Create a guided emergency call sequence
        let content = UNMutableNotificationContent()
        content.title = "Emergency Call Sequence Started"
        content.body = "Follow the guided steps to establish Yemen Mobile connection"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "emergencySequenceStart", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        
        // Auto-start monitoring
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.monitorNetworkRegistration()
        }
    }
    
    func monitorNetworkRegistration() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        startContinuousMonitoring()
        
        let content = UNMutableNotificationContent()
        content.title = "Network Monitoring Active"
        content.body = "Monitoring for Yemen Mobile network registration..."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "monitoringStart", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func startContinuousMonitoring() {
        // Monitor every 2 seconds for network changes
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForNetworkRegistration()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        emergencySequenceActive = false
        monitoringTimer?.invalidate()
        registrationTimer?.invalidate()
    }
    
    private func checkForNetworkRegistration() {
        // Check if Yemen Mobile is now visible
        guard let carriers = telephonyInfo.serviceSubscriberCellularProviders else { return }
        
        for (_, carrier) in carriers {
            let carrierName = carrier.carrierName ?? ""
            let mcc = carrier.mobileCountryCode ?? ""
            let mnc = carrier.mobileNetworkCode ?? ""
            
            // Check for Yemen Mobile indicators
            let isYemenMobile = (mcc == "421" && mnc == "03") ||
                               carrierName.lowercased().contains("yemen") ||
                               carrierName.lowercased().contains("ymobile")
            
            if isYemenMobile && !networkRegistrationDetected {
                networkRegistrationDetected = true
                handleYemenMobileDetection(carrierName: carrierName)
            }
        }
        
        // Also check for CDMA registration
        checkForCDMARegistration()
    }
    
    private func checkForCDMARegistration() {
        guard let radioTechs = telephonyInfo.serviceCurrentRadioAccessTechnology else { return }
        
        for (_, tech) in radioTechs {
            if let technology = tech {
                // Check for CDMA technologies that Yemen Mobile uses
                if technology.contains("CDMA") || technology.contains("EVDO") {
                    handleCDMADetection(technology: technology)
                }
            }
        }
    }
    
    private func handleYemenMobileDetection(carrierName: String) {
        DispatchQueue.main.async {
            self.sendNetworkDetectedNotification(carrierName: carrierName)
            self.scheduleQuickConfiguration()
        }
    }
    
    private func handleCDMADetection(technology: String) {
        // CDMA detected - might be Yemen Mobile
        if !networkRegistrationDetected {
            DispatchQueue.main.async {
                self.sendCDMADetectedNotification(technology: technology)
            }
        }
    }
    
    private func sendNetworkDetectedNotification(carrierName: String) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Yemen Mobile Detected!"
        content.body = "\(carrierName) is now available. Configure settings immediately!"
        content.sound = .default
        content.categoryIdentifier = "YEMEN_MOBILE_DETECTED"
        
        // Add action buttons
        let configureAction = UNNotificationAction(identifier: "CONFIGURE", title: "Configure Now", options: [.foreground])
        let ignoreAction = UNNotificationAction(identifier: "IGNORE", title: "Ignore", options: [])
        
        let category = UNNotificationCategory(identifier: "YEMEN_MOBILE_DETECTED", actions: [configureAction, ignoreAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        let request = UNNotificationRequest(identifier: "yemenMobileFound", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendCDMADetectedNotification(technology: String) {
        let content = UNMutableNotificationContent()
        content.title = "📡 CDMA Network Detected"
        content.body = "\(technology) detected. This might be Yemen Mobile. Check network settings."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "cdmaDetected", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleQuickConfiguration() {
        // Give user 30 seconds to configure before network might drop
        registrationTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.sendConfigurationReminderNotification()
        }
    }
    
    private func sendConfigurationReminderNotification() {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Configuration Reminder"
        content.body = "Yemen Mobile connection may drop soon. Make sure to set manual network selection!"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "configReminder", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Emergency Call Detection
    
    private func handleEmergencyCallStarted() {
        lastEmergencyCallTime = Date()
        
        let content = UNMutableNotificationContent()
        content.title = "Emergency Call Detected"
        content.body = "Monitoring for network registration..."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "emergencyCallStart", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        
        // Start intensive monitoring during emergency call
        if !isMonitoring {
            monitorNetworkRegistration()
        }
    }
    
    private func handleEmergencyCallEnded() {
        let content = UNMutableNotificationContent()
        content.title = "Emergency Call Ended"
        content.body = "Checking for network registration changes..."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "emergencyCallEnd", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        
        // Check for network changes after emergency call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkForNetworkRegistration()
        }
        
        // Continue monitoring for a few more minutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 300.0) { // 5 minutes
            if self.isMonitoring && !self.networkRegistrationDetected {
                self.stopMonitoring()
            }
        }
    }
    
    // MARK: - Network Configuration Helpers
    
    func generateCarrierConfiguration() -> String {
        return """
        Yemen Mobile Configuration Settings:
        
        === CARRIER INFORMATION ===
        Carrier Name: Yemen Mobile
        MCC: 421 (Yemen)
        MNC: 03 (Yemen Mobile)
        
        === DATA SETTINGS ===
        APN: ymobile
        Username: ymobile
        Password: ymobile
        Authentication: PAP
        APN Type: default,supl
        
        === NETWORK SETTINGS ===
        Network Type: CDMA/EVDO
        Frequencies: BC0 (800 MHz), BC21 (2000 MHz)
        Preferred: CDMA/EVDO
        
        === MANUAL CONFIGURATION STEPS ===
        1. Settings > Cellular > Cellular Data Network
        2. Enter APN settings above
        3. Settings > Cellular > Network Selection
        4. Turn OFF Automatic
        5. Select Yemen Mobile from list
        
        Generated: \(Date())
        """
    }
    
    func exportEmergencyLogs() -> String {
        let logs = """
        Yemen Mobile Emergency Call Assistant Logs
        Generated: \(Date())
        
        === EMERGENCY CALL HISTORY ===
        Last Emergency Call: \(lastEmergencyCallTime?.description ?? "None")
        Emergency Sequence Active: \(emergencySequenceActive ? "YES" : "NO")
        
        === MONITORING STATUS ===
        Currently Monitoring: \(isMonitoring ? "YES" : "NO")
        Network Registration Detected: \(networkRegistrationDetected ? "YES" : "NO")
        
        === CONFIGURATION ===
        \(generateCarrierConfiguration())
        """
        
        return logs
    }
}

// MARK: - CXCallObserverDelegate

extension EmergencyCallAssistant: CXCallObserverDelegate {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        DispatchQueue.main.async {
            if call.hasConnected && !call.hasEnded {
                // Call started
                if call.isOutgoing {
                    // Check if this might be an emergency call
                    // Note: We can't directly detect emergency numbers due to privacy
                    self.handleEmergencyCallStarted()
                }
            } else if call.hasEnded {
                // Call ended
                if call.isOutgoing {
                    self.handleEmergencyCallEnded()
                }
            }
        }
    }
}