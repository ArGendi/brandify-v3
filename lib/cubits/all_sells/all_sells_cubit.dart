import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:brandify/models/local/hive_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/app_user/app_user_cubit.dart';
import 'package:brandify/cubits/products/products_cubit.dart';
import 'package:brandify/cubits/reports/reports_cubit.dart';
import 'package:brandify/cubits/sides/sides_cubit.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/main.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:brandify/models/firebase/firestore/sells_services.dart';
import 'package:brandify/models/firebase/firestore/shopify_services.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/models/sell.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
part 'all_sells_state.dart';

class AllSellsCubit extends Cubit<AllSellsState> {
  List<Sell> sells = [];
  int totalProfit = 0;
  int total = 0;

  AllSellsCubit() : super(AllSellsInitial());
  static AllSellsCubit get(BuildContext context) => BlocProvider.of(context);

  void add(BuildContext context, Sell sell){
    total += sell.priceOfSell!;
    totalProfit += sell.profit;
    AppUserCubit.get(context).addToTotal(sell.priceOfSell!);
    AppUserCubit.get(context).addToProfit(sell.profit);
    AppUserCubit.get(context).addToTotalOrders(sell.quantity!);
    sells.add(sell);
    // Cache.setTotal(total);
    emit(NewSellsAddedState());
  }

  void addTotalAndProfit(int totalValue, int profitValue){
    total += totalValue;
    totalProfit += profitValue;
    Cache.setTotal(totalProfit);
    emit(ProfitChangedState());
  }

  void getTotalAndProfit(){
    total = Cache.getTotal() ?? 0;
    totalProfit = Cache.getProfit() ?? 0;
    emit(ProfitChangedState());
  }

  Future<List<Sell>> getSellsFromDB() async{
    List<Sell> sellsFromDB = [];
    var sellsBox = Hive.box(HiveServices.getTableName(sellsTable));
    var keys = sellsBox.keys.toList();
    for(var key in keys){
      Sell temp = Sell.fromJson(sellsBox.get(key));
      temp.id = key;
      sellsFromDB.add(temp);
      print("Sellll: ${temp.toJson()}");
    }
    return sellsFromDB;
  }

  Future<void> getSells({int expenses = 0, List<Product>? allProducts, OrderDate? orderDate}) async{
    //if(sells.isNotEmpty) return;
    List<Sell> temp = List.from(sells);
    sells = [];

    try{
      emit(LoadingAllSellsState());
      await Package.checkAccessability(
        online: () async{
          var response = await SellsServices().getSells();
          if(response.status == Status.success){
            sells.addAll(response.data);
          }
        },
        offline: () async{
          sells = await getSellsFromDB();
        },
        shopify: () async{
          List shopifySells = await ShopifyServices().getOrders();   
          
          for(var one in shopifySells){
            Sell newSell = Sell.fromShopifyOrder(one, allProducts ?? []);
            sells.add(newSell);
          }
          print('✅ Totaaaaaaaaaaal selllllllllllllllls: ${sells.length}');
          var response = await SellsServices().getSells();
          if(response.status == Status.success){
            sells.addAll(response.data);
          }
        },
      );
      _calculateTotals(expenses);
      emit(SuccessAllSellsState());
    }
    catch(e){
      sells = List.from(temp);
      print("Erroroooooooooooooooo: $e");
      emit(SuccessAllSellsState());
    }
    
  }

  Future<void> getSellsInDateRange(DateTime fromDate, DateTime toDate, {int expenses = 0, List<Product>? allProducts}) async {
    //List<Sell> temp = List.from(sells);
    sells = [];

    try {
      emit(LoadingAllSellsState());
      await Package.checkAccessability(
        online: () async {
          var response = await SellsServices().getSellsInDateRange(fromDate, toDate);
          print("sells status: ${response.status} : ${response.data}");
          if (response.status == Status.success) {
            sells = response.data;
          }
        },
        offline: () async {
          sells = await getSellsFromDB();
          // Filter sells by date range from local storage
          sells = sells.where((sell) {
            if (sell.date == null) return false;
            return sell.date!.isAfter(fromDate.subtract(const Duration(days: 1))) && 
                   sell.date!.isBefore(toDate.add(const Duration(days: 1)));
          }).toList();
        },
        shopify: () async {
          // Get Shopify orders in date range
          List shopifySells = await ShopifyServices().getPaidOrdersInDateRange(fromDate, toDate);
          int counter = 0;
          for (var one in shopifySells) {
            Sell newSell = Sell.fromShopifyOrder(one, allProducts ?? []);
            if(newSell.isRefunded){
              counter++;
            }
            sells.add(newSell);
          }
          print('✅ Total Shopify sells in date range: ${sells.length}');
          print("counter: $counter");
          
          // Get local sells in date range
          var response = await SellsServices().getSellsInDateRange(fromDate, toDate);
          if (response.status == Status.success) {
            sells.addAll(response.data);
          }
        },
      );
      _calculateTotals(expenses);
      emit(SuccessAllSellsState());
    } catch (e) {
      //sells = List.from(temp);
      emit(FailAllSellsState());
    }
  }

  void deductFromProfit(int value){
    totalProfit -= value;
    emit(ProfitChangedState());
  }

  Future<void> refund(BuildContext context, Sell targetSell) async{
    emit(LoadingRefundSellsState());
    try{
      print("process refund..");
      await _processRefund(context, targetSell);
    }
    catch(e){
      _handleRefundError(context, e);
    }
  }

  void _calculateTotals(int expenses) {
    //sells.sort((a,b) => b.date!.compareTo(a.date!));
    total = 0;
    totalProfit = 0;

    for(var one in sells){
      if(!one.isRefunded){
        if(one.shopifyId != null && one.status != "paid"){
          continue;
        }
        total += one.priceOfSell!;
        totalProfit += one.profit;
      }
    }
    totalProfit -= expenses;
  }

  Future<void> _processRefund(BuildContext context, Sell targetSell) async {
    print("${targetSell.product?.backendId} : ${targetSell.size?.toJson()}");
    dynamic id;
    await Package.checkAccessability(
      online: () async {
        id = targetSell.product?.backendId;
      },
      offline: () async {
        id = targetSell.product?.id;
        print("id: $id");
      },
      shopify: () async {
        id = targetSell.product?.shopifyId ?? targetSell.product?.backendId;
      }
    );
    Product? refundedProduct = await ProductsCubit.get(context).refundProduct(
      id,
      targetSell.size!,
      targetSell.quantity ?? 0,
    );
    print(refundedProduct?.toJson().toString() ?? "No refund");
    
    if (!_isValidRefund(refundedProduct, targetSell)) {
      _handleInvalidRefund(context);
      return;
    }

    await _executeRefund(context, targetSell, refundedProduct!);
  }

  bool _isValidRefund(Product? refundedProduct, Sell targetSell) {
    int index = sells.indexOf(targetSell);
    return refundedProduct != null && targetSell.product != null && index > -1;
  }

  Future<void> _executeRefund(BuildContext context, Sell targetSell, Product refundedProduct) async {
    print("excuting refund..");
    int index = sells.indexOf(targetSell);
    sells[index].isRefunded = true;
    
    await _updateRefundedData(context, index, targetSell, refundedProduct);
    _updateFinancials(context, index, targetSell);
    
    emit(RefundSellsState());
    _showRefundSuccess(context);
  }

  Future<void> _updateRefundedData(BuildContext context, int index, Sell targetSell, Product refundedProduct) async {
    SidesCubit.get(context).refundSide(targetSell.sideExpenses);
    
    // Update inventory
    await Package.checkAccessability(
      online: () async {
        await FirestoreServices().update(productsTable, refundedProduct.backendId.toString(), refundedProduct.toJson());
      },
      offline: () async {
        await Hive.box(HiveServices.getTableName(productsTable)).put(targetSell.product!.id, refundedProduct.toJson());
      },
      shopify: () async{
        if(targetSell.shopifyId != null){
          await ShopifyServices().updateInventory(refundedProduct);
        }
        else{
          await FirestoreServices().update(productsTable, refundedProduct.backendId.toString(), refundedProduct.toJson());
        }
      },
    );
    
    // Update sell record and process Shopify refund
    await Package.checkAccessability(
      online: () async {
        await FirestoreServices().update(sellsTable, sells[index].backendId.toString(), sells[index].toJson());
      },
      offline: () async {
        await Hive.box(HiveServices.getTableName(sellsTable)).put(sells[index].id, sells[index].toJson());
      },
      shopify: () async{
        if(targetSell.shopifyId != null){
          try {
            print("Attempting Shopify refund for order: ${targetSell.shopifyId}");
            
            // First test the refund process
            final testResult = await ShopifyServices().testRefundProcess(targetSell.shopifyId!);
            print("Test result: $testResult");
            
            if (testResult['success'] == true) {
              // Test passed, proceed with manual refund
              final refundResult = await ShopifyServices().manualRefundOrder(
                targetSell.shopifyId!,
                reason: 'Customer requested refund'
              );
              print("Manual refund result: $refundResult");
              
              if (refundResult['success'] == true) {
                print("Shopify refund successful");
              } else {
                print("Shopify refund failed: ${refundResult['error']}");
                // Don't throw error here, just log it since the local refund was successful
              }
            } else {
              print("Shopify refund test failed: ${testResult['error']}");
              // Don't throw error here, just log it since the local refund was successful
            }
          } catch (e) {
            print("Error during Shopify refund: $e");
            // Don't throw error here, just log it since the local refund was successful
          }
        }
        else{
          await FirestoreServices().update(sellsTable, sells[index].backendId.toString(), sells[index].toJson());
        }
      },
    );
  }

  void _updateFinancials(BuildContext context, int index, Sell targetSell) {
    total -= sells[index].priceOfSell ?? 0;
    totalProfit -= sells[index].profit;
    AppUserCubit.get(context).deductFromTotal(sells[index].priceOfSell?? 0);
    AppUserCubit.get(context).deductFromProfit(sells[index].profit);

    ReportsCubit.get(context).deductFromCurrentReport(
      sells[index].quantity ?? 0, 
      sells[index].profit,
      sells[index].priceOfSell ?? 0,
    );
  }

  void _showRefundSuccess(BuildContext context) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.refunded), backgroundColor: Colors.green,)
    );
    navigatorKey.currentState?.pop();
  }

  void _handleInvalidRefund(BuildContext context) {
    emit(FailRefundSellsState());
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.refundFailed), backgroundColor: Colors.red,)
    );
  }

  void _handleRefundError(BuildContext context, dynamic error) {
    emit(FailRefundSellsState());
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.refundError(error.toString())), backgroundColor: Colors.red,)
    );
  }

  void reset(){
    sells = [];
    totalProfit = 0;
    total = 0;
    emit(AllSellsInitial());
  }

  void remove(Sell sell) async {
      dynamic productId;
      await Package.checkAccessability(
        online: () async {
          productId = sell.product?.backendId;
        },
        offline: () async {
          productId = sell.product?.id;
        },
        shopify: () async {
          productId = sell.product?.shopifyId;
        }
      );
  
      final index = sells.indexWhere((s) => 
        s.date == sell.date && 
        (s.product?.backendId == productId || s.product?.id == productId || s.product?.shopifyId == productId) &&
        s.size?.name == sell.size?.name &&
        s.quantity == sell.quantity
      );
      
      if (index != -1) {
        sells.removeAt(index);
        emit(SellsUpdatedState());
      }
    }

  void clear() {
    sells = [];
    totalProfit = 0;
    total = 0;
    emit(AllSellsInitial());
  }
}

