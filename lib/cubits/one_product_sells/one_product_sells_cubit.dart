import 'package:bloc/bloc.dart';
import 'package:brandify/models/local/hive_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/models/sell.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/models/firebase/firestore/sells_services.dart';
import 'package:brandify/models/firebase/firestore/shopify_services.dart';
import 'package:brandify/enum.dart';

part 'one_product_sells_state.dart';

class OneProductSellsCubit extends Cubit<OneProductSellsState> {
  List<Sell> sells = [];

  OneProductSellsCubit() : super(OneProductSellsInitial());
  static OneProductSellsCubit get(BuildContext context) => BlocProvider.of(context);

  List<Sell> filteredSells = [];

  Future<void> getAllSellsOfProductInDateRange(Product product, DateTime fromDate, DateTime toDate, {bool isFirstTime = false}) async {
    emit(OneProductSellsChangedState());
    List<Sell> resultSells = [];

    if (Package.type == PackageType.shopify && product.shopifyId != null) {
      // Shopify orders for this product in date range
      final shopifyOrders = await ShopifyServices().getProductSellsInDateRange(
        productShopifyId: product.shopifyId!,
        fromDate: fromDate,
        toDate: toDate,
      );
      resultSells = shopifyOrders
        .map((order) => Sell.fromShopifyOrder(order, [product]))
        .toList();

      // Fetch from Firebase
        final firebaseResult = await SellsServices().getSellsInDateRange(fromDate, toDate);
        if (firebaseResult.status == Status.success) {
          resultSells.addAll((firebaseResult.data as List<Sell>).where((sell) {
            final sellProduct = sell.product;
            bool matches = false;
            if (product.shopifyId != null && sellProduct?.shopifyId != null && product.shopifyId == sellProduct!.shopifyId) {
              matches = true;
            } else if (product.backendId != null && sellProduct?.backendId != null && product.backendId == sellProduct!.backendId) {
              matches = true;
            } else if (product.id != null && sellProduct?.id != null && product.id == sellProduct!.id) {
              matches = true;
            }
            return matches;
          }).toList());
        }

    } else {
      if (Package.type == PackageType.online) {
        // Fetch from Firebase
        final firebaseResult = await SellsServices().getSellsInDateRange(fromDate, toDate);
        if (firebaseResult.status == Status.success) {
          resultSells = (firebaseResult.data as List<Sell>).where((sell) {
            final sellProduct = sell.product;
            bool matches = false;
            if (product.shopifyId != null && sellProduct?.shopifyId != null && product.shopifyId == sellProduct!.shopifyId) {
              matches = true;
            } else if (product.backendId != null && sellProduct?.backendId != null && product.backendId == sellProduct!.backendId) {
              matches = true;
            } else if (product.id != null && sellProduct?.id != null && product.id == sellProduct!.id) {
              matches = true;
            }
            return matches;
          }).toList();
        }
      } else {
        // Fetch from cache
        final cachedSells = await HiveServices.getSellsInDateRange(fromDate, toDate);
        if (cachedSells.status == Status.success) {
          resultSells = cachedSells.data.where((sell) {
            final sellProduct = sell.product;
            bool matches = false;
            if (product.shopifyId != null && sellProduct?.shopifyId != null && product.shopifyId == sellProduct!.shopifyId) {
              matches = true;
            } else if (product.backendId != null && sellProduct?.backendId != null && product.backendId == sellProduct!.backendId) {
              matches = true;
            } else if (product.id != null && sellProduct?.id != null && product.id == sellProduct!.id) {
              matches = true;
            }
            return matches;
          }).toList();
        }
      }
    }

    if(isFirstTime){
      sells = resultSells;
      filteredSells = List.from(sells);
    }
    else{
      filteredSells = resultSells;
    }
    filteredSells.sort((a, b) => b.date!.compareTo(a.date!));
    emit(OneProductSellsSuccess());
  }

  void filterByDate(DateTime startDate, DateTime endDate) {
    print("filterByDate");
    print(startDate);
    
    print(endDate);
    filteredSells = sells.where((sell) {
      print("Sell date: ${sell.date}");
      return sell.date != null &&
          sell.date!.isAfter(startDate.subtract(Duration(days: 1))) &&
          sell.date!.isBefore(endDate.add(Duration(days: 1)));
    }).toList();
    print(sells);
    //filteredSells.sort((a, b) => b.date!.compareTo(a.date!));
    emit(OneProductSellsSuccess());
  }

  void clearFilter() {
    filteredSells = List.from(sells);
    filteredSells.sort((a, b) => b.date!.compareTo(a.date!));
    emit(OneProductSellsSuccess());
  }
}
