import 'package:objectbox/objectbox.dart';

@Entity()
class User {
  int id;
  String name;
  String price;
  String date;
  User({this.id = 0, required this.name,required this.price, required this.date});
}