import 'package:bloc/bloc.dart';
import 'package:brandify/cubits/reports/reports_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:brandify/cubits/all_sells/all_sells_cubit.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/models/product_sells.dart';
import 'package:brandify/models/sell.dart';
import 'package:brandify/utils/date_utils.dart';
part 'best_products_state.dart';

class BestProductsCubit extends Cubit<BestProductsState> {
  List<ProductSells> bestProducts = [];
  DateTimeRange? selectedDateRange;
  String sortBy = 'quantity';  // Add this field

  BestProductsCubit() : super(BestProductsInitial());
  static BestProductsCubit get(BuildContext context) => BlocProvider.of(context);


  Future<void> selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );
    if (picked != null) {
      selectedDateRange = picked;
      _calculateBestProducts(context);
      emit(BestProductsChangedState());
    }
  }

  Future<void> _calculateBestProducts(BuildContext context) async{
    if (selectedDateRange == null) return;

    final sells = context.read<ReportsCubit>().currentReport?.sells ?? [];
    final filteredSells = sells.where((sell) {
      final sellDate = sell.date;
      if (sellDate == null) return false;
      // return sellDate.isAfter(selectedDateRange!.start) &&
      //     sellDate.isBefore(selectedDateRange!.end);
      return DateTimeUtils.isBetweenInclusive(sellDate, selectedDateRange!.start, selectedDateRange!.end.add(Duration(days: 1)));
    }).toList();

    // Group sells by product and calculate total quantity
    final productSales = <String, ProductSells>{};
    for (var sell in filteredSells) {
      if(sell.isRefunded) continue;
      final product = sell.product;
      print("product: ${product?.toJson()}");
      if (product == null) continue;
      await Package.checkAccessability(
        online: () async{
          productSales[product.backendId!] = productSales[product.backendId] != null ? 
          ProductSells(productSales[product.backendId]!.product, productSales[product.backendId]!.quantity + (sell.quantity ?? 0), productSales[product.backendId]!.profit + sell.profit) : ProductSells(product, sell.quantity ?? 0, sell.profit);
        }, 
        offline: () async{
          productSales[product.id.toString()] = productSales[product.id.toString()] != null? 
          ProductSells(productSales[product.id.toString()]!.product, productSales[product.id.toString()]!.quantity + (sell.quantity ?? 0), productSales[product.id.toString()]!.profit + sell.profit) : ProductSells(product, sell.quantity ?? 0, sell.profit);
        },
        shopify: () async{
          productSales[product.shopifyId.toString()] = productSales[product.shopifyId.toString()] != null ? 
          ProductSells(productSales[product.shopifyId.toString()]!.product, productSales[product.shopifyId.toString()]!.quantity + (sell.quantity ?? 0), productSales[product.shopifyId.toString()]!.profit + sell.profit) : ProductSells(product, sell.quantity ?? 0, sell.profit);
        },
      );
    }

    // Convert to list and sort by quantity
    bestProducts = productSales.entries
        .map((e) => ProductSells(e.value.product, e.value.quantity, e.value.profit))
        .toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
  }

  Future<void> setRange(BuildContext context, DateTimeRange range) async{
    selectedDateRange = range;
    emit(BestProductsLoadingState());
    await _calculateBestProducts(context);
    emit(BestProductsChangedState());
  }

  int getIncreasePercent(int i){
    if(i < 3){
      return 10;
    }
    else if(i < 6){
      return 8;
    }
    else{
      return 5;
    }
  }

  // Update your sort methods to set this field
  void sortByQuantity() {
    sortBy = 'quantity';
    bestProducts.sort((a, b) => b.quantity.compareTo(a.quantity));
    emit(BestProductsChangedState());
  }

  void sortByProfit() {
    sortBy = 'profit';
    bestProducts.sort((a, b) => b.profit.compareTo(a.profit));
    emit(BestProductsChangedState());
  }

  // void getBestProducts(List<Product> products){
  //   bestProducts = products.where((e) => e.noOfSells > 0).toList();
  //   bestProducts.sort((a,b) => b.noOfSells.compareTo(a.noOfSells));
  //   if(bestProducts.length > 10){
  //     bestProducts = bestProducts.getRange(0,10).toList();
  //   }
  //   emit(BestProductsChangedState());
  // }

  // void getMostSoldProducts(List<Sell> sells) {
  //   // Create a map to store the total quantity sold for each product
  //   Map<Product, int> productQuantities = {};

  //   // Iterate through the sales list and calculate total quantities
  //   for (var sale in sells) {
  //     if (productQuantities.containsKey(sale.product)) {
  //       productQuantities[sale.product!] = productQuantities[sale.product!]! + (sale.quantity ?? 0);
  //     } else {
  //       productQuantities[sale.product!] = sale.quantity ?? 0;
  //     }
  //   }

  //   // Sort the products by quantity sold in descending order
  //   var sortedProducts = productQuantities.entries.toList()
  //     ..sort((a, b) => a.value.compareTo(b.value));

  //   var topProducts = sortedProducts.take(10).map((entry) => Product(name: entry.key.name, noOfSells: entry.value)).toList();
  //   bestProducts = topProducts;
  //   emit(BestProductsChangedState());
  // }

  // void getTopSellingProducts(List<Sell> sells, int topN) {
  //   // Create a map to store the total quantity sold for each product
  //   Map<int, Map<Product,int>> productSales = {};

  //   // Calculate total sales for each product
  //   for (var sell in sells) {
  //     if(sell.isRefunded) continue;

  //     Product product = sell.product!;
  //     int quantity = sell.quantity ?? 0;

  //     if (productSales.containsKey(product.id)) {
  //       productSales[product.id!]![product] = productSales[product.id!]![product]??0 + quantity;
  //     } else {
  //       if(product.id != null){
  //         productSales[product.id!] = {
  //           product : quantity,
  //         };
  //       }
  //     }
  //   }

  //   // Sort the products by total sales in descending order
  //   var sortedProducts = productSales.entries.toList()
  //     ..sort((a, b) => a.value.values.toList()[0].compareTo(b.value.values.toList()[0]));

  //   // Get the top N products
  //   var topProducts = sortedProducts.take(topN).map((entry) => entry.value.keys.toList()[0]).toList();
  //   bestProducts = topProducts;
  //   emit(BestProductsChangedState());
  // }

  
}


