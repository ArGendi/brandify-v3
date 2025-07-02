import 'package:brandify/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/models/sell_side.dart';
import 'package:brandify/models/side.dart';
import 'package:brandify/models/size.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Sell{
  int? id;
  String? backendId;
  int? shopifyId;
  Product? product;
  DateTime? date;
  int? quantity;
  int profit = 0;
  int? priceOfSell;
  int extraExpenses = 0;
  List<SellSide> sideExpenses = [];
  ProductSize? size;
  bool isRefunded = false;
  SellPlace? place;
  DateTime? createdAt;
  String? status;

  Sell({this.id, this.backendId, this.product, this.date, this.quantity, this.priceOfSell, 
    this.profit = 0, this.sideExpenses = const [], this.extraExpenses = 0, this.size,
    this.place}){
      createdAt = DateTime.now();
    }

  Sell.fromJson(Map<dynamic, dynamic> json){
    id = json["id"];
    backendId = json["backendId"];
    shopifyId = json["shopifyId"];
    product = Product.fromJson(json["product"]);
    date = DateTime.parse(json["date"]);
    quantity = json["quantity"];
    profit = json["profit"];
    priceOfSell = json["priceOfSell"];
    sideExpenses = [for(var item in json["sideExpenses"]) SellSide.fromJson(item)];
    extraExpenses = json["extraExpenses"];
    size = ProductSize.fromJson(json["size"]);
    isRefunded = json["isRefunded"] ?? false;
    place = convertPlaceFromString(json["place"]);
    createdAt = json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null;
  }

  Sell.fromShopifyOrder(Map<String, dynamic> order, List<Product> allProducts) {
    shopifyId = order['id'];
    date = DateTime.parse(order['created_at']);
    status = order['financial_status'];
    
    if (order['line_items']?.isNotEmpty == true) {
      final lineItem = order['line_items'][0];
      quantity = lineItem['quantity'];
      priceOfSell = (double.parse(lineItem['price'])).round() - (double.parse(lineItem['total_discount'])).round();
      
      // Find matching product from allProducts list
      // product = Product(
      //   shopifyId : lineItem['product_id'],
      //   name: lineItem['title'],
      // );
      product = _findProductByShopifyId(lineItem['product_id'], allProducts);
      size = ProductSize(name: lineItem['variant_title']);
      
      // Calculate profit
      if (product?.price != null) {
        profit = priceOfSell! - (product!.price! * quantity!);
      }
    }

    // Set default values
    sideExpenses = [];
    extraExpenses = 0;
    isRefunded = order['financial_status'] == 'refunded';
    place = SellPlace.online;
  }

  Product? _findProductByShopifyId(int shopifyId, List<Product> products) {
    try {
      return products.firstWhere(
        (product) => product.shopifyId == shopifyId,
        orElse: () => throw Exception('Product not found'),
      );
    } catch (e) {
      debugPrint('Error finding product with Shopify ID $shopifyId: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson(){
    return {
      "id": id,
      "backendId": backendId,
      "shopifyId": shopifyId,
      "product": product?.toJson(),
      "date": DateFormat('yyyy-MM-dd HH:mm:ss').format(date!),
      "quantity": quantity,
      "profit": profit,
      "priceOfSell": priceOfSell,
      "sideExpenses": [for(var item in sideExpenses) item.toJson()],
      "extraExpenses": extraExpenses,
      "size": size?.toJson(),
      "isRefunded": isRefunded,
      "place": getPlace(),
      "created_at": createdAt != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt!) : null,
    };
  }

  String getAllSideExpenses(){
    String temp = "";
    for(var item in sideExpenses){
      temp += "${item.usedQuantity} ${item.side?.name}, ";
    }
    return temp;
  }

  String getPlace(){
    switch(place){
      case SellPlace.online: return "Online";
      case SellPlace.store: return "Store";
      case SellPlace.inEvent: return "In event";
      default: return "Other";
    }
  }

  SellPlace convertPlaceFromString(String value){
    switch(value){
      case "Online": return SellPlace.online;
      case "Store": return SellPlace.store;
      case "In event": return SellPlace.inEvent;
      default: return SellPlace.other;
    }
  }
}