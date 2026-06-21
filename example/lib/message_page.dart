import 'package:flutter/material.dart';

/// Minimal placeholder screen so every route has something to render. The
/// example exists to demonstrate the builder, not the UI.
class MessagePage extends StatelessWidget {
  const MessagePage(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
