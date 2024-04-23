import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/ios');
              },
              child: const Text('IOS Channel'),
            ),
            const SizedBox(height: 30, width: double.maxFinite),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/android');
              },
              child: const Text('Android Channel'),
            ),
          ],
        ),
      ),
    );
  }
}
