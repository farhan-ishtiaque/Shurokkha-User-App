# Police Module - Django Backend Documentation for Flutter Integration

## Overview

The Police Module in the Shurokkha Django backend provides comprehensive functionality for police report management, officer management, and police station operations. This documentation covers all API endpoints, data models, and workflow logic needed for Flutter integration.

## Table of Contents

1. [Authentication](#authentication)
2. [Data Models](#data-models) 
3. [Police Report Workflow](#police-report-workflow)
4. [API Endpoints](#api-endpoints)
5. [Firebase/Firestore Integration](#firebasefirestore-integration)
6. [Missing Features & Recommendations](#missing-features--recommendations)
7. [Error Handling](#error-handling)
8. [Integration Examples](#integration-examples)

---

## Authentication

### User Authentication for Mobile App
- **Type**: Token-based authentication
- **Header Format**: `Authorization: Token {token_key}`
- **Model**: `AppUserToken` (linked to `AppUser`)

### Police Station Authentication
- **Type**: Session-based (for web dashboard)
- **Fields**: `station_id` and `password`

---

## Data Models

### 1. AppUser Model
**File**: `app_auth/models.py`

Users who submit police reports from the mobile app.

```python
class AppUser(models.Model):
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    username = models.CharField(max_length=30, unique=True)
    email = models.EmailField(unique=True)
    date_of_birth = models.DateField()
    nid_number = models.CharField(max_length=20, unique=True)
    address = models.TextField()
    nid_front_image = models.ImageField(upload_to='nid_images/')
    selfie_image = models.ImageField(upload_to='selfie_images/')
    phone_number = models.CharField(max_length=15, unique=True)
    password = models.CharField(max_length=128)
    emergency_contact1 = models.CharField(max_length=15, blank=True, null=True)
    emergency_contact2 = models.CharField(max_length=15, blank=True, null=True)
    emergency_contact3 = models.CharField(max_length=15, blank=True, null=True)
    blood_group = models.CharField(max_length=5, blank=True, null=True)
    health_conditions = models.TextField(blank=True, null=True)
    allergies = models.TextField(blank=True, null=True)
    longitude = models.FloatField(blank=True, null=True)
    latitude = models.FloatField(blank=True, null=True)
    rating = models.FloatField(default=0.0)  # Used for trust scoring
```

**Rating System**:
- Starts at 0.0
- Increases by 1 when report is marked "completed"
- Decreases by 1 when report is marked "fraud"
- Users with rating >= 0 get automatic police station assignment
- Users with rating < 0 get sent to operator for verification

### 2. PoliceStation Model
**File**: `police/models.py`

```python
class PoliceStation(models.Model):
    station_id = models.CharField(max_length=4, primary_key=True)
    name = models.CharField(max_length=100)
    password = models.CharField(max_length=128)
    postal_code = models.CharField(max_length=10)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
```

### 3. PoliceOfficer Model
**File**: `police/models.py`

```python
class PoliceOfficer(models.Model):
    station = models.ForeignKey('PoliceStation', on_delete=models.CASCADE, related_name='officers')
    unit_id = models.CharField(max_length=20)
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    username = models.CharField(max_length=50, unique=True)
    password = models.CharField(max_length=128)
    phone_number = models.CharField(max_length=20)
    nid_number = models.CharField(max_length=30)
    dob = models.DateField(null=True, blank=True)
    license_number = models.CharField(max_length=50)
    license_validity = models.DateField(null=True, blank=True)
    address = models.CharField(max_length=255)
    is_available = models.BooleanField(default=True)
    created_at = models.DateTimeField(default=timezone.now)
```

### 4. PoliceReport Model
**File**: `emergencyReport/models.py`

```python
class PoliceReport(models.Model):
    description = models.TextField()
    location = models.ForeignKey(Location, null=True, blank=True, on_delete=models.CASCADE)
    submitted_by = models.ForeignKey(AppUser, on_delete=models.SET_NULL, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    timestamp = models.DateTimeField(auto_now_add=True)
    assigned_station = models.ForeignKey(PoliceStation, null=True, blank=True, on_delete=models.SET_NULL)
    assigned_operator = models.ForeignKey(User, null=True, blank=True, on_delete=models.SET_NULL)
    assigned_driver = models.ForeignKey(eunitDriver, null=True, blank=True, on_delete=models.SET_NULL)
    operator_status = models.CharField(
        max_length=20,
        choices=[('registered', 'Registered'), ('assigned', 'Assigned')],
        default='registered'
    )
    anonymous = models.BooleanField(default=False)
    media_file = models.FileField(upload_to='police_reports/', null=True, blank=True)
```

**Status Choices**:
- `pending`: Initial state
- `accepted`: Officer assigned
- `completed`: Case resolved successfully
- `fraud`: Report marked as fraudulent (only for non-anonymous)

### 5. Location Model
**File**: `emergencyReport/models.py`

```python
class Location(models.Model):
    address = models.TextField(null=True, blank=True)
    latitude = models.FloatField()
    longitude = models.FloatField()
```

---

## Police Report Workflow

### 1. Report Submission Flow

```
User Submits Report → Validation → Location Creation → Assignment Logic → Database Save → Firebase Sync → Response
```

#### Assignment Logic:
1. **Anonymous Reports**: Always go to operator for verification
2. **Non-Anonymous Reports**: 
   - If `user.rating >= 0`: Automatic assignment to nearest police station
   - If `user.rating < 0`: Sent to operator for verification

#### Distance-Based Assignment:
- System finds nearest police station using geopy distance calculation
- Only stations with valid latitude/longitude are considered
- Distance is calculated and stored for reference

### 2. Operator Verification Workflow

For reports requiring operator verification:
1. Report appears in operator dashboard
2. Operator reviews report details and user information
3. Operator can:
   - Approve → Assign to nearest police station
   - Reject → Mark as fraud (affects user rating)

### 3. Police Station Dashboard Workflow

1. Reports assigned to station appear in dashboard
2. Station can view report details and user information
3. Station assigns available officer to report
4. Officer becomes unavailable upon assignment
5. Officer can update report status
6. When marked "completed", officer becomes available again

---

## API Endpoints

### Base URL Structure
- **Emergency Reports**: `/api/users/emergency/`
- **Police Management**: `/police/`
- **User Authentication**: `/api/users/`

### 1. Submit Police Report
**Endpoint**: `POST /api/users/emergency/submit-police-report/`
**Authentication**: Required (Token)

**Request Format**: `multipart/form-data` (for media upload support)

**Parameters**:
```javascript
{
  "description": "string (required)",
  "latitude": "float (required)",
  "longitude": "float (required)", 
  "address": "string (required)",
  "anonymous": "boolean (optional, default: false)",
  "media": "file (optional)"
}
```

**Example Request**:
```bash
curl -X POST \
  -H "Authorization: Token abc123..." \
  -F "description=Theft reported at local shop" \
  -F "latitude=23.7461" \
  -F "longitude=90.3742" \
  -F "address=123 Main Street, Dhaka" \
  -F "anonymous=false" \
  -F "media=@photo.jpg" \
  http://yourserver.com/api/users/emergency/submit-police-report/
```

**Response**:
```json
{
  "success": true,
  "message": "Police report submitted successfully",
  "report_id": 123,
  "anonymous": false,
  "media_attached": true,
  "assigned_station": "Dhanmondi Police Station",
  "distance_km": 2.5,
  "note": null
}
```

**Error Response**:
```json
{
  "error": "All fields (latitude, longitude, address, description) are required.",
  "status": 400
}
```

### 2. Get User Reports
**Endpoint**: `GET /api/users/emergency/user-reports/`
**Authentication**: Required (Token)

**Response**:
```json
{
  "reports": [
    {
      "report_id": 123,
      "description": "Theft reported at local shop",
      "status": "pending",
      "timestamp": "2025-01-15T10:30:00Z",
      "address": "123 Main Street, Dhaka",
      "latitude": 23.7461,
      "longitude": 90.3742,
      "assigned_station": "Dhanmondi Police Station",
      "assigned_driver_id": null,
      "operator_status": "registered"
    }
  ]
}
```

### 3. Get Report Status
**Endpoint**: `GET /api/users/emergency/report-status/{report_id}/`
**Authentication**: Required (Token)

**Response**:
```json
{
  "report_id": 123,
  "status": "accepted",
  "assigned_officer": "Officer John Doe",
  "assigned_station": "Dhanmondi Police Station",
  "last_updated": "2025-01-15T11:00:00Z"
}
```

### 4. Police Station Management APIs

#### Login to Police Station
**Endpoint**: `POST /police/login/`
**Authentication**: None (establishes session)

**Parameters**:
```json
{
  "station_id": "1234",
  "password": "police123"
}
```

#### Get Available Officers
**Endpoint**: `GET /police/get-available-officers/`
**Authentication**: Session required

**Response**:
```json
{
  "success": true,
  "officers": [
    {
      "id": 1,
      "unit_id": "P001",
      "first_name": "John",
      "last_name": "Doe",
      "username": "john.doe",
      "phone_number": "01712345678",
      "nid_number": "1234567890",
      "dob": "1990-01-01",
      "license_number": "DL12345",
      "license_validity": "2025-12-31",
      "address": "Police Quarters, Dhaka",
      "is_available": true
    }
  ]
}
```

#### Assign Officer to Report
**Endpoint**: `POST /police/assign-officer/`
**Authentication**: Session required

**Parameters**:
```json
{
  "report_id": "123",
  "officer_id": "1"
}
```

**Response**:
```json
{
  "success": true,
  "officer_name": "John Doe"
}
```

#### Register New Officer
**Endpoint**: `POST /police/register-officer/`
**Authentication**: Session required

**Parameters**:
```json
{
  "unit_id": "P002",
  "first_name": "Jane",
  "last_name": "Smith",
  "username": "jane.smith",
  "password": "password123",
  "phone_number": "01712345679",
  "nid_number": "1234567891",
  "dob": "1992-05-15",
  "license_number": "DL12346",
  "license_validity": "2026-05-15",
  "address": "Police Quarters, Dhaka"
}
```

#### Update Report Status
**Endpoint**: `POST /police/update-status/`
**Authentication**: Session required

**Parameters**:
```json
{
  "report_id": "123",
  "status": "completed"
}
```

#### Update Operator Status (For Admin/Operator Panel)
**Endpoint**: `POST /api/users/emergency/update-operator-status/`
**Authentication**: Session required

**Parameters**:
```json
{
  "report_id": "123",
  "report_type": "police",
  "operator_status": "assigned",
  "assigned_operator_id": "456"
}
```

**Operator Status Values**:
- `registered`: Initial state when report is submitted
- `assigned`: When operator reviews and assigns to police station

### 5. User Information API
**Endpoint**: `GET /police/api/user-info/{user_id}/`
**Authentication**: Session required

**Response**:
```json
{
  "success": true,
  "user": {
    "first_name": "Alice",
    "last_name": "Johnson",
    "username": "alice.j",
    "email": "alice@example.com",
    "phone_number": "01712345680",
    "date_of_birth": "1985-03-10",
    "nid_number": "9876543210",
    "address": "456 Oak Avenue, Dhaka",
    "emergency_contact1": "01712345681",
    "emergency_contact2": "01712345682",
    "emergency_contact3": "01712345683",
    "blood_group": "O+",
    "health_conditions": "None",
    "allergies": "Penicillin",
    "rating": 2.5
  }
}
```

---

## Firebase/Firestore Integration

### Police Reports Collection
**Collection**: `police_reports`
**Document ID**: `{report_id}`

**Document Structure**:
```json
{
  "report_id": "123",
  "description": "Theft reported at local shop",
  "latitude": 23.7461,
  "longitude": 90.3742,
  "address": "123 Main Street, Dhaka",
  "anonymous": false,
  "user_id": 456,
  "assigned_station": "Dhanmondi Police Station",
  "assigned_station_id": "1234",
  "operator_status": "registered",
  "status": "pending",
  "timestamp": "SERVER_TIMESTAMP",
  "media_attached": true,
  "distance_km": 2.5,
  "user_rating": 2.5,
  "assigned_officer_id": null,
  "assigned_officer_name": null,
  "updated_at": "SERVER_TIMESTAMP"
}
```

### Real-time Updates
- Firebase automatically syncs status changes
- Police dashboard gets real-time updates
- Mobile app can listen to document changes for live status updates

---

## Missing Features & Recommendations

### 1. Currently Missing Features

#### A. Police Report Status Tracking for Mobile
- **Issue**: No dedicated API for police report status tracking
- **Current**: `get_report_status` only works for medical reports 
- **Recommendation**: Add endpoint similar to medical reports
- **Suggested Endpoint**: `GET /api/users/emergency/police-report-status/{report_id}/`

**Suggested Implementation**:
```python
@csrf_exempt
def get_police_report_status(request, report_id):
    """Get status of a specific police report"""
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Token '):
        return JsonResponse({'error': 'Missing or invalid token format'}, status=401)
    
    token_key = auth_header.replace('Token ', '').strip()
    
    try:
        user_token = AppUserToken.objects.get(key=token_key)
        user = user_token.user
        
        # For anonymous reports, user won't be linked
        report = PoliceReport.objects.get(id=report_id)
        if not report.anonymous and report.submitted_by != user:
            return JsonResponse({'error': 'Unauthorized'}, status=403)
            
        return JsonResponse({
            'report_id': report.id,
            'status': report.status,
            'description': report.description,
            'timestamp': report.timestamp.isoformat(),
            'assigned_station': report.assigned_station.name if report.assigned_station else None,
            'assigned_officer': f"{report.assigned_driver.first_name} {report.assigned_driver.last_name}" if report.assigned_driver else None,
            'anonymous': report.anonymous,
            'operator_status': report.operator_status
        })
    except PoliceReport.DoesNotExist:
        return JsonResponse({'error': 'Police report not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

#### B. Police Report History
- **Issue**: No API to get user's police report history
- **Current**: `user-reports` endpoint only returns medical reports
- **Recommendation**: Extend existing user-reports endpoint to include police reports
- **Suggested Enhancement**: Add `report_type` parameter to filter reports

**Current Implementation Limitation**:
```python
# Current code in get_user_reports() only handles medical reports:
reports = MedicalReport.objects.filter(submitted_by=user).order_by('-timestamp')
```

**Suggested Enhanced Implementation**:
```python
@csrf_exempt  
def get_user_reports(request):
    """Get all reports for the authenticated user"""
    # ... auth validation ...
    
    report_type = request.GET.get('type', 'all')  # all, medical, police, fire
    
    all_reports = []
    
    if report_type in ['all', 'police']:
        police_reports = PoliceReport.objects.filter(
            submitted_by=user, anonymous=False
        ).order_by('-timestamp')
        
        for report in police_reports:
            all_reports.append({
                'report_id': report.id,
                'report_type': 'police',
                'description': report.description,
                'status': report.status,
                'timestamp': report.timestamp.isoformat(),
                'address': report.location.address if report.location else '',
                'assigned_station': report.assigned_station.name if report.assigned_station else None,
                'assigned_officer': f"{report.assigned_driver.first_name} {report.assigned_driver.last_name}" if report.assigned_driver else None,
                'operator_status': report.operator_status,
            })
    
    if report_type in ['all', 'medical']:
        # ... existing medical report code ...
    
    # Sort all reports by timestamp
    all_reports.sort(key=lambda x: x['timestamp'], reverse=True)
    
    return JsonResponse({'reports': all_reports})
```

#### C. Media File Handling
- **Issue**: Media files are stored but no API to retrieve them
- **Current**: `media_file` field stores file path but URLs are not provided in API responses
- **Recommendation**: Add media URL in API responses
- **Security**: Implement proper access control for media files

**Current Django Settings Needed**:
```python
# In settings.py
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# In urls.py (for development)
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

**Suggested API Enhancement**:
```python
# In API responses, add media_url field:
{
  "report_id": 123,
  "description": "Theft reported",
  "media_attached": true,
  "media_url": "http://yourserver.com/media/police_reports/evidence_123.jpg",
  "media_filename": "evidence_123.jpg"
}
```

**Security Implementation**:
```python
@csrf_exempt
def get_police_report_media(request, report_id):
    """Secure endpoint to access police report media files"""
    # Verify user has access to this report
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Token '):
        return JsonResponse({'error': 'Unauthorized'}, status=401)
    
    try:
        user_token = AppUserToken.objects.get(key=auth_header.replace('Token ', ''))
        user = user_token.user
        
        report = PoliceReport.objects.get(id=report_id)
        
        # Check access permissions
        if not report.anonymous and report.submitted_by != user:
            return JsonResponse({'error': 'Access denied'}, status=403)
            
        if report.media_file:
            response = FileResponse(
                open(report.media_file.path, 'rb'),
                content_type='application/octet-stream'
            )
            response['Content-Disposition'] = f'attachment; filename="{os.path.basename(report.media_file.name)}"'
            return response
        else:
            return JsonResponse({'error': 'No media file attached'}, status=404)
            
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
```

#### D. Push Notifications
- **Issue**: No notification system for status updates
- **Recommendation**: Implement FCM integration
- **Use Cases**: Report accepted, officer assigned, case completed

### 2. Enhancements Needed

#### A. Advanced Search & Filtering
```python
# Suggested API enhancement
GET /api/users/emergency/reports/?type=police&status=pending&date_from=2025-01-01
```

#### B. Report Categories
- Currently all police reports are treated equally
- Suggestion: Add severity levels (Low, Medium, High, Emergency)
- Impact on assignment priority

#### C. Officer Location Tracking
- Add real-time location tracking for assigned officers
- Help users track response progress

#### D. Report Updates/Comments
- Allow officers to add progress updates
- Users can see investigation progress

### 3. Security Enhancements

#### A. Rate Limiting
- Implement rate limiting for report submission
- Prevent spam/abuse

#### B. Input Validation
- Add more robust validation for coordinates
- Validate address format and existence

#### C. Media File Validation
- File type restrictions
- File size limits
- Malware scanning

---

## Error Handling

### Common Error Codes

| Status Code | Meaning | Common Causes |
|-------------|---------|---------------|
| 400 | Bad Request | Missing required fields, invalid data format |
| 401 | Unauthorized | Invalid/missing token, session expired |
| 404 | Not Found | Report not found, user not found |
| 405 | Method Not Allowed | Wrong HTTP method used |
| 500 | Internal Server Error | Database error, Firebase error |

### Error Response Format
```json
{
  "error": "Descriptive error message",
  "status": 400
}
```

### Handling Firebase Errors
The system continues to work even if Firebase is unavailable. Reports are saved to MySQL and Firebase sync is attempted separately.

---

## Integration Examples

### 1. Flutter Report Submission

```dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PoliceReportService {
  final String baseUrl;
  final String userToken;
  
  PoliceReportService({required this.baseUrl, required this.userToken});

  Future<Map<String, dynamic>> submitPoliceReport({
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    bool anonymous = false,
    File? mediaFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/users/emergency/submit-police-report/'),
      );
      
      request.headers['Authorization'] = 'Token $userToken';
      request.fields['description'] = description;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['address'] = address;
      request.fields['anonymous'] = anonymous.toString();
      
      if (mediaFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('media', mediaFile.path)
        );
      }
      
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      var jsonResponse = json.decode(responseString);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonResponse,
        };
      } else {
        return {
          'success': false,
          'error': jsonResponse['error'] ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getUserReports() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/emergency/user-reports/'),
        headers: {'Authorization': 'Token $userToken'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['reports']);
      } else {
        throw Exception('Failed to load reports');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
```

### 2. Real-time Status Updates with Firebase

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PoliceReportTracker {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<DocumentSnapshot> listenToReportStatus(String reportId) {
    return _firestore
        .collection('police_reports')
        .doc(reportId)
        .snapshots();
  }
  
  void handleStatusUpdate(DocumentSnapshot snapshot) {
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      String status = data['status'];
      String? officerName = data['assigned_officer_name'];
      String? stationName = data['assigned_station'];
      bool anonymous = data['anonymous'] ?? false;
      
      // Update UI based on status
      switch (status) {
        case 'pending':
          if (anonymous) {
            showNotification('Anonymous report submitted. Awaiting operator verification.');
          } else {
            showNotification('Report submitted to $stationName. Awaiting officer assignment.');
          }
          break;
        case 'accepted':
          showNotification('Officer $officerName has been assigned to your case.');
          break;
        case 'completed':
          showNotification('Case resolved successfully by $officerName.');
          break;
        case 'fraud':
          showNotification('Report has been marked as fraudulent.');
          break;
      }
    }
  }
  
  void showNotification(String message) {
    // Implement your notification logic here
    print('Police Report Update: $message');
  }
}
```

### 3. Anonymous vs Non-Anonymous Reports

```dart
class ReportSubmissionForm extends StatefulWidget {
  @override
  _ReportSubmissionFormState createState() => _ReportSubmissionFormState();
}

class _ReportSubmissionFormState extends State<ReportSubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  File? _selectedMedia;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report Crime')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Crime Description',
                  hintText: 'Describe what happened...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter the address where incident occurred',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.my_location),
                    onPressed: _getCurrentLocation,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide the location';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Media attachment
              Container(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickMedia,
                  icon: Icon(Icons.camera_alt),
                  label: Text(_selectedMedia != null 
                      ? 'Evidence Attached' 
                      : 'Attach Evidence (Optional)'),
                ),
              ),
              SizedBox(height: 16),
              
              // Anonymous checkbox
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CheckboxListTile(
                  title: Text('Submit Anonymously'),
                  subtitle: Text(
                    'Anonymous reports require operator verification before being assigned to police.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  value: _isAnonymous,
                  onChanged: (bool? value) {
                    setState(() {
                      _isAnonymous = value ?? false;
                    });
                  },
                ),
              ),
              SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Submit Report'),
                ),
              ),
              
              if (_isAnonymous) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anonymous reports take longer to process as they require operator verification.',
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _getCurrentLocation() async {
    // Implement location fetching logic
    // Update _addressController and store lat/lng coordinates
  }
  
  void _pickMedia() async {
    // Implement media picker logic
    // Set _selectedMedia file
  }
  
  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        final policeService = PoliceReportService(
          baseUrl: 'http://your-server.com',
          userToken: 'user-token-here',
        );
        
        final result = await policeService.submitPoliceReport(
          description: _descriptionController.text,
          latitude: 23.7461, // Get from location service
          longitude: 90.3742, // Get from location service
          address: _addressController.text,
          anonymous: _isAnonymous,
          mediaFile: _selectedMedia,
        );
        
        if (result['success']) {
          // Navigate to tracking screen or show success
          final reportData = result['data'];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReportTrackingScreen(
                reportId: reportData['report_id'].toString(),
                isAnonymous: _isAnonymous,
              ),
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
```

### 4. Report Tracking Screen

```dart
class ReportTrackingScreen extends StatefulWidget {
  final String reportId;
  final bool isAnonymous;
  
  const ReportTrackingScreen({
    Key? key,
    required this.reportId,
    required this.isAnonymous,
  }) : super(key: key);

  @override
  _ReportTrackingScreenState createState() => _ReportTrackingScreenState();
}

class _ReportTrackingScreenState extends State<ReportTrackingScreen> {
  final PoliceReportTracker _tracker = PoliceReportTracker();
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  Map<String, dynamic>? _currentStatus;

  @override
  void initState() {
    super.initState();
    _setupStatusListener();
  }

  void _setupStatusListener() {
    _statusSubscription = _tracker
        .listenToReportStatus(widget.reportId)
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _currentStatus = snapshot.data() as Map<String, dynamic>;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report #${widget.reportId}'),
      ),
      body: _currentStatus == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status timeline
                  _buildStatusTimeline(),
                  SizedBox(height: 24),
                  
                  // Report details
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report Details',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          SizedBox(height: 8),
                          _buildDetailRow('Status', _getStatusText()),
                          _buildDetailRow('Submitted', _formatTimestamp()),
                          _buildDetailRow('Type', widget.isAnonymous ? 'Anonymous' : 'Registered'),
                          if (_currentStatus!['assigned_station'] != null)
                            _buildDetailRow('Assigned Station', _currentStatus!['assigned_station']),
                          if (_currentStatus!['assigned_officer_name'] != null)
                            _buildDetailRow('Assigned Officer', _currentStatus!['assigned_officer_name']),
                          _buildDetailRow('Description', _currentStatus!['description']),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusTimeline() {
    String status = _currentStatus!['status'];
    String operatorStatus = _currentStatus!['operator_status'] ?? 'registered';
    bool isAnonymous = _currentStatus!['anonymous'] ?? false;

    List<TimelineStep> steps = [];
    
    if (isAnonymous) {
      steps.addAll([
        TimelineStep('Report Submitted', true, 'Anonymous report received'),
        TimelineStep('Operator Review', operatorStatus == 'assigned', 'Awaiting verification'),
        TimelineStep('Police Assignment', status == 'accepted' || status == 'completed', 'Officer assigned'),
        TimelineStep('Case Resolution', status == 'completed', 'Case completed'),
      ]);
    } else {
      steps.addAll([
        TimelineStep('Report Submitted', true, 'Report received'),
        TimelineStep('Police Assignment', status == 'accepted' || status == 'completed', 'Officer assigned'),
        TimelineStep('Case Resolution', status == 'completed', 'Case completed'),
      ]);
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Timeline',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 16),
            ...steps.map((step) => _buildTimelineStep(step)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(TimelineStep step) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: step.isCompleted ? Colors.green : Colors.grey,
          ),
          child: Icon(
            step.isCompleted ? Icons.check : Icons.circle,
            color: Colors.white,
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: step.isCompleted ? Colors.black : Colors.grey,
                ),
              ),
              Text(
                step.description,
                style: TextStyle(
                  color: step.isCompleted ? Colors.black87 : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusText() {
    String status = _currentStatus!['status'];
    switch (status) {
      case 'pending':
        return 'Pending Assignment';
      case 'accepted':
        return 'Officer Assigned';
      case 'completed':
        return 'Case Resolved';
      case 'fraud':
        return 'Marked as Fraudulent';
      default:
        return status.toUpperCase();
    }
  }

  String _formatTimestamp() {
    var timestamp = _currentStatus!['timestamp'];
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString();
    }
    return timestamp.toString();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}

class TimelineStep {
  final String title;
  final bool isCompleted;
  final String description;

  TimelineStep(this.title, this.isCompleted, this.description);
}
```

---

## Testing the API

### 1. Using curl for Testing

```bash
# Test police report submission
curl -X POST \
  -H "Authorization: Token your-token-here" \
  -F "description=Test crime report" \
  -F "latitude=23.7461" \
  -F "longitude=90.3742" \
  -F "address=Test Address, Dhaka" \
  -F "anonymous=false" \
  http://localhost:8000/api/users/emergency/submit-police-report/

# Test getting user reports
curl -X GET \
  -H "Authorization: Token your-token-here" \
  http://localhost:8000/api/users/emergency/user-reports/

# Test police station login
curl -X POST \
  -d "station_id=1234&password=police123" \
  http://localhost:8000/police/login/
```

### 2. Testing with Postman

Create a Postman collection with these requests:

1. **Submit Police Report**
   - Method: POST
   - URL: `{{base_url}}/api/users/emergency/submit-police-report/`
   - Headers: `Authorization: Token {{user_token}}`
   - Body: form-data with required fields

2. **Get Available Officers**
   - Method: GET  
   - URL: `{{base_url}}/police/get-available-officers/`
   - Headers: Session cookies from login

3. **Assign Officer**
   - Method: POST
   - URL: `{{base_url}}/police/assign-officer/`
   - Body: form-data with report_id and officer_id

---

## Conclusion

The Django police module provides a robust foundation for police report management with automatic assignment, officer management, and real-time updates. The system handles both anonymous and non-anonymous reports with appropriate verification workflows.

**Key Features Ready for Flutter Integration**:
- ✅ Report submission with media support
- ✅ Automatic police station assignment
- ✅ Officer assignment system
- ✅ Real-time status updates via Firebase
- ✅ User rating system for trust scoring
- ✅ Anonymous reporting support

**Recommended Next Steps**:
1. Implement missing APIs for police report history
2. Add push notification system
3. Enhance media file handling
4. Add report categories/severity levels
5. Implement officer location tracking

This documentation provides all necessary information for Flutter developers to successfully integrate with the police module backend.
 