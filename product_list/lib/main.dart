import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
  return MaterialApp(
    title:"Product List",
    home:ProductListScreen(),
  );
  }
}

class ProductListScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          ProductCard(
            name:"Apple",
            description:"A red apple",
            price:"\$1.00",
            image:"assets/apple.png"
          ),
          ProductCard(
            name:"Banana",
            description:"A ripe banana",
            price:"\$0.50",
            image:"assets/banana.png"
          ),
          ProductCard(
            name:"Grapes",
            description:"A bunch of grapes",
            price:"\$2.00",
            image:"assets/grapes.png"
          ),
          ProductCard(
            name:"Watermelon",
            description:"A juicy watermelon",
            price:"\$3.00",
            image:"assets/watermelon.png"
          )
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  ProductCard({Key? key, required this.name, required this.description, required this.price, required this.image}): super(key:key);

  final String name;
  final String description;
  final String price;
  final String image;

  Widget build(BuildContext context) {
    return Card(
      child:Container(
        child:Row(
          children: [
            Image.asset(this.image, width: 100, height: 100),
            Column(
              children: [
                Text(this.name),
                Text(this.description),
                Text(this.price)
              ],
            )
          ],
        )
      )
    );
  }
}