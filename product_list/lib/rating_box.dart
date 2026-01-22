import 'package:flutter/material.dart';

class RatingBox extends StatefulWidget{
  RatingBoxState createState() => RatingBoxState();
}

class RatingBoxState extends State<RatingBox> {
  int rating = 0;

  void setOneStar() {
    setState(() {
      rating = 1;
    });
  }

  void setTwoStar() {
    setState(() {
      rating = 2;
    });
  }

  void setThreeStar() {
    setState(() {
      rating = 3;
    });
  }

  void setFourStar() {
    setState(() {
      rating = 4;
    });
  }

  void setFiveStar() {
    setState(() {
      rating = 5;
    });
  }

  Widget build(BuildContext context) {

    return Row(
      children: [
        Container(
          child: IconButton(
            icon: (rating >= 1 ? Icon(Icons.star) : Icon(Icons.star_border)),
            color: Colors.amber,
            onPressed: setOneStar
          ),
        ),
        Container(
          child: IconButton(
            icon: (rating >= 2 ? Icon(Icons.star) : Icon(Icons.star_border)),
            color: Colors.amber,
            onPressed: setTwoStar
          ),
        ),
        Container(
          child: IconButton(
            icon: (rating >= 3 ? Icon(Icons.star) : Icon(Icons.star_border)),
            color: Colors.amber,
            onPressed: setThreeStar
          ),
        ),
        Container(
          child: IconButton(
            icon: (rating >= 4 ? Icon(Icons.star) : Icon(Icons.star_border)),
            color: Colors.amber,
            onPressed: setFourStar
          ),
        ),
        Container(
          child: IconButton(
            icon: (rating >= 5 ? Icon(Icons.star) : Icon(Icons.star_border)),
            color: Colors.amber,
            onPressed: setFiveStar
          ),
        ),
      ],
    );
  }
}