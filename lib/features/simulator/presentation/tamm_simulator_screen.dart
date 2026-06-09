import 'package:flutter/material.dart';

enum SimState { setup, retryScreen, successScreen }

class TammSimulatorScreen extends StatefulWidget {
  const TammSimulatorScreen({super.key});

  @override
  State<TammSimulatorScreen> createState() => _TammSimulatorScreenState();
}

class _TammSimulatorScreenState extends State<TammSimulatorScreen> {
  SimState _currentState = SimState.setup;
  bool _isLoading = false;

  void _onNextClicked() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _currentState = SimState.retryScreen;
    });
  }

  void _onNextLongPressed() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _currentState = SimState.successScreen;
    });
  }

  void _onBackClicked() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _currentState = SimState.setup;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case SimState.setup:
        return _buildSetupScreen();
      case SimState.retryScreen:
        return _buildRetryScreen();
      case SimState.successScreen:
        return _buildSuccessScreen();
    }
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Appointment Option'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select an option:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.arrow_forward),
                  title: const Text('Advance'),
                  tileColor: Colors.grey.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Postpone'),
                  tileColor: Colors.grey.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {},
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onNextClicked,
                    onLongPress: _isLoading ? null : _onNextLongPressed,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Next'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildRetryScreen() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: _onBackClicked,
        ),
        title: const Text('Error'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Request Cannot be Processed',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Pick your preferred appointment date',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
