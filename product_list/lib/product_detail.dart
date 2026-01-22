import 'package:flutter/material.dart';

class Product{
    final String name;
    final String description;
    final String price;
    final String image;

    Product({required this.name, required this.description, required this.price, required this.image});
}

class ProductDetail extends StatelessWidget{

    Widget build(BuildContext context){

        final Product product = ModalRoute.of(context)!.settings.arguments as Product;
        
        return Scaffold(
            appBar:AppBar(
                title:Text("Product Detail Screen")
            ),
            body:Center(
                child:Column(
                    children:[
                        Image.asset(product.image),
                        Text(product.name),
                        Text(product.description),
                        Text(product.price)
                    ]
                )
            )
        );
    }
}