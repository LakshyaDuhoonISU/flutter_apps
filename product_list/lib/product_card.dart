import 'package:flutter/material.dart';
import 'product_detail.dart';
import 'rating_box.dart';

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
            Image.asset(this.image,width:100,height:100),
            Column(
              children: [
                Text(this.name),
                Text(this.description),
                Text(this.price),
                RatingBox(),
                TextButton(
                    child: Text("View Details"),
                    onPressed: (){
                      Navigator.pushNamed(context, "/product_detail",arguments: Product(name:this.name,description:this.description,price:this.price,image:this.image));
                    },
                )
              ],
            )
          ],
        )
      )
    );
  }
}