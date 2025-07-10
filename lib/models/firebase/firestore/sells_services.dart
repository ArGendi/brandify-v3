import 'package:brandify/constants.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/data.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:brandify/models/sell.dart';

class SellsServices extends FirestoreServices{
  Future<Data<dynamic, Status>> getSells() async{
    try{
      var snapshot = await docRef.collection(sellsTable).get();
      List<Sell> sells = [];
      for(var doc in snapshot.docs){
        Map<String, dynamic> map = doc.data();
        var temp = Sell.fromJson(map);
        temp.backendId = doc.id;
        sells.add(temp);
      }
      return Data<List<Sell>, Status>(sells, Status.success);
    }
    catch(e){
      return Data<String, Status>(e.toString(), Status.fail);
    }
  }

  Future<Data<dynamic, Status>> getSellsInDateRange(DateTime fromDate, DateTime toDate) async {
    try {
      print("from: $fromDate");
      print("To: $toDate");
      // Convert dates to Firestore Timestamp format
      var fromTimestamp = DateTime(fromDate.year, fromDate.month, fromDate.day-1);
      var toTimestamp = DateTime(toDate.year, toDate.month, toDate.day,);

      print("from: $fromTimestamp");
      print("To: $toTimestamp");
      
      var snapshot = await docRef
          .collection(sellsTable)
          .where('date', isGreaterThanOrEqualTo: fromTimestamp.toIso8601String())
          .where('date', isLessThanOrEqualTo: toTimestamp.toIso8601String())
          .get();
      
      print("Doooooooocs length: ${snapshot.docs.length}");
      List<Sell> sells = [];
      for(var doc in snapshot.docs){
        Map<String, dynamic> map = doc.data();
        var temp = Sell.fromJson(map);
        temp.backendId = doc.id;
        sells.add(temp);
      }
      return Data<List<Sell>, Status>(sells, Status.success);
    }
    catch(e){
      return Data<String, Status>(e.toString(), Status.fail);
    }
  }

  Future<Data<List<Sell>, Status>> getProductSellsFromFirebase({
    required int? productId,
    String? backendId,
    int? shopifyId,
  }) async {
    try {
      var snapshot = await docRef.collection(sellsTable).get();
      List<Sell> sells = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> map = doc.data();
        var temp = Sell.fromJson(map);
        temp.backendId = doc.id;

        // Match by shopifyId, backendId, or id
        final sellProduct = temp.product;
        bool matches = false;
        if (shopifyId != null && sellProduct?.shopifyId != null && shopifyId == sellProduct!.shopifyId) {
          matches = true;
        } else if (backendId != null && sellProduct?.backendId != null && backendId == sellProduct!.backendId) {
          matches = true;
        } else if (productId != null && sellProduct?.id != null && productId == sellProduct!.id) {
          matches = true;
        }

        if (matches) {
          sells.add(temp);
        }
      }
      return Data<List<Sell>, Status>(sells, Status.success);
    } catch (e) {
      return Data<List<Sell>, Status>([], Status.fail);
    }
  }
}