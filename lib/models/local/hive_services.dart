import 'package:hive/hive.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:brandify/models/sell.dart';
import 'package:brandify/models/data.dart';
import 'package:brandify/enum.dart';

class HiveServices {

  static Future<void> openUserBoxes() async {
    final email = Cache.getEmail();
    if (email != null) {
      if(!Hive.isBoxOpen(getTableName(productsTable))) {
        await Hive.openBox(getTableName(productsTable));
      }
      if(!Hive.isBoxOpen(getTableName(sellsTable))) {
        await Hive.openBox(getTableName(sellsTable));
      }
      if(!Hive.isBoxOpen(getTableName(extraExpensesTable))) {
        await Hive.openBox(getTableName(extraExpensesTable));
      }
      if(!Hive.isBoxOpen(getTableName(sidesTable))) {
        await Hive.openBox(getTableName(sidesTable));
      }
      if(!Hive.isBoxOpen(getTableName(adsTable))) {
        await Hive.openBox(getTableName(adsTable));
      }
    }
  }

  static String getTableName(String table) {
    final email = Cache.getEmail();
    return "${email}_$table";
  }

  static Future<Data<List<Sell>, Status>> getSellsInDateRange(DateTime fromDate, DateTime toDate) async {
    try {
      final sellsBox = Hive.box(getTableName(sellsTable));
      List<Sell> sells = [];
      for (var key in sellsBox.keys) {
        final sellData = sellsBox.get(key);
        if (sellData == null) continue;
        final sell = Sell.fromJson(Map<String, dynamic>.from(sellData));
        if (sell.date == null) continue;
        // Inclusive range: fromDate <= sell.date <= toDate
        if (sell.date!.isAfter(fromDate.subtract(const Duration(days: 1))) &&
            sell.date!.isBefore(toDate.add(const Duration(days: 1)))) {
          sells.add(sell);
        }
      }
      return Data<List<Sell>, Status>(sells, Status.success);
    } catch (e) {
      return Data<List<Sell>, Status>([], Status.fail);
    }
  }
}