import 'package:flutter/material.dart';

void main() {
  runApp(
    MyApp(),
  ); // function to run first screen (need to send a constructor as a parameter)
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      // MaterialApp is from the first line from material.dart package
      title: "Counter App", // Title of the screen
      home: CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  CounterScreenState createState() => CounterScreenState();
}

class CounterScreenState extends State<CounterScreen> {
  int count = 0;

  void increment() {
    setState(() {
      count++;
    });
  }

  void decrement() {
    setState(() {
      count--;
    });
  }

  void reset() {
    setState(() {
      count = 0;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold defines the structure of the screen
      appBar: AppBar(
        // AppBar is the top bar of the screen
        title: Text("Counter"), // Title in the AppBar
      ),
      body: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Center the content vertically
        children: [
          Text("Count Value :- $count"),
          IconButton(
            // Button to increment the count
            icon: Text("Increment"),
            onPressed: increment,
          ),
          IconButton(
            // Button to decrement the count
            icon: Text("Decrement"),
            onPressed: decrement,
          ),
          IconButton(
            // Button to reset the count
            icon: Text("Reset"),
            onPressed: reset,
          ),
        ],
      ), // Body of the screen showing the count
    );
  }
}
