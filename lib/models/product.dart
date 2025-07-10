import 'package:brandify/models/size.dart';
import 'package:intl/intl.dart';

class Product{
  int? id;
  String? backendId;
  int? shopifyId;
  String? code;
  String? sku;
  String? name;
  String? category;
  String? description;
  String? image;
  int? price;
  int? shopifyPrice;
  List<ProductSize> sizes = [];
  int noOfSells = 0;
  DateTime? createdAt;

  Product({this.id, this.shopifyId, this.name, this.description, 
  this.image, this.price, this.noOfSells = 0, this.code}){
    createdAt = DateTime.now();
  }
  Product.fromJson(Map<dynamic, dynamic> json){
    id = json["id"];
    backendId = json["backendId"];
    shopifyId = json["shopifyId"];
    code = json["code"];
    sku = json["sku"];
    name = json["name"];
    category = json["category"];
    description = json["description"];
    image = json["image"];
    price = json["price"];
    shopifyPrice = json["shopifyPrice"];
    noOfSells = json["noOfSells"] ?? 0;
    sizes = json["sizes"] != null ? [for(var x in json["sizes"]) ProductSize.fromJson(x)] : []; 
    createdAt = json["createdAt"] != null? DateTime.parse(json["createdAt"]): null;
  }

  Product.fromShopify(Map<String, dynamic> shopifyProduct) {
    shopifyId = shopifyProduct['id'];
    name = shopifyProduct['title'];
    description = shopifyProduct['body_html'] != null ? 
    shopifyProduct['body_html'].toString() : null;
    image = (shopifyProduct['images']?.isNotEmpty ?? false)
        ? shopifyProduct['images'][0]['src'] 
        : null;
    
    sizes = [];
    if (shopifyProduct['variants'] != null) {
      shopifyPrice = (double.tryParse(shopifyProduct['variants']![0]?['price'] ?? '0') ?? 0).round();
      price = shopifyPrice;
      sku = shopifyProduct['variants']![0]?['sku'];
      code = shopifyProduct['variants']![0]?['barcode'];
      for (var variant in shopifyProduct['variants']) {
        sizes.add(ProductSize(
          id: variant['id'],
          name: variant['title'],
          quantity: int.tryParse(variant['inventory_quantity']?.toString() ?? '0') ?? 0,
        ));
      }
    }
    else{
      price = shopifyPrice = 0;
    }
  }

  Map<String, dynamic> toJson(){
    return {
      "id": id,
      "backendId": backendId,
      "shopifyId": shopifyId,
      "code": code,
      "sku": sku,
      "name": name,
      "category": category,
      "description": description,
      "image": image,
      "price": price,
      "shopifyPrice": shopifyPrice,
      "noOfSells": noOfSells,
      "sizes": [for(var size in sizes) size.toJson()],
      "created_at": createdAt != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt!) : null,
    };
  }

  int getNumberOfAllItems(){
    int total = 0;
    for(var item in sizes){
      total += item.quantity ?? 0;
    }
    return total;
  }
}