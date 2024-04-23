import 'package:flutter/material.dart';

class IOSChannelView extends StatefulWidget {
  const IOSChannelView({super.key});
  @override
  State<IOSChannelView> createState() => _IOSChannelViewState();
}

class _IOSChannelViewState extends State<IOSChannelView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IOS Channel'),
      ),
      body: const SafeArea(
        child: Column(
          children: [],
        ),
      ),
    );
  }
}
