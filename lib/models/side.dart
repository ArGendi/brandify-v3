import 'package:intl/intl.dart';

class Side{
  int? id;
  String? backendId;
  String? name;
  int? price;
  int? quantity;
  DateTime? createdAt;

  Side({this.id, this.backendId, this.name, this.price, this.quantity}){
    createdAt = DateTime.now();
  }
  Side.fromJson(Map<dynamic, dynamic> json){
    id = json["id"];
    backendId = json["backendId"];
    name = json["name"];
    price = json["price"];
    quantity = json["quantity"];
    createdAt = json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null;
  }

  Map<String, dynamic> toJson(){
    return {
      "id": id,
      "backendId": backendId,
      "name": name,
      "price": price,
      "quantity": quantity,
      "created_at": createdAt != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt!) : null,
    };
  }
}