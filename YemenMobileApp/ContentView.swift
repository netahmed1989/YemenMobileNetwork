//
//  ContentView.swift
//  Yemen Mobile Network Assistant
//  Created for iOS 18.0+ - iPhone XS and later
//

import SwiftUI
import CoreTelephony
import CallKit
import UserNotifications

struct ContentView: View {
    @StateObject private var networkManager = NetworkManager()
    @StateObject private var emergencyAssistant = EmergencyCallAssistant()
    @State private var showingNetworkDetails = false
    @State private var showingEmergencyGuide = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Current Network Status
                    currentNetworkSection
                    
                    // Emergency Call Assistant
                    emergencyAssistantSection
                    
                    // Network Configuration
                    networkConfigSection
                    
                    // Tools Section
                    toolsSection
                }
                .padding()
            }
            .navigationTitle("Yemen Mobile Pro")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                networkManager.startMonitoring()
                setupNotifications()
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
                Button("Open Settings") {
                    openSettings()
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingNetworkDetails) {
                NetworkDetailsView(networkManager: networkManager)
            }
            .sheet(isPresented: $showingEmergencyGuide) {
                EmergencyGuideView()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("CDMA Network Assistant")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Yemen Mobile Connection Tool")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemGray6))
        )
    }
    
    private var currentNetworkSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "cellularbars")
                    .foregroundColor(networkManager.isConnected ? .green : .red)
                Text("Network Status")
                    .font(.headline)
                Spacer()
                Button("Details") {
                    showingNetworkDetails = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                NetworkStatusRow(title: "Carrier", value: networkManager.carrierName)
                NetworkStatusRow(title: "Network Type", value: networkManager.networkType)
                NetworkStatusRow(title: "Signal Strength", value: networkManager.signalStrength)
                NetworkStatusRow(title: "Connection", value: networkManager.connectionStatus)
            }
            
            if networkManager.isYemenMobileDetected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Yemen Mobile Detected")
                        .fontWeight(.medium)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Yemen Mobile Not Detected")
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
    
    private var emergencyAssistantSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "phone.badge.plus")
                    .foregroundColor(.red)
                Text("Emergency Call Assistant")
                    .font(.headline)
                Spacer()
                Button("Guide") {
                    showingEmergencyGuide = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            Text("This tool helps you use emergency calls to establish Yemen Mobile connection")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                Button(action: {
                    emergencyAssistant.startEmergencySequence()
                    showAlert(title: "Emergency Sequence Started", 
                             message: "Follow the guided steps to establish Yemen Mobile connection. Only use emergency numbers for real emergencies!")
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Start Emergency Sequence")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    emergencyAssistant.monitorNetworkRegistration()
                    showAlert(title: "Monitoring Started", 
                             message: "App is now monitoring for Yemen Mobile network registration. Make an emergency call to trigger detection.")
                }) {
                    HStack {
                        Image(systemName: "eye")
                        Text("Monitor Network Registration")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            if emergencyAssistant.isMonitoring {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Monitoring network changes...")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
    
    private var networkConfigSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.purple)
                Text("Network Configuration")
                    .font(.headline)
            }
            
            VStack(spacing: 10) {
                Button(action: {
                    networkManager.applyYemenMobileSettings()
                    showAlert(title: "Opening Settings", 
                             message: "Please configure:\n1. Go to Settings > Cellular\n2. Tap 'Cellular Data Network'\n3. Set APN to: ymobile\n4. Set Username to: ymobile\n5. Set Password to: ymobile")
                }) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver")
                        Text("Apply Yemen Mobile Settings")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    networkManager.forceNetworkSelection()
                    showAlert(title: "Manual Network Selection", 
                             message: "To manually select Yemen Mobile:\n1. Settings > Cellular\n2. Network Selection\n3. Turn OFF 'Automatic'\n4. Select 'Yemen Mobile'")
                }) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("Force Network Selection")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
    
    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(.orange)
                Text("Advanced Tools")
                    .font(.headline)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ToolButton(icon: "doc.text", title: "Export Logs", color: .blue) {
                    networkManager.exportLogs()
                    showAlert(title: "Logs Exported", message: "Network logs have been generated and saved to console.")
                }
                
                ToolButton(icon: "arrow.clockwise", title: "Reset Network", color: .orange) {
                    networkManager.resetNetworkSettings()
                    showAlert(title: "Reset Network Settings", 
                             message: "⚠️ WARNING: This will erase all WiFi passwords!\n\n1. Settings > General\n2. Transfer or Reset iPhone\n3. Reset > Reset Network Settings")
                }
                
                ToolButton(icon: "info.circle", title: "Network Info", color: .purple) {
                    showingNetworkDetails = true
                }
                
                ToolButton(icon: "gear", title: "Settings", color: .gray) {
                    openSettings()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct NetworkStatusRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct ToolButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

struct NetworkDetailsView: View {
    @ObservedObject var networkManager: NetworkManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Network Details")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(networkManager.generateNetworkLogs())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                        )
                }
                .padding()
            }
            .navigationTitle("Network Info")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct EmergencyGuideView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("🚨 Emergency Call Guide")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("⚠️ IMPORTANT: Only use real emergency numbers if you have a real emergency!")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("STEP 1: Prepare")
                            .font(.headline)
                        Text("• Ensure SIM card is inserted\n• Turn OFF Airplane Mode\n• Close all other apps")
                        
                        Text("STEP 2: Emergency Call Method")
                            .font(.headline)
                        Text("• Open Phone app\n• Dial emergency number (e.g., 999, 911)\n• Make the call (hang up immediately if no real emergency)\n• Yemen Mobile network should temporarily connect")
                        
                        Text("STEP 3: Monitor Registration")
                            .font(.headline)
                        Text("• This app will monitor network changes\n• When Yemen Mobile appears, you'll get a notification\n• Quickly configure settings before connection drops")
                        
                        Text("STEP 4: Preserve Connection")
                            .font(.headline)
                        Text("• Go to Settings > Cellular immediately\n• Set Network Selection to Manual\n• Select Yemen Mobile if it appears")
                    }
                }
                .padding()
            }
            .navigationTitle("Emergency Guide")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ContentView()
}