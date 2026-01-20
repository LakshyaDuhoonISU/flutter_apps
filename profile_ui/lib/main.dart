import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      title:"Profile UI",
      initialRoute: "/",
      routes: {
        "/": (context) => HomePage(),
        "/profile": (context) => ProfileScreen(),
        "/about": (context) => AboutMe()
      },
    );
  }
}

class HomePage extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text("Home Page")
      ),
      body:Center(
        child:Column(
          children:[
            Text("Welcome to My Profile App"),
            Text("Tap on the Profile button to view my profile page"),
            Text("Tap on the About Me button to know more about me"),
            Row(
              children: [
                TextButton(onPressed: () {
                  Navigator.pushNamed(context, "/profile");
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),child: Text("Profile")
                ),
                TextButton(onPressed: () {
                  Navigator.pushNamed(context, "/about");
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                )
                , child: Text("About Me")),
              ]
            )
          ],
        )
      )
    );
  }
}

class ProfileScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text("My Profile")
      ),
      body:Center(
        child:Column(
          children: [
            Image.asset("assets/boy.png", width: 100, height: 100),
            Text("Hello, My name is ABC", style:TextStyle(color: Colors.blue, fontSize: 20) ),
            Text("I am a Flutter Developer", style:TextStyle(fontSize:18)),
            Text("I love to develop web apps", style:TextStyle(fontSize:16)),
            Row(
              children:[
                TextButton(onPressed: () {
                  Navigator.pushNamed(context, "/");
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ), child: Text("Home")
                ),
                TextButton(onPressed: () {
                  Navigator.pushNamed(context, "/about");
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ), child: Text("About Me")),
              ]
            )
          ]
        )
      )
    );
  }
}

class AboutMe extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title: Text("About Me"),
      ),
      body: Center(
        child: Column(
          children: [
            Text("Name: John"),
            Text("Age: 25"),
            Text("Gender: Male"),
            Text("Favourite Programming Language: Dart"),
            Text("Hobbies: Coding, Reading, Traveling"),
            Text("Favourtie IDE: VS Code"),
            Row(
              children:[
                TextButton(onPressed: () {
                  Navigator.pushNamed(context, "/");
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ), child: Text("Home")
                ),
                TextButton(onPressed: () {
                  Navigator.pushNamed(context, "/profile");
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ), child: Text("Profile")),
              ]
            )
          ],
        ),
      ),
    );
  }
}