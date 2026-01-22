import 'package:flutter/material.dart';
import 'product_detail.dart';
import 'product_card.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Product List",
      initialRoute: "/",
      routes: {
        "/": (context) => ProductListScreen(),
        "/product_detail": (context) => ProductDetail(),
      },
    );
  }
}

class ProductListScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          ProductCard(
            name: "Apple",
            description: "A red apple",
            price: "\$1.00",
            image: "assets/apple.png",
          ),
          ProductCard(
            name: "Banana",
            description: "A ripe banana",
            price: "\$0.50",
            image: "assets/banana.png",
          ),
          ProductCard(
            name: "Grapes",
            description: "A bunch of grapes",
            price: "\$2.00",
            image: "assets/grapes.png",
          ),
          ProductCard(
            name: "Watermelon",
            description: "A juicy watermelon",
            price: "\$3.00",
            image: "assets/watermelon.png",
          ),
        ],
      ),
    );
  }
}
