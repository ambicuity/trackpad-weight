# API Documentation

Complete documentation for the TrackPad Weight Scale REST API and webhook system.

## Table of Contents

1. [API Overview](#api-overview)
2. [Authentication](#authentication)
3. [Endpoints](#endpoints)
4. [Webhook System](#webhook-system)
5. [Client Libraries](#client-libraries)
6. [Examples](#examples)
7. [Error Handling](#error-handling)

## API Overview

The TrackPad Weight Scale includes a built-in HTTP API server that provides programmatic access to weight measurements, configuration, and data export features.

### Base URL

```
http://localhost:8080/api
```

### API Versions

- **Current Version**: v1
- **Supported Formats**: JSON
- **HTTP Methods**: GET, POST, PUT, DELETE

### Rate Limiting

- **Weight readings**: Up to 10 requests/second
- **Configuration changes**: Up to 1 request/second
- **Data exports**: Up to 1 request/minute

## Authentication

The API currently uses no authentication for local access. All endpoints are accessible without credentials when connecting from localhost.

### Security Considerations

- API server only binds to localhost (127.0.0.1)
- No external network access by default
- Consider using SSH tunneling for remote access
- Webhook endpoints should use HTTPS when possible

## Endpoints

### Weight Measurements

#### Get Current Weight

```http
GET /api/weight
```

Returns the current weight reading from the trackpad.

**Response**:
```json
{
  "weight": 15.3,
  "unit": "grams",
  "timestamp": "2025-01-15T10:30:00Z",
  "calibrated": true,
  "stable": true,
  "session_id": "session_20250115_103000"
}
```

**Response Fields**:
- `weight` (number): Current weight in grams
- `unit` (string): Always "grams"
- `timestamp` (string): ISO 8601 timestamp of measurement
- `calibrated` (boolean): Whether scale has been calibrated
- `stable` (boolean): Whether reading is stable (not changing)
- `session_id` (string): Current measurement session identifier

#### Get Weight History

```http
GET /api/weight/history?limit=50&since=2025-01-15T00:00:00Z
```

Returns historical weight measurements.

**Query Parameters**:
- `limit` (optional, default: 100): Maximum number of records
- `since` (optional): ISO 8601 timestamp, return records after this time
- `session_id` (optional): Filter by specific session

**Response**:
```json
{
  "measurements": [
    {
      "weight": 15.3,
      "timestamp": "2025-01-15T10:30:00Z",
      "session_id": "session_20250115_103000",
      "tare_point": 0.0
    }
  ],
  "total_count": 1,
  "has_more": false
}
```

#### Get Weight Statistics

```http
GET /api/weight/stats?session_id=session_20250115_103000
```

Returns statistical analysis of weight measurements.

**Response**:
```json
{
  "session_id": "session_20250115_103000",
  "measurement_count": 150,
  "duration_seconds": 300,
  "min_weight": 0.0,
  "max_weight": 25.7,
  "average_weight": 12.4,
  "median_weight": 11.8,
  "standard_deviation": 3.2,
  "stability_score": 0.85
}
```

### Configuration and Control

#### Calibrate Scale

```http
POST /api/calibrate
```

Calibrates the scale to zero the current reading.

**Response**:
```json
{
  "success": true,
  "message": "Scale calibrated successfully",
  "timestamp": "2025-01-15T10:30:00Z",
  "previous_offset": 2.1,
  "new_offset": 0.0
}
```

#### Set Tare Point

```http
POST /api/tare
Content-Type: application/json

{
  "name": "container",
  "description": "Small glass bowl"
}
```

Sets a tare point for comparison measurements.

**Request Body**:
- `name` (required): Name for this tare point
- `description` (optional): Additional description

**Response**:
```json
{
  "success": true,
  "tare_id": "tare_20250115_103000",
  "name": "container",
  "tare_weight": 15.3,
  "timestamp": "2025-01-15T10:30:00Z"
}
```

#### Get Configuration

```http
GET /api/config
```

Returns current application configuration.

**Response**:
```json
{
  "auto_tare_enabled": true,
  "auto_tare_timeout": 5000,
  "comparison_mode_enabled": false,
  "logging_enabled": true,
  "api_server_enabled": true,
  "api_server_port": 8080,
  "webhook_url": null,
  "compact_widget_visible": false,
  "theme": "system",
  "font_size": "medium"
}
```

#### Update Configuration

```http
PUT /api/config
Content-Type: application/json

{
  "auto_tare_enabled": false,
  "auto_tare_timeout": 10000
}
```

Updates configuration settings. Only provided fields are updated.

**Response**:
```json
{
  "success": true,
  "updated_fields": ["auto_tare_enabled", "auto_tare_timeout"],
  "config": {
    "auto_tare_enabled": false,
    "auto_tare_timeout": 10000
  }
}
```

### Data Export

#### Export Weight Log (CSV)

```http
GET /api/export/csv?session_id=session_20250115_103000
```

Exports weight measurements as CSV data.

**Query Parameters**:
- `session_id` (optional): Export specific session only
- `start_date` (optional): ISO 8601 start date
- `end_date` (optional): ISO 8601 end date

**Response**:
```
Content-Type: text/csv
Content-Disposition: attachment; filename="weights_20250115.csv"

timestamp,weight,session_id,tare_point,notes
2025-01-15T10:30:00Z,15.3,session_20250115_103000,0.0,""
2025-01-15T10:30:15Z,18.7,session_20250115_103000,0.0,""
```

#### Export Weight Log (JSON)

```http
GET /api/export/json?session_id=session_20250115_103000
```

Exports weight measurements as JSON data.

**Response**:
```json
{
  "export_timestamp": "2025-01-15T10:35:00Z",
  "session_count": 1,
  "measurement_count": 150,
  "sessions": [
    {
      "session_id": "session_20250115_103000",
      "start_time": "2025-01-15T10:30:00Z",
      "end_time": "2025-01-15T10:35:00Z",
      "measurements": [
        {
          "timestamp": "2025-01-15T10:30:00Z",
          "weight": 15.3,
          "tare_point": 0.0
        }
      ]
    }
  ]
}
```

### Comparison and Analysis

#### Get Comparison Data

```http
GET /api/comparisons
```

Returns current comparison mode data.

**Response**:
```json
{
  "comparison_mode_enabled": true,
  "reference_items": [
    {
      "id": "ref_001",
      "name": "Gold Ring",
      "reference_weight": 3.5,
      "current_weight": 3.2,
      "difference": -0.3,
      "percent_difference": -8.57,
      "within_tolerance": true,
      "tolerance": 0.5,
      "last_updated": "2025-01-15T10:30:00Z"
    }
  ],
  "active_comparisons": 1
}
```

#### Add Reference Item

```http
POST /api/comparisons/reference
Content-Type: application/json

{
  "name": "Silver Coin",
  "reference_weight": 8.1,
  "tolerance": 0.2,
  "description": "1964 silver quarter"
}
```

Adds a new reference item for comparison.

**Response**:
```json
{
  "success": true,
  "reference_id": "ref_002",
  "name": "Silver Coin",
  "reference_weight": 8.1,
  "tolerance": 0.2
}
```

### System Information

#### Get Server Status

```http
GET /api/status
```

Returns API server and application status.

**Response**:
```json
{
  "server_status": "running",
  "uptime_seconds": 3600,
  "version": "1.0.0",
  "build": "20250115",
  "platform": "macOS",
  "trackpad_model": "MacBook Pro 16-inch 2021",
  "force_touch_available": true,
  "multitouch_support": true,
  "active_sessions": 1,
  "total_measurements": 1547,
  "memory_usage_mb": 45.2,
  "cpu_usage_percent": 2.1
}
```

#### Get Health Check

```http
GET /api/health
```

Simple health check endpoint for monitoring.

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

## Webhook System

The webhook system allows external services to receive real-time notifications about weight changes and system events.

### Configuration

Configure webhook URL through the API or menu interface:

```http
PUT /api/config
Content-Type: application/json

{
  "webhook_url": "https://your-server.com/webhook"
}
```

### Webhook Events

#### Weight Changed

Sent when weight reading changes significantly.

```json
{
  "event": "weight_changed",
  "timestamp": "2025-01-15T10:30:00Z",
  "data": {
    "previous_weight": 10.5,
    "current_weight": 15.3,
    "change": 4.8,
    "session_id": "session_20250115_103000"
  }
}
```

#### Calibration Performed

Sent when scale is calibrated.

```json
{
  "event": "calibration_performed",
  "timestamp": "2025-01-15T10:30:00Z",
  "data": {
    "previous_offset": 2.1,
    "new_offset": 0.0,
    "session_id": "session_20250115_103000"
  }
}
```

#### Tare Set

Sent when a new tare point is established.

```json
{
  "event": "tare_set",
  "timestamp": "2025-01-15T10:30:00Z",
  "data": {
    "tare_id": "tare_20250115_103000",
    "name": "container",
    "tare_weight": 15.3,
    "session_id": "session_20250115_103000"
  }
}
```

#### Session Started/Ended

Sent when measurement sessions begin or end.

```json
{
  "event": "session_started",
  "timestamp": "2025-01-15T10:30:00Z",
  "data": {
    "session_id": "session_20250115_103000",
    "trigger": "auto_tare"
  }
}
```

### Webhook Security

#### Signature Verification

Webhooks include an HMAC signature for verification:

```http
POST /your-webhook-endpoint
Content-Type: application/json
X-TrackpadWeight-Signature: sha256=a8b7c9d...
X-TrackpadWeight-Timestamp: 1642339800

{
  "event": "weight_changed",
  ...
}
```

#### Retry Logic

- Failed webhooks are retried up to 3 times
- Exponential backoff: 1s, 5s, 25s
- Webhooks are considered failed if they return non-2xx status codes
- Timeout: 30 seconds

## Client Libraries

### Python

```python
import requests
from datetime import datetime

class TrackpadWeightClient:
    def __init__(self, base_url="http://localhost:8080/api"):
        self.base_url = base_url
    
    def get_current_weight(self):
        response = requests.get(f"{self.base_url}/weight")
        return response.json()
    
    def calibrate(self):
        response = requests.post(f"{self.base_url}/calibrate")
        return response.json()
    
    def set_tare(self, name, description=None):
        data = {"name": name}
        if description:
            data["description"] = description
        response = requests.post(f"{self.base_url}/tare", json=data)
        return response.json()
    
    def get_history(self, limit=100, since=None):
        params = {"limit": limit}
        if since:
            params["since"] = since.isoformat()
        response = requests.get(f"{self.base_url}/weight/history", params=params)
        return response.json()

# Usage example
client = TrackpadWeightClient()
weight = client.get_current_weight()
print(f"Current weight: {weight['weight']}g")
```

### JavaScript (Node.js)

```javascript
const axios = require('axios');

class TrackpadWeightClient {
    constructor(baseUrl = 'http://localhost:8080/api') {
        this.baseUrl = baseUrl;
    }
    
    async getCurrentWeight() {
        const response = await axios.get(`${this.baseUrl}/weight`);
        return response.data;
    }
    
    async calibrate() {
        const response = await axios.post(`${this.baseUrl}/calibrate`);
        return response.data;
    }
    
    async setTare(name, description = null) {
        const data = { name };
        if (description) data.description = description;
        const response = await axios.post(`${this.baseUrl}/tare`, data);
        return response.data;
    }
    
    async getHistory(limit = 100, since = null) {
        const params = { limit };
        if (since) params.since = since.toISOString();
        const response = await axios.get(`${this.baseUrl}/weight/history`, { params });
        return response.data;
    }
}

// Usage example
const client = new TrackpadWeightClient();
client.getCurrentWeight().then(weight => {
    console.log(`Current weight: ${weight.weight}g`);
});
```

### curl Examples

```bash
# Get current weight
curl http://localhost:8080/api/weight

# Calibrate scale
curl -X POST http://localhost:8080/api/calibrate

# Set tare point
curl -X POST http://localhost:8080/api/tare \
  -H "Content-Type: application/json" \
  -d '{"name": "container", "description": "Small bowl"}'

# Get weight history
curl "http://localhost:8080/api/weight/history?limit=10"

# Export CSV data
curl http://localhost:8080/api/export/csv > weights.csv

# Update configuration
curl -X PUT http://localhost:8080/api/config \
  -H "Content-Type: application/json" \
  -d '{"auto_tare_enabled": true, "auto_tare_timeout": 5000}'
```

## Examples

### Real-time Weight Monitoring

```python
import requests
import time
from datetime import datetime

def monitor_weight(duration=60, interval=0.5):
    """Monitor weight changes for specified duration."""
    client = TrackpadWeightClient()
    start_time = time.time()
    previous_weight = None
    
    print(f"Monitoring weight for {duration} seconds...")
    
    while time.time() - start_time < duration:
        try:
            data = client.get_current_weight()
            current_weight = data['weight']
            timestamp = datetime.now().strftime('%H:%M:%S')
            
            if previous_weight is None or abs(current_weight - previous_weight) > 0.1:
                print(f"[{timestamp}] Weight: {current_weight:.1f}g")
                previous_weight = current_weight
            
            time.sleep(interval)
            
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(1)

# Usage
monitor_weight(duration=30, interval=0.5)
```

### Automated Calibration

```python
def auto_calibrate_if_needed():
    """Calibrate scale if readings seem unstable."""
    client = TrackpadWeightClient()
    
    # Take several readings
    readings = []
    for _ in range(10):
        weight = client.get_current_weight()
        readings.append(weight['weight'])
        time.sleep(0.1)
    
    # Calculate standard deviation
    import statistics
    std_dev = statistics.stdev(readings) if len(readings) > 1 else 0
    
    # Calibrate if readings are too variable
    if std_dev > 0.5:  # More than 0.5g standard deviation
        print(f"Readings unstable (std dev: {std_dev:.2f}g), calibrating...")
        client.calibrate()
        return True
    else:
        print(f"Readings stable (std dev: {std_dev:.2f}g)")
        return False
```

### Batch Weight Logging

```python
def log_weight_batch(items):
    """Log weights for multiple items with automatic taring."""
    client = TrackpadWeightClient()
    results = []
    
    for item_name in items:
        input(f"Place '{item_name}' on scale and press Enter...")
        
        # Set tare for this item
        client.set_tare(item_name)
        
        input("Add the item content and press Enter...")
        
        # Get final weight
        weight_data = client.get_current_weight()
        results.append({
            'item': item_name,
            'weight': weight_data['weight'],
            'timestamp': weight_data['timestamp']
        })
        
        print(f"'{item_name}': {weight_data['weight']:.1f}g")
        
        input("Remove item and press Enter to continue...")
    
    return results

# Usage
items = ["Letter 1", "Letter 2", "Package 1"]
results = log_weight_batch(items)
```

## Error Handling

### HTTP Status Codes

- `200 OK`: Request successful
- `400 Bad Request`: Invalid request parameters
- `404 Not Found`: Endpoint not found
- `405 Method Not Allowed`: HTTP method not supported
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error
- `503 Service Unavailable`: Service temporarily unavailable

### Error Response Format

```json
{
  "error": {
    "code": "INVALID_PARAMETER",
    "message": "The 'limit' parameter must be between 1 and 1000",
    "details": {
      "parameter": "limit",
      "provided_value": 5000,
      "allowed_range": "1-1000"
    },
    "timestamp": "2025-01-15T10:30:00Z"
  }
}
```

### Common Error Codes

- `TRACKPAD_NOT_AVAILABLE`: Force Touch trackpad not detected
- `CALIBRATION_FAILED`: Scale calibration unsuccessful
- `INVALID_PARAMETER`: Request parameter validation failed
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `SESSION_NOT_FOUND`: Specified session ID not found
- `WEBHOOK_DELIVERY_FAILED`: Webhook endpoint not reachable
- `CONFIGURATION_ERROR`: Configuration value invalid

### Retry Strategies

```python
import time
import requests
from functools import wraps

def retry_on_error(max_retries=3, delay=1):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except requests.exceptions.RequestException as e:
                    if attempt == max_retries - 1:
                        raise
                    print(f"Attempt {attempt + 1} failed: {e}")
                    time.sleep(delay * (2 ** attempt))  # Exponential backoff
            return None
        return wrapper
    return decorator

@retry_on_error(max_retries=3)
def get_weight_with_retry():
    response = requests.get("http://localhost:8080/api/weight")
    response.raise_for_status()
    return response.json()
```

---

**Last Updated**: January 2025
**API Version**: 1.0
**Documentation Version**: 2.0