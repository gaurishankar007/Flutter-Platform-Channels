import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';

import '../controllers/platform_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _platformController = PlatformController();
  StreamSubscription<String>? _streamSubscription;
  final ValueNotifier<String> _valueNotifier = ValueNotifier("");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Platform Channels',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Method Channel',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final data = await _platformController.greeting();
                if (data.$1 != null) {
                  _showSuccess("${data.$1}");
                } else if (data.$2 != null) {
                  _showError(data.$2!);
                }
              },
              child: const Text('Say hello to platform'),
            ),
            const SizedBox(height: 20, width: double.maxFinite),
            ElevatedButton(
              onPressed: () async {
                final data = await _platformController.getBatteryLevel();
                if (data.$1 != null) {
                  _showSuccess("Battery Level: ${data.$1}");
                } else if (data.$2 != null) {
                  _showError(data.$2!);
                }
              },
              child: const Text('Show Battery Level'),
            ),
            const SizedBox(height: 50),
            Text(
              'Event Channel',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder(
              valueListenable: _valueNotifier,
              builder: (context, value, child) {
                return RichText(
                  text: TextSpan(
                    text: "Time:",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _receiveEvents,
              child: const Text('Receive Events'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _stopEvents,
              child: const Text('Stop Events'),
            ),
          ],
        ),
      ),
    );
  }

  _receiveEvents() {
    _streamSubscription = _platformController.getEventStream().listen(
      (event) => _valueNotifier.value = event,
    );
  }

  _stopEvents() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _valueNotifier.value = "";
  }

  _showSuccess(String message) {
    InteractiveToast.slide(
      context,
      title: Text(message),
      trailing: const Icon(
        Icons.check_circle_rounded,
        color: Colors.green,
        size: 20,
      ),
    );
  }

  _showError(String message) {
    InteractiveToast.slide(
      context,
      title: Text(message),
      trailing: const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
    );
  }
}
