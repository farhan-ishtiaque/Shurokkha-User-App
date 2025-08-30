import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';

class EmergencyController {
  final int userId;
  final CameraController cameraController;

  EmergencyController({required this.userId, required this.cameraController});

  Future<void> triggerEmergency() async {
    await sendEmergencyToBackend();
    await notifyEmergencyContacts();
    await startLocationUpdates();
    await startVideoRecording();
  }

  Future<void> sendEmergencyToBackend() async {
    final pos = await Geolocator.getCurrentPosition();
    final uri = Uri.parse('https://your-backend.com/api/alert/');
    await http.post(uri, body: {
      'user_id': userId.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'latitude': pos.latitude.toString(),
      'longitude': pos.longitude.toString(),
    });
  }

  Future<void> notifyEmergencyContacts() async {
    // Placeholder: You’ll use url_launcher later to open SMS
    print("Notify emergency contacts");
  }

  Future<void> startLocationUpdates() async {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      await http.post(
        Uri.parse('https://your-backend.com/api/location/'),
        body: {
          'user_id': userId.toString(),
          'lat': position.latitude.toString(),
          'lng': position.longitude.toString(),
        },
      );
    });
  }

  Future<void> startVideoRecording() async {
    if (!cameraController.value.isInitialized) return;
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/emergency_${DateTime.now().millisecondsSinceEpoch}.mp4';
    await cameraController.startVideoRecording();
    // Save file path for later upload
    print('Recording started: $filePath');
  }

  Future<void> stopVideoRecording() async {
    final file = await cameraController.stopVideoRecording();
    await uploadVideo(file.path);
  }

  Future<void> uploadVideo(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://your-backend.com/api/upload_video/'),
    );
    request.files.add(await http.MultipartFile.fromPath('video', filePath));
    request.fields['user_id'] = userId.toString();
    await request.send();
  }
}
