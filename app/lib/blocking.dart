import 'package:flutter/material.dart';

class Blocking extends StatefulWidget {
  @override
  _BlockingState createState() => _BlockingState();
}

class _BlockingState extends State<Blocking> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Icon(
          Icons.block, // You can replace this with any other icon
          size: 100.0, // You can adjust the size of the icon
          color: Colors.red, // You can customize the icon color
        ),
      ),
    );
  }
}