import "package:flutter/material.dart";
import "dart:async";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(title: "Stop Clock", home: StopWatchScreen());
  }
}

class StopWatchScreen extends StatefulWidget {
  StopWatchScreenState createState() => StopWatchScreenState();
}

class StopWatchScreenState extends State<StopWatchScreen> {
  int hours = 0;
  int minutes = 0;
  int seconds = 0;
  Timer? timer;

  void start() {
    if (timer == null || !timer!.isActive) {
      timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
        setState(() {
          seconds++;
          if (seconds == 60) {
            seconds = 0;
            minutes++;
            if (minutes == 60) {
              minutes = 0;
              hours++;
            }
          }
        });
      });
    }
  }

  void stop() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
      timer = null;
    }
  }

  void reset() {
    stop();
    setState(() {
      hours = 0;
      minutes = 0;
      seconds = 0;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Stop Watch")),
      body: Column(
        children: [
          Text("Stop Watch"),
          Text("$hours:$minutes:$seconds"),
          IconButton(icon: Icon(Icons.play_arrow), onPressed: start),
          IconButton(icon: Icon(Icons.stop), onPressed: stop),
          IconButton(icon: Icon(Icons.refresh), onPressed: reset),
        ],
      ),
    );
  }
}
