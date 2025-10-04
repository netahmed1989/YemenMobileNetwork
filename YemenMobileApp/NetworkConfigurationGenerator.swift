//
//  NetworkConfigurationGenerator.swift
//  Yemen Mobile Network Assistant
//

import Foundation

class NetworkConfigurationGenerator {
    
    static func generateYemenMobileIPCC() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleDisplayName</key>
            <string>Yemen Mobile</string>
            <key>CFBundleIdentifier</key>
            <string>com.apple.carrier.YemenMobile_Yemen</string>
            <key>CFBundleVersion</key>
            <string>\(timestamp)</string>
            
            <!-- Carrier Identity -->
            <key>CarrierName</key>
            <string>Yemen Mobile</string>
            <key>OverridesSpn</key>
            <array>
                <dict>
                    <key>mcc</key>
                    <string>421</string>
                    <key>mnc</key>
                    <string>03</string>
                    <key>spn</key>
                    <string>Yemen Mobile</string>
                </dict>
            </array>
            
            <!-- Network Technology Support -->
            <key>SupportsCDMA</key>
            <true/>
            <key>SupportsGSM</key>
            <false/>
            <key>SupportsLTE</key>
            <true/>
            <key>Supports5G</key>
            <false/>
            
            <!-- CDMA Configuration -->
            <key>SupportedCDMAFrequencies</key>
            <array>
                <string>BC0</string>
                <string>BC21</string>
            </array>
            <key>CDMAPreferredNetworkType</key>
            <string>CDMA_EVDO</string>
            <key>CDMANetworkPriority</key>
            <integer>1</integer>
            
            <!-- APN Settings -->
            <key>DefaultAPNSettings</key>
            <dict>
                <key>DefaultAPNSettingsIPv4</key>
                <dict>
                    <key>apn</key>
                    <string>ymobile</string>
                    <key>username</key>
                    <string>ymobile</string>
                    <key>password</key>
                    <string>ymobile</string>
                    <key>type</key>
                    <array>
                        <string>default</string>
                        <string>supl</string>
                    </array>
                </dict>
            </dict>
            
            <!-- Network Recognition -->
            <key>PhoneNumberRegistrationGatewayAddress</key>
            <string>421</string>
            <key>AllowEDGEEditing</key>
            <true/>
            <key>AllowsVOIP</key>
            <true/>
            <key>APNEditabilityTypeMask</key>
            <integer>4</integer>
            
            <!-- Emergency Call Enhancement -->
            <key>ForceEmergencyNetworkRegistration</key>
            <true/>
            <key>AllowEmergencyCallNetworkSelection</key>
            <true/>
            <key>EmergencyNetworkSelectionTimeout</key>
            <integer>30</integer>
            
            <!-- VoLTE Support -->
            <key>AllowVoLTE</key>
            <true/>
            <key>VoLTEEnabled</key>
            <true/>
            <key>SupportsIMS</key>
            <true/>
            
            <!-- UI Customization -->
            <key>ShowCallForwardingUI</key>
            <true/>
            <key>ShowCallWaitingUI</key>
            <true/>
            <key>VoicemailDefaultEnabled</key>
            <false/>
            
            <!-- Data Connection -->
            <key>SupportsCellularData</key>
            <true/>
            <key>SupportsPersonalHotspot</key>
            <true/>
            <key>ShowDataConnectionActivationAlert</key>
            <false/>
            
            <!-- Network URLs -->
            <key>MyAccountURL</key>
            <string>http://www.yemenmobile.com.ye</string>
            <key>MyAccountURLTitle</key>
            <string>Yemen Mobile</string>
            
        </dict>
        </plist>
        """
    }
    
    static func generateCarrierBundle() -> [String: Any] {
        return [
            "CFBundleDisplayName": "Yemen Mobile",
            "CFBundleIdentifier": "com.apple.carrier.YemenMobile_Yemen",
            "CFBundleVersion": "\(Int(Date().timeIntervalSince1970))",
            "CarrierName": "Yemen Mobile",
            "SupportsCDMA": true,
            "SupportsGSM": false,
            "SupportsLTE": true,
            "SupportedCDMAFrequencies": ["BC0", "BC21"],
            "CDMAPreferredNetworkType": "CDMA_EVDO",
            "DefaultAPNSettings": [
                "DefaultAPNSettingsIPv4": [
                    "apn": "ymobile",
                    "username": "ymobile",
                    "password": "ymobile",
                    "type": ["default", "supl"]
                ]
            ],
            "OverridesSpn": [[
                "mcc": "421",
                "mnc": "03",
                "spn": "Yemen Mobile"
            ]]
        ]
    }
    
    static func exportConfiguration(to url: URL) throws {
        let ipccContent = generateYemenMobileIPCC()
        try ipccContent.write(to: url, atomically: true, encoding: .utf8)
    }
}