import "package:flutter/material.dart";
import "dart:async";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(title: "Digital Clock", home: DigitalClockScreen());
  }
}

class DigitalClockScreen extends StatefulWidget {
  DigitalClockScreenState createState() => DigitalClockScreenState();
}

class DigitalClockScreenState extends State<DigitalClockScreen> {
  String time = "";

  void initState() {
    super.initState();

    setState(() {
      time = DateTime.now().toString();
    });

    Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        time = DateTime.now().toString();
      });
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Digital Clock")),
      body: Center(child: Text(time)),
    );
  }
}
