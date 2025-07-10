import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:brandify/models/local/hive_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/main.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:brandify/models/firebase/firestore/product_services.dart';
import 'package:brandify/models/firebase/firestore/shopify_services.dart';
import 'package:brandify/models/firebase/storage_services.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/models/size.dart';
import 'package:brandify/view/screens/products/product_details.dart';
import 'package:brandify/view/screens/products/products_screen.dart';
import 'package:shopify_flutter/shopify_flutter.dart' as sh;
import 'package:brandify/view/widgets/loading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  List<Product> filteredProducts = [];
  List<Product> products = [];
  bool gettingData = false;
  final TextEditingController searchController = TextEditingController();

  ProductsCubit() : super(ProductsInitial()) {
    filteredProducts = products;
  }

  static ProductsCubit get(BuildContext context) => BlocProvider.of(context);

  Future<List<Product>> getProductsFromDB() async {
    List<Product> productsFromDB = [];
    print("phone: ${Cache.getPhone()}");
    var productsBox = Hive.box(HiveServices.getTableName(productsTable));
    var keys = productsBox.keys.toList();
    
    for (var key in keys) {
      Product temp = Product.fromJson(productsBox.get(key));
      temp.id = key;
      productsFromDB.add(temp);
    }
    return productsFromDB;
  }

  Future<void> getProducts() async {
    if (products.isNotEmpty || gettingData) return;

    gettingData = true;
    try{
      emit(LoadingProductsState());
      await Package.checkAccessability(
        online: () async {
          var response = await ProductServices().getProducts();
          print("online read product: ${response.data}");
          if (response.status == Status.success) {
            products = response.data as List<Product>;
          }
        },
        offline: () async {
          print("getting product from offline");
          products = await getProductsFromDB();
          print("getting product from offline: ${products.length}");
        },
        shopify: () async{
          List shopifyProducts = await ShopifyServices().getAllProducts();
          print("-----------------------------------------------------");
          print("Productsssssssssssssssssssssssssssssssssssssssssssss: ${shopifyProducts.length}");
          print("-----------------------------------------------------");
          log("${shopifyProducts[0]}");
          for(var prod in shopifyProducts){
            products.add(Product.fromShopify(prod));
          }
          print("-----------------------------------------------------");
          print("Products Afteeeeeeeeeeer: ${products.length}");
          print("-----------------------------------------------------");
          var response = await ProductServices().getProducts();
          if (response.status == Status.success) {
            List<Product> firebaseProducts = response.data as List<Product>;
            for(var prod in firebaseProducts){
              int index = products.indexWhere((element) => element.shopifyId.toString() == prod.backendId);
              if(index != -1){
                products[index].price = prod.price;
              }
            }
          }
        },
      );
      filteredProducts = products;
      print("-----------------------------------------------------");
      print("Filtered Products: ${filteredProducts.length}");
      print("-----------------------------------------------------");
      gettingData = false;
      emit(SuccessProductsState());
    }
    catch(e){
      gettingData = false;
      emit(FailProductsState());
    }
    
  }

  Future<void> addProduct(Product product, BuildContext context) async {
    emit(LoadingOneProductState());
    try {
      await Package.checkAccessability(
        online: () async {
          print("adding product with image ${product.image}");
          if(product.image != null){
            product.image = await StorageServices.uploadFile(File(product.image!));
          }
          var response = await FirestoreServices().add(productsTable, product.toJson());
          product.backendId = response.data;
        },
        offline: () async {
          var productBox = Hive.box(HiveServices.getTableName(productsTable));
          product.id = await productBox.add(product.toJson());
        },
        shopify: () async{
          if(product.image != null){
            product.image = await StorageServices.uploadFile(File(product.image!));
          }
          var res = await ShopifyServices().createProduct(product);
          product.shopifyId = res;
          await FirestoreServices().set(productsTable, product.shopifyId.toString() ,{
            "price": product.price
          });
        }
      );
      products.add(product);
      filteredProducts = products;
      log(filteredProducts.toString());
      
      emit(ProductAddedState());
      _showSuccessSnackBar(context, AppLocalizations.of(context)!.done);
      navigatorKey.currentState?.pop();
    } catch (e) {
      emit(FailOneProductState());
      _showErrorSnackBar(context, AppLocalizations.of(context)!.tryAgainLater);
    }
  }

  Future<void> deleteProduct(Product product, BuildContext context) async {
    emit(LoadingOneProductState());
    try {
      await Package.checkAccessability(
        online: () async {
          await FirestoreServices().delete(productsTable, product.backendId.toString());
        },
        offline: () async {
          var productBox = Hive.box(HiveServices.getTableName(productsTable));
          await productBox.delete(product.id ?? -1);
        },
        shopify: () async{
          await ShopifyServices().deleteProduct(product.shopifyId.toString());
        }
      );
      products.remove(product);
      filteredProducts = products;
      
      emit(ProductAddedState());
      _showSuccessSnackBar(context, AppLocalizations.of(context)!.productDeleted);
      navigatorKey.currentState?..pop()..pop();
    } catch (e) {
      emit(FailOneProductState());
      _showErrorSnackBar(context, AppLocalizations.of(context)!.tryAgainLater);
    }
  }

  Future<void> editProduct(Product oldProduct, Product newProduct, BuildContext context) async {
    int index = products.indexOf(oldProduct);
    if (index > -1) {
      emit(LoadingEditProductState());
      
      // Add the new comparison function here
      //bool isOnlyPriceChanged = _isOnlyPriceChanged(oldProduct, newProduct);
      
      await Package.checkAccessability(
        online: () async {
          var res = await FirestoreServices().update(
            productsTable,
            oldProduct.backendId.toString(),
            newProduct.toJson()
          );
          if(res.status == Status.success){
            products[index] = newProduct;
            _showSuccessSnackBar(
              context,
              AppLocalizations.of(context)!.productUpdated
            );
            navigatorKey.currentState?..pop()..pop();
          }
          else{
            _showSuccessSnackBar(
              context,
              AppLocalizations.of(context)!.errorUpdatingProduct
            );
          }
        },
        offline: () async {
          await Hive.box(HiveServices.getTableName(productsTable)).put(oldProduct.id, newProduct.toJson());
          products[index] = newProduct;
          _showSuccessSnackBar(
            context,
            AppLocalizations.of(context)!.productUpdated
          );
          navigatorKey.currentState?..pop()..pop();
        },
        shopify: () async{
          bool onlyPriceChanged = _isOnlyPriceChanged(oldProduct, newProduct);
          if(onlyPriceChanged){
            await FirestoreServices().set(productsTable, oldProduct.shopifyId.toString(), {
              "price": newProduct.price
            });
            products[index] = newProduct;
            print("product updateeeeeeed on firebase");
            _showSuccessSnackBar(
              context, 
              AppLocalizations.of(context)!.productUpdated
            );
            navigatorKey.currentState?..pop()..pop();
          }
          else{
            var res = await ShopifyServices().updateInventory(newProduct);
            if(res){
              if(newProduct.price != null || (newProduct.price != newProduct.shopifyPrice)){
                await FirestoreServices().set(productsTable, oldProduct.shopifyId.toString(), {
                  "price": newProduct.price
                });
              }

              products[index] = newProduct;
              print("product updateeeeeeed: $res");
              _showSuccessSnackBar(
                context, 
                AppLocalizations.of(context)!.productUpdated
              );
              navigatorKey.currentState?..pop()..pop();
            }
            else{
              _showSuccessSnackBar(
                context, 
                AppLocalizations.of(context)!.errorUpdatingProduct
              );
            }
          }
        },
      );
      emit(EditProductState());
    }
  }

  bool _isOnlyPriceChanged(Product oldProduct, Product newProduct) {
    // Check if only price is different
    if (oldProduct.price != newProduct.price) {
      // Verify all other fields remain the same
      return oldProduct.name == newProduct.name &&
             oldProduct.code == newProduct.code &&
             oldProduct.image == newProduct.image &&
             oldProduct.backendId == newProduct.backendId &&
             oldProduct.shopifyId == newProduct.shopifyId &&
             _areSizesEqual(oldProduct.sizes, newProduct.sizes);
    }
    return false;
  }

  bool _areSizesEqual(List<ProductSize> sizes1, List<ProductSize> sizes2) {
    if (sizes1.length != sizes2.length) return false;
    
    for (int i = 0; i < sizes1.length; i++) {
      if (sizes1[i].name != sizes2[i].name ||
          sizes1[i].quantity != sizes2[i].quantity) {
        return false;
      }
    }
    return true;
  }

  void filterProducts(String value) {
    if (value.isEmpty) {
      filteredProducts = products;
    } else {
      filteredProducts = products
          .where((e) => e.name.toString().toLowerCase().contains(value.toString().toLowerCase()))
          .toList();
    }
    emit(FilterState());
  }

  Future<bool> sellSize(Product p, ProductSize size, int quantity) async{
    try{
      int i = products.indexOf(p);
      bool result = false;
      if (i != -1) {
        int j = products[i].sizes.indexOf(size);
        products[i].sizes[j].quantity = products[i].sizes[j].quantity! - quantity;
        products[i].noOfSells += quantity;
        await Package.checkAccessability(
          online: () async {
            var res = await FirestoreServices().update(productsTable, products[i].backendId.toString(), products[i].toJson());
            if(res.status == Status.success){
              result = true;
            }
          },
          offline: () async {
            print("updating product");
            print(products[i].toJson());
            print(HiveServices.getTableName(productsTable));
            await Hive.box(HiveServices.getTableName(productsTable)).put(products[i].id!, products[i].toJson());
            result = true;
            print("result: $result");
          },
          shopify: () async{
            if(products[i].sizes[j].id != null){
              result = await ShopifyServices().updateProductQuantity(products[i].sizes[j].id!, quantity * -1);
            }
          }
        );
        emit(SellSizeState());
      }
      print("final result: $result");
      return result;
    }
    catch(e){
      String errorMessage = AppLocalizations.of(navigatorKey.currentContext!)!.failedToFetchProducts("");
      if (e is SocketException) {
        errorMessage += AppLocalizations.of(navigatorKey.currentContext!)!.noInternetConnection;
      } else if (e is TimeoutException) {
        errorMessage += AppLocalizations.of(navigatorKey.currentContext!)!.connectionTimedOut;
      } else if (e.toString().contains("permission-denied")) {
        errorMessage += AppLocalizations.of(navigatorKey.currentContext!)!.accessDenied;
      } else {
        errorMessage += e.toString();
      }
      
      if (navigatorKey.currentContext != null) {
        _showErrorSnackBar(navigatorKey.currentContext!, errorMessage);
      }
      return false;
    }
  }

  Future<Product?> refundProduct(dynamic id, ProductSize size, int quantity) async{
    if (id == null) return null;
    
    for (int i = 0; i < products.length; i++) {
      dynamic productId;
      Package.checkAccessability(
        online: () async{
          productId = products[i].backendId;
        }, 
        offline: () async{
          productId = products[i].id;
        },
        shopify: () async{
          productId = products[i].shopifyId ?? products[i].backendId;
          
        }
      );
      if (productId == id) {
        for (int j = 0; j < products[i].sizes.length; j++) {
          if (products[i].sizes[j].name == size.name) {
            if(Package.type == PackageType.shopify){
              bool isUpdated = await ShopifyServices().updateProductQuantity(products[i].sizes[j].id!, quantity);
              if(isUpdated){
                products[i].sizes[j].quantity = products[i].sizes[j].quantity! + quantity;
                products[i].noOfSells -= quantity;
              }
            }
            else{
              products[i].sizes[j].quantity = products[i].sizes[j].quantity! + quantity;
              products[i].noOfSells -= quantity;
            }
            
            log("Sells: ${products[i].noOfSells}");
            filteredProducts = products;
            emit(EditProductState());
            return products[i];
          }
        }
      }
    }
    return null;
  }

  void getProductByCode(BuildContext context, String code) {
    List<Product> temp = products.where((item) => item.code == code).toList();
    if (temp.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetails(product: temp.first))
      );
    } else {
      _showErrorSnackBar(context, AppLocalizations.of(context)!.doesntExist);
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      )
    );
    }
    
  }

  void reset() {
    products = [];
    filteredProducts = [];
    emit(ProductsInitial());
  }

  void clear() {
    products = [];
    filteredProducts = [];
    emit(ProductsInitial());
  }

  Future<void> updateShopifyProductCost(Product product, BuildContext context) async {
    try {
      var response = await FirestoreServices().set(
        productsTable,
        product.shopifyId.toString(),
        {"price": product.price},
      );
      if(response.status == Status.success){
        int index = products.indexWhere((e) => e.shopifyId == product.shopifyId);
        if(index != -1){
          products[index].price = product.price;
          emit(EditProductState());
          _showSuccessSnackBar(context, AppLocalizations.of(context)!.productUpdated);
        }
        else{
          _showErrorSnackBar(context, AppLocalizations.of(context)!.errorUpdatingProduct);
        }
      }
      else{
        _showErrorSnackBar(context, AppLocalizations.of(context)!.errorUpdatingProduct);
      }
    } catch (e) {
      _showErrorSnackBar(context, AppLocalizations.of(context)!.errorUpdatingProduct);
    }
  }
}

