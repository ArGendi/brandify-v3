import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/models/sell.dart';

part 'one_product_sells_state.dart';

class OneProductSellsCubit extends Cubit<OneProductSellsState> {
  List<Sell> sells = [];

  OneProductSellsCubit() : super(OneProductSellsInitial());
  static OneProductSellsCubit get(BuildContext context) => BlocProvider.of(context);

  List<Sell> filteredSells = [];

  void getAllSellsOfProduct(List<Sell> allSells, Product product) {
    print('=== getAllSellsOfProduct Debug ===');
    print('Product IDs - id: ${product.id}, backendId: ${product.backendId}, shopifyId: ${product.shopifyId}');
    print('Total sells to filter: ${allSells.length}');
    
    sells = allSells.where((sell) {
      if (sell.product == null) {
        print('Sell ${sell.id} has no product, skipping');
        return false;
      }
      
      final sellProduct = sell.product!;
      print('Checking sell ${sell.id} - Product IDs: id: ${sellProduct.id}, backendId: ${sellProduct.backendId}, shopifyId: ${sellProduct.shopifyId}');
      
      // Check all three ID types for matching
      bool matches = false;
      
      // 1. Check shopifyId (highest priority for Shopify products)
      if (product.shopifyId != null && sellProduct.shopifyId != null) {
        if (product.shopifyId == sellProduct.shopifyId) {
          print('  ✓ Matched by shopifyId: ${product.shopifyId}');
          matches = true;
        }
      }
      
      // 2. Check backendId (for backend-synced products)
      if (!matches && product.backendId != null && sellProduct.backendId != null) {
        if (product.backendId == sellProduct.backendId) {
          print('  ✓ Matched by backendId: ${product.backendId}');
          matches = true;
        }
      }
      
      // 3. Check local id (fallback for local products)
      if (!matches && product.id != null && sellProduct.id != null) {
        if (product.id == sellProduct.id) {
          print('  ✓ Matched by local id: ${product.id}');
          matches = true;
        }
      }
      
      if (!matches) {
        print('  ✗ No ID match found');
      }
      
      return matches;
    }).toList();
    
    print('Found ${sells.length} matching sells');
    print('=== End Debug ===');
    
    filteredSells = List.from(sells);
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
