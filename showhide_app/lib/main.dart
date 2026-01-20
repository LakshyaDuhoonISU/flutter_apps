import "package:flutter/material.dart";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(title: "Show Hide App", home: ShowHideAppScreen());
  }
}

class ShowHideAppScreen extends StatefulWidget {
  ShowHideAppScreenState createState() => ShowHideAppScreenState();
}

class ShowHideAppScreenState extends State<ShowHideAppScreen> {
  bool visible = true;

  void show() {
    setState(() {
      visible = true;
    });
  }

  void hide() {
    setState(() {
      visible = false;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Show Hide App")),
      body: Column(
        children: [
          visible ? Text("We are coder...") : Container(),
          IconButton(icon: Icon(Icons.visibility), onPressed: show),
          IconButton(icon: Icon(Icons.visibility_off), onPressed: hide),
        ],
      ),
    );
  }
}
