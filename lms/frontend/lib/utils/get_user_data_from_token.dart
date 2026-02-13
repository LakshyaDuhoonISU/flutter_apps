import 'package:jwt_decode/jwt_decode.dart';
import '../models/user.dart';

User getUserDataFromToken(String token) {
  Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
      print("Decoded Token: $decodedToken");
      User user = User(
        id: decodedToken['id'],
        name: decodedToken['name'],
        username: decodedToken['username'],
        email: decodedToken['email'],
        password: '',
        userType: decodedToken['userType']
      );
      return user;
}