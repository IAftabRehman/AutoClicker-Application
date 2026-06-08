import 'package:flutter/material.dart';
import '../../../core/native_bridge/native_bridge.dart';

class TestPlaygroundScreen extends StatefulWidget {
  const TestPlaygroundScreen({super.key});

  @override
  State<TestPlaygroundScreen> createState() => _TestPlaygroundScreenState();
}

class _TestPlaygroundScreenState extends State<TestPlaygroundScreen> {
  int _tapCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bot Click Testing Area')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _tapCount++;
                });
              },
              borderRadius: BorderRadius.circular(100),
              child: Container(
                height: 200,
                width: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$_tapCount',
                  style: const TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                await NativeBridge().startOverlay();
              },
              child: const Text('Open Bot Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
