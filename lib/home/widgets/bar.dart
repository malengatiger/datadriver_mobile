import 'package:flutter/material.dart';

class Bar extends StatelessWidget {
  const Bar({Key? key, required this.title, required this.body}) : super(key: key);
  final String title;
  final Widget body;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        key: key,
        title: Text(title),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.logout)),
        ],
      ),
      body: body,
    );
  }
}
