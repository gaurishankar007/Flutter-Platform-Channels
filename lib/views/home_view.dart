import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../errors/exception_handler.dart';
import '../widgets/snackbar_message.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final platformChannel = const MethodChannel("flutter.native/helper");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Channels'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => greeting(context),
              child: const Text('Say hello to platform'),
            ),
            const SizedBox(height: 30, width: double.maxFinite),
            ElevatedButton(
              onPressed: () => getBatteryLevel(context),
              child: const Text('Show Battery Level'),
            ),
          ],
        ),
      ),
    );
  }

  greeting(BuildContext context) async {
    exceptionHandler(() async {
      final argument = {"name": "Flutter"};
      final String response = await platformChannel.invokeMethod('greeting', argument);
      if (context.mounted) {
        showSnackBar(
          context,
          message: response,
          color: Colors.green,
        );
      }
    }, context);
  }

  getBatteryLevel(BuildContext context) async {
    exceptionHandler(() async {
      final int batteryLevel = await platformChannel.invokeMethod('getBatteryLevel');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog.adaptive(
              title: const Text('Battery Level'),
              content: Row(
                children: [
                  const Icon(Icons.battery_full, color: Colors.green),
                  const SizedBox(width: 10),
                  Text('$batteryLevel%'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    }, context);
  }
}
