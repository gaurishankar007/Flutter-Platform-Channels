import 'package:flutter/material.dart';

class AndroidChannelView extends StatefulWidget {
  const AndroidChannelView({super.key});
  @override
  State<AndroidChannelView> createState() => _AndroidChannelViewState();
}

class _AndroidChannelViewState extends State<AndroidChannelView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Android Channel'),
      ),
      body: const SafeArea(
        child: Column(
          children: [],
        ),
      ),
    );
  }
}
