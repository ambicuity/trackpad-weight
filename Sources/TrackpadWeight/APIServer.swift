/**
 * APIServer - API/Webhook Integration Feature
 * 
 * Implements Feature 12: API/Webhook Integration
 * - Provide local HTTP API for external integration
 * - Support for webhooks to notify external services
 * - RESTful endpoints for weight data, logging, and control
 */

#if canImport(Cocoa)
import Foundation
import Network

class APIServer: NSObject {
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var isRunning: Bool = false
    private var port: UInt16 = 8080
    
    // Configuration
    private let userDefaults = UserDefaults.standard
    private let apiEnabledKey = "api_server_enabled"
    private let apiPortKey = "api_server_port"
    private let webhookURLKey = "webhook_url"
    
    // Data providers (weak references to avoid retain cycles)
    weak var weightLogger: WeightLogger?
    weak var comparisonManager: ComparisonManager?
    weak var autoTareManager: AutoTareManager?
    weak var compactWidget: CompactWeightWidget?
    
    // Current state
    private var currentWeight: Double = 0.0
    private var webhookURL: String?
    
    override init() {
        super.init()
        loadSettings()
    }
    
    deinit {
        stopServer()
    }
    
    // MARK: - Public Interface
    
    func startServer() -> Bool {
        guard !isRunning else { return true }
        
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: port))
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.start(queue: .main)
            isRunning = true
            
            print("APIServer: Started on port \(port)")
            return true
            
        } catch {
            print("APIServer: Failed to start server: \(error)")
            return false
        }
    }
    
    func stopServer() {
        guard isRunning else { return }
        
        listener?.cancel()
        listener = nil
        
        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()
        
        isRunning = false
        print("APIServer: Server stopped")
    }
    
    func isServerRunning() -> Bool {
        return isRunning
    }
    
    func setPort(_ newPort: UInt16) {
        port = max(1024, min(newPort, 65535)) // Restrict to non-privileged ports
        saveSettings()
        
        if isRunning {
            stopServer()
            let _ = startServer()
        }
    }
    
    func getPort() -> UInt16 {
        return port
    }
    
    func setWebhookURL(_ url: String?) {
        webhookURL = url?.isEmpty == true ? nil : url
        saveSettings()
    }
    
    func getWebhookURL() -> String? {
        return webhookURL
    }
    
    func updateWeight(_ weight: Double) {
        currentWeight = weight
        
        // Send webhook notification if configured
        if let url = webhookURL {
            sendWebhook(url: url, weight: weight)
        }
    }
    
    func setDataProviders(weightLogger: WeightLogger? = nil,
                         comparisonManager: ComparisonManager? = nil,
                         autoTareManager: AutoTareManager? = nil,
                         compactWidget: CompactWeightWidget? = nil) {
        self.weightLogger = weightLogger
        self.comparisonManager = comparisonManager
        self.autoTareManager = autoTareManager
        self.compactWidget = compactWidget
    }
    
    // MARK: - Status and Information
    
    func getStatusDescription() -> String {
        let status = isRunning ? "Running on port \(port)" : "Stopped"
        let webhook = webhookURL != nil ? "Webhook configured" : "No webhook"
        return "API Server: \(status) • \(webhook)"
    }
    
    func getDetailedStatus() -> String {
        return """
        API Server Status:
        • Running: \(isRunning ? "Yes" : "No")
        • Port: \(port)
        • Active Connections: \(connections.count)
        • Webhook URL: \(webhookURL ?? "Not configured")
        • Current Weight: \(String(format: "%.1f", currentWeight))g
        
        Available Endpoints:
        • GET /weight - Current weight
        • GET /status - Server status
        • GET /logs - Weight logs
        • POST /calibrate - Calibrate scale
        • POST /tare - Tare scale
        """
    }
    
    // MARK: - Private Methods
    
    private func handleNewConnection(_ connection: NWConnection) {
        connections.append(connection)
        
        connection.start(queue: .main)
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.handleRequest(data: data, connection: connection)
            }
            
            if error != nil || isComplete {
                self?.connections.removeAll { $0 === connection }
                connection.cancel()
            }
        }
    }
    
    private func handleRequest(data: Data, connection: NWConnection) {
        guard let requestString = String(data: data, encoding: .utf8) else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }
        
        let lines = requestString.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }
        
        let components = firstLine.components(separatedBy: " ")
        guard components.count >= 2 else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request")
            return
        }
        
        let method = components[0]
        let path = components[1]
        
        routeRequest(method: method, path: path, connection: connection, body: extractBody(from: requestString))
    }
    
    private func routeRequest(method: String, path: String, connection: NWConnection, body: String?) {
        switch (method, path) {
        case ("GET", "/weight"):
            handleGetWeight(connection: connection)
        case ("GET", "/status"):
            handleGetStatus(connection: connection)
        case ("GET", "/logs"):
            handleGetLogs(connection: connection)
        case ("GET", "/logs/sessions"):
            handleGetSessions(connection: connection)
        case ("POST", "/calibrate"):
            handleCalibrate(connection: connection)
        case ("POST", "/tare"):
            handleTare(connection: connection, body: body)
        case ("GET", "/comparison"):
            handleGetComparison(connection: connection)
        case ("POST", "/comparison/reference"):
            handleSetReference(connection: connection, body: body)
        case ("GET", "/widget"):
            handleGetWidget(connection: connection)
        case ("POST", "/widget/toggle"):
            handleToggleWidget(connection: connection)
        case ("GET", "/"):
            handleGetAPI(connection: connection)
        default:
            sendResponse(connection: connection, statusCode: 404, body: "Not Found")
        }
    }
    
    private func handleGetWeight(connection: NWConnection) {
        let response: [String: Any] = [
            "weight": currentWeight,
            "unit": "grams",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        sendJSONResponse(connection: connection, data: response)
    }
    
    private func handleGetStatus(connection: NWConnection) {
        let response = [
            "server": [
                "running": isRunning,
                "port": port,
                "connections": connections.count
            ],
            "weight": [
                "current": currentWeight,
                "unit": "grams"
            ],
            "features": [
                "logging": weightLogger != nil,
                "comparison": comparisonManager?.isInComparisonMode() ?? false,
                "auto_tare": autoTareManager?.isAutoTareEnabled() ?? false,
                "widget": compactWidget?.isWidgetVisible() ?? false
            ]
        ] as [String: Any]
        
        sendJSONResponse(connection: connection, data: response)
    }
    
    private func handleGetLogs(connection: NWConnection) {
        let logs = weightLogger?.getRecentReadings(count: 100) ?? []
        let response = [
            "logs": logs.map { reading in
                [
                    "timestamp": ISO8601DateFormatter().string(from: reading.timestamp),
                    "weight": reading.weight,
                    "session_id": reading.sessionId.uuidString
                ]
            }
        ]
        
        sendJSONResponse(connection: connection, data: response)
    }
    
    private func handleGetSessions(connection: NWConnection) {
        let sessions = weightLogger?.getAllSessions() ?? []
        let response = [
            "sessions": sessions.prefix(20).map { session in
                [
                    "id": session.id.uuidString,
                    "start_time": ISO8601DateFormatter().string(from: session.startTime),
                    "end_time": session.endTime.map { ISO8601DateFormatter().string(from: $0) },
                    "readings_count": session.readings.count,
                    "average_weight": session.averageWeight,
                    "max_weight": session.maxWeight,
                    "min_weight": session.minWeight
                ] as [String: Any?]
            }
        ]
        
        sendJSONResponse(connection: connection, data: response)
    }
    
    private func handleCalibrate(connection: NWConnection) {
        // Trigger calibration through notification
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .apiCalibrateRequest, object: nil)
        }
        
        let response: [String: Any] = [
            "success": true,
            "message": "Calibration requested"
        ]
        
        sendJSONResponse(connection: connection, data: response)
    }
    
    private func handleTare(connection: NWConnection, body: String?) {
        var itemName = "API Item"
        
        if let body = body,
           let data = body.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let name = json["name"] as? String {
            itemName = name
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .apiTareRequest, object: itemName)
        }
        
        let response: [String: Any] = [
            "success": true,
            "message": "Tare requested for \(itemName)"
        ]
        
        sendJSONResponse(connection: connection, data: response)
    }
    
    private func handleGetComparison(connection: NWConnection) {
        let comparison = comparisonManager?.getCurrentComparison(for: currentWeight)
        
        let response: [String: Any] = [
            "comparison_mode": comparisonManager?.isInComparisonMode() ?? false,
            "current_comparison": comparison.map { comp in
                [
                    "name": comp.name,
                    "reference_weight": comp.referenceWeight,
                    "current_weight": comp.currentWeight,
                    "difference": comp.difference,
                    "percent_difference": comp.percentDifference,
                    "within_tolerance": comp.isWithinTolerance
                ] as [String: Any]
            } as Any
        ]
        
        sendJSONResponse(connection: connection, data: response)
    }
    
    private func handleSetReference(connection: NWConnection, body: String?) {
        guard let body = body,
              let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String,
              let weight = json["weight"] as? Double else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid request body")
            return
        }
        
        comparisonManager?.setReferenceWeight(name: name, weight: weight)
        
        let response: [String: Any] = [
            "success": true,
            "message": "Reference weight set for \(name)"
        ]
        
        sendJSONResponse(connection: connection, data: response)
    }
    
    private func handleGetWidget(connection: NWConnection) {
        let response = [
            "visible": compactWidget?.isWidgetVisible() ?? false,
            "position": compactWidget?.getPosition().rawValue ?? "unknown",
            "size": compactWidget?.getCurrentSize().rawValue ?? "unknown",
            "opacity": compactWidget?.getOpacity() ?? 0.9,
            "auto_hide": compactWidget?.isAutoHideEnabled() ?? false
        ] as [String: Any]
        
        sendJSONResponse(connection: connection, data: response)
    }
    
    private func handleToggleWidget(connection: NWConnection) {
        DispatchQueue.main.async {
            self.compactWidget?.toggleWidget()
        }
        
        let response = [
            "success": true,
            "visible": compactWidget?.isWidgetVisible() ?? false
        ]
        
        sendJSONResponse(connection: connection, data: response)
    }
    
    private func handleGetAPI(connection: NWConnection) {
        let apiDocs = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>TrackPad Weight Scale API</title>
            <style>
                body { font-family: monospace; margin: 40px; }
                .endpoint { margin: 20px 0; padding: 10px; background: #f5f5f5; }
                .method { font-weight: bold; color: #007acc; }
            </style>
        </head>
        <body>
            <h1>TrackPad Weight Scale API</h1>
            <p>Local HTTP API for external integration</p>
            
            <div class="endpoint">
                <span class="method">GET</span> /weight - Get current weight reading
            </div>
            
            <div class="endpoint">
                <span class="method">GET</span> /status - Get server and feature status
            </div>
            
            <div class="endpoint">
                <span class="method">GET</span> /logs - Get recent weight logs
            </div>
            
            <div class="endpoint">
                <span class="method">GET</span> /logs/sessions - Get weight sessions
            </div>
            
            <div class="endpoint">
                <span class="method">POST</span> /calibrate - Calibrate the scale
            </div>
            
            <div class="endpoint">
                <span class="method">POST</span> /tare - Tare the scale
                <br>Body: {"name": "item_name"}
            </div>
            
            <div class="endpoint">
                <span class="method">GET</span> /comparison - Get comparison status
            </div>
            
            <div class="endpoint">
                <span class="method">POST</span> /comparison/reference - Set reference weight
                <br>Body: {"name": "item_name", "weight": 123.4}
            </div>
            
            <div class="endpoint">
                <span class="method">GET</span> /widget - Get widget status
            </div>
            
            <div class="endpoint">
                <span class="method">POST</span> /widget/toggle - Toggle widget visibility
            </div>
        </body>
        </html>
        """
        
        sendResponse(connection: connection, statusCode: 200, body: apiDocs, contentType: "text/html")
    }
    
    private func sendJSONResponse(connection: NWConnection, data: Any) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            sendResponse(connection: connection, statusCode: 200, body: jsonString, contentType: "application/json")
        } catch {
            sendResponse(connection: connection, statusCode: 500, body: "Internal Server Error")
        }
    }
    
    private func sendResponse(connection: NWConnection, statusCode: Int, body: String, contentType: String = "text/plain") {
        let response = """
        HTTP/1.1 \(statusCode) \(statusCodeText(statusCode))
        Content-Type: \(contentType)
        Content-Length: \(body.utf8.count)
        Access-Control-Allow-Origin: *
        Access-Control-Allow-Methods: GET, POST, OPTIONS
        Access-Control-Allow-Headers: Content-Type
        
        \(body)
        """
        
        if let data = response.data(using: .utf8) {
            connection.send(content: data, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }
    
    private func statusCodeText(_ code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }
    
    private func extractBody(from request: String) -> String? {
        let components = request.components(separatedBy: "\r\n\r\n")
        return components.count > 1 ? components[1] : nil
    }
    
    private func sendWebhook(url: String, weight: Double) {
        guard let webhookURL = URL(string: url) else { return }
        
        let payload: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "weight": weight,
            "unit": "grams",
            "source": "trackpad_weight_scale"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            
            var request = URLRequest(url: webhookURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("APIServer: Webhook failed: \(error)")
                }
            }.resume()
            
        } catch {
            print("APIServer: Failed to encode webhook payload: \(error)")
        }
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettings() {
        port = UInt16(userDefaults.integer(forKey: apiPortKey))
        if port == 0 { port = 8080 }
        
        webhookURL = userDefaults.string(forKey: webhookURLKey)
    }
    
    private func saveSettings() {
        userDefaults.set(Int(port), forKey: apiPortKey)
        userDefaults.set(webhookURL, forKey: webhookURLKey)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let apiCalibrateRequest = Notification.Name("apiCalibrateRequest")
    static let apiTareRequest = Notification.Name("apiTareRequest")
}

#else
// Stub implementation for non-macOS platforms
import Foundation

class APIServer {
    private var isRunning: Bool = false
    private var port: UInt16 = 8080
    private var currentWeight: Double = 0.0
    
    init() {
        print("APIServer: Stub implementation for non-macOS")
    }
    
    func startServer() -> Bool { 
        isRunning = true
        return true 
    }
    
    func stopServer() { isRunning = false }
    func isServerRunning() -> Bool { return isRunning }
    func setPort(_ newPort: UInt16) { port = newPort }
    func getPort() -> UInt16 { return port }
    func setWebhookURL(_ url: String?) {}
    func getWebhookURL() -> String? { return nil }
    func updateWeight(_ weight: Double) { currentWeight = weight }
    func setDataProviders(weightLogger: WeightLogger? = nil, comparisonManager: ComparisonManager? = nil, autoTareManager: AutoTareManager? = nil, compactWidget: CompactWeightWidget? = nil) {}
    func getStatusDescription() -> String { return "API Server: Stub" }
    func getDetailedStatus() -> String { return "Stub implementation" }
}

#endif