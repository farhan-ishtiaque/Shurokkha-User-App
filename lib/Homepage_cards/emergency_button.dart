import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../controllers/emergency_controller.dart';

class EmergencyButtonPage extends StatefulWidget {
  const EmergencyButtonPage({super.key});

  @override
  State<EmergencyButtonPage> createState() => _EmergencyButtonPageState();
}

class _EmergencyButtonPageState extends State<EmergencyButtonPage> {
  int _secondsRemaining = 10;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 1) {
        timer.cancel();
        _onTimerFinished();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _onTimerFinished() async {
    print('Emergency triggered.');

    // Initialize camera
    final cameras = await availableCameras();
    final camera = cameras.first;
    final controller = CameraController(camera, ResolutionPreset.medium);
    await controller.initialize();

    final emergency = EmergencyController(
      userId: 1001,
      cameraController: controller,
    );
    await emergency.triggerEmergency();

    Navigator.of(context).pop(); // Or navigate to a “Monitoring” screen
  }

  void _cancelEmergency() {
    print('Emergency cancelled!');
    _countdownTimer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: Colors.redAccent,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_secondsRemaining',
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 20,
                  ),
                  textStyle: const TextStyle(fontSize: 24),
                ),
                onPressed: _cancelEmergency,
                child: const Text(
                  'TAP TO CANCEL',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
