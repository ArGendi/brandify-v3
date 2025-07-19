import 'package:brandify/cubits/ads/ads_cubit.dart';
import 'package:brandify/cubits/all_sells/all_sells_cubit.dart';
import 'package:brandify/cubits/extra_expenses/extra_expenses_cubit.dart';
import 'package:brandify/cubits/products/products_cubit.dart';
import 'package:brandify/cubits/sides/sides_cubit.dart';
import 'package:brandify/main.dart';
import 'package:brandify/models/ad.dart';
import 'package:brandify/models/extra_expense.dart';
import 'package:brandify/models/local/hive_services.dart';
import 'package:brandify/models/sell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:brandify/models/firebase/firestore/shopify_services.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/view/screens/auth/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'app_user_state.dart';

class AppUserCubit extends Cubit<AppUserState> {
  // Add the variables here
  int totalProfit = 0;
  int total = 0;
  int totalOrders = 0; 
  String? brandName;
  String? brandPhone;
  String? email;
  bool isLoggedInNow = false;
  DateTime? createdAt;
  bool isLoading = false;
  List<Privilege> privileges = [];

  AppUserCubit() : super(AppUserInitial());

  static AppUserCubit get(BuildContext context) => BlocProvider.of(context);

  void setIsLoggedInNow(bool value){
    isLoggedInNow = value;
  }

  void _resetAllCubits(BuildContext context) {
    AdsCubit.get(context).reset();
    ExtraExpensesCubit.get(context).reset();
    AllSellsCubit.get(context).reset();
    ProductsCubit.get(context).reset();
  }

  Future<void> getUserData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    emit(AppUserLoading());
    try {
      var packageType = Cache.getPackageType();
      if(packageType != null){
        Package.getTypeFromString(packageType);
      }
      else{
        Package.getTypeFromString(PACKAGE_TYPE_ONLINE);
      }
      print("Packaaaaaage: ${Package.type}");
      await Package.checkAccessability(
        online: () async{
          var userData = await FirestoreServices().getUserData();
          print("user data : $userData");
          
          if (userData != null) {
            print("user dataaaaaa : $userData");
            brandName = userData['brandName'];
            email = userData['email'];
            brandPhone = userData['brandPhone'];
            totalOrders = userData['totalOrders'] ?? 0;
            totalProfit = userData['totalProfit'] ?? 0;
            total = userData['total'] ?? 0;
            // Set Shopify parameters if they exist
            ShopifyServices.setParamters(
              newAdminAcessToken: userData['adminAPIAcessToken'],
              //newStoreFrontAcessToken: userData['storeFrontAPIAcessToken'],
              newStoreId: userData['storeId'],
              newLocationId: userData['locationId'],
            );
            Package.getTypeFromString(
              userData["package"] ?? PACKAGE_TYPE_ONLINE,
            );
            if(Package.type == PackageType.offline){
              brandName = Cache.getName();
              brandPhone = Cache.getPhone();
              email = Cache.getEmail();
              totalOrders = Cache.getTotalOrders() ?? 0;
              totalProfit = Cache.getTotalProfit() ?? 0;
              total = Cache.getTotal() ?? 0;
              Package.getTypeFromString(PACKAGE_TYPE_OFFLINE);
            }
          }
          else{
            var packageType = Cache.getPackageType();
            if(packageType != null){
              Package.getTypeFromString(packageType);
            }
            else{
              Package.getTypeFromString(PACKAGE_TYPE_ONLINE);
              ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                SnackBar(
                  content: Text(l10n.failedToGetUserData),
                  backgroundColor: Colors.red,
                ), 
              );
              FirebaseAuth.instance.signOut();
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            }
          }
        }, 
        offline: () async{
          brandName = Cache.getName();
          email = Cache.getEmail();
          brandPhone = Cache.getPhone();
          totalOrders = Cache.getTotalOrders() ?? 0;
          totalProfit = Cache.getTotalProfit() ?? 0;
          total = Cache.getTotal() ?? 0;
          Package.getTypeFromString(PACKAGE_TYPE_OFFLINE);
        },
        shopify: () async{
          var userData = await FirestoreServices().getUserData();
          print("user data : $userData");
          
          if (userData != null) {
            print("user dataaaaaa : $userData");
            brandName = userData['brandName'];
            email = userData['email'];
            brandPhone = userData['brandPhone'];
            totalOrders = userData['totalOrders'] ?? 0;
            totalProfit = userData['totalProfit'] ?? 0;
            total = userData['total'] ?? 0;
            // Set Shopify parameters if they exist
            ShopifyServices.setParamters(
              newAdminAcessToken: userData['adminAPIAcessToken'],
              //newStoreFrontAcessToken: userData['storeFrontAPIAcessToken'],
              newStoreId: userData['storeId'],
              newLocationId: userData['locationId'],
            );
            Package.getTypeFromString(
              userData["package"] ?? PACKAGE_TYPE_SHOPIFY,
            );
          }
          else{
            Package.type = PackageType.shopify;
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              SnackBar(
                content: Text(l10n.failedToGetUserData),
                backgroundColor: Colors.red,
              ),
            );
            FirebaseAuth.instance.signOut();
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => LoginScreen()),
              (route) => false,  
            );
          }
        },
      );
      
      emit(AppUserLoaded());
    } catch (e) {
      emit(AppUserError(l10n.errorLoadingUserData(e.toString())));
    }
  }

   

  void calculateTotalAndProfit(List<Sell> sells, List<Ad> ads, List<ExtraExpense> extraExpenses){
    if(Cache.getTotal() != 0) return;
    
    int internalTotalIncome = 0;
    int internalTotalProfit = 0;

    for(var sell in sells){
      if(!sell.isRefunded){
        internalTotalIncome += sell.priceOfSell!;
        internalTotalProfit += sell.profit;
      }
    }
    for(var ad in ads){
      internalTotalProfit -= ad.cost ?? 0;
    }
    for(var extraExpense in extraExpenses){
      internalTotalProfit -= extraExpense.price ?? 0;
    }

    total = internalTotalIncome;
    totalProfit = internalTotalProfit;
    Cache.setTotal(total);
    Cache.setProfit(totalProfit);
    emit(AppUserLoaded());
  }

  // Add these methods to manage the values
  void updateTotal(int value) async {
    total = value;
    await Package.checkAccessability(
      online: () async {
        await FirestoreServices().updateUserData({'total': value});
      },
      offline: () async {
        Cache.setTotal(value);
      },
    );
    emit(TotalUpdatedState());
  }

  void updateProfit(int value) async {
    totalProfit = value;
    await Package.checkAccessability(
      online: () async {
        await FirestoreServices().updateUserData({'totalProfit': value});
      },
      offline: () async {
        Cache.setTotalProfit(value);
      },
    );
    emit(ProfitUpdatedState());
  }

  void addToTotal(int value) async {
    total += value;
    await Package.checkAccessability(
      online: () async {
        await FirestoreServices().updateUserData({'total': total});
      },
      offline: () async {
        await Cache.setTotal(total);
      },
    );
    emit(TotalUpdatedState());
  }

  void addToProfit(int value) async {
    totalProfit += value;
    await Package.checkAccessability(
      online: () async {
        await FirestoreServices().updateUserData({'totalProfit': totalProfit});
      },
      offline: () async {
        Cache.setTotalProfit(totalProfit);
      },
    );
    emit(ProfitUpdatedState());
  }

   void addToTotalOrders(int value) async {
    totalOrders += value;
    await Package.checkAccessability(
      online: () async {
        await FirestoreServices().updateUserData({'totalOrders': totalOrders});
      },
      offline: () async {
        Cache.setTotalOrders(totalOrders);
      },
    );
    emit(TotalOrdersUpdatedState());
  }

  void deductFromTotal(int value) async {
    total -= value;
    await Package.checkAccessability(
      online: () async {
        await FirestoreServices().updateUserData({'total': total});
      },
      offline: () async {
        Cache.setTotal(total);
      },
    );
    emit(TotalUpdatedState());
  }

  void deductFromProfit(int value) async {
    print("value : $value");
    totalProfit -= value;
    await Package.checkAccessability(
      online: () async {
        await FirestoreServices().updateUserData({'totalProfit': totalProfit});
      },
      offline: () async {
        Cache.setTotalProfit(totalProfit);
      },
    );
    emit(ProfitUpdatedState());
  }

  Future<bool> updateUser({required String name}) async{
    print("name : $name");
    bool isSuccess = false;
    var res = await FirestoreServices().updateUserData({
      'brandName': name,
    });
    if(res.status == Status.success){
      brandName = name;
      isSuccess = true;
      await Cache.setName(name);
    }
    else{
      isSuccess = false;
    }
    // await Package.checkAccessability(
    //   online: () async {
        
    //   },
    //   offline: () async {
    //     await Cache.setName(name);
    //     await Cache.setPhone(phone);
    //     isSuccess = true;
    //   },
    // );
    emit(UserUpdatedState());
    print("isSuccess : $isSuccess");
    return isSuccess;
  }

  void setPrivileges(List<String> privs) {
    print(privs);
    privileges = privs.map((e) => PrivilegeExtension.fromString(e)).whereType<Privilege>().toList();
    emit(AppUserDataValuesLoading());
  }

  List<Privilege> getPrivileges() => privileges;

  Future<void> logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    emit(AppUserLoading());
    try {
      await FirebaseAuth.instance.signOut();
      await _clearLocalData();
      total = 0;
      totalProfit = 0;
      totalOrders = 0;
      brandName = null;
      brandPhone = null;
      ShopifyServices.clearValues();
      emit(AppUserSuccess());
      _navigateToLogin(context);
    } catch (e) {
      emit(AppUserError(l10n.unexpectedError(e.toString())));
    }
  }
  
    Future<void> _clearLocalData() async {
      await Cache.clear();
      
      ProductsCubit.get(navigatorKey.currentContext!).clear();
      AllSellsCubit.get(navigatorKey.currentContext!).clear();
      SidesCubit.get(navigatorKey.currentContext!).clear();
      AdsCubit.get(navigatorKey.currentContext!).clear();
      ExtraExpensesCubit.get(navigatorKey.currentContext!).clear();
      
      emit(AppUserInitial());
    }
  
    void _navigateToLogin(BuildContext context) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }

  Future<void> deleteAccount(BuildContext context) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
  
        emit(AppUserLoading());
  
        // Delete all user data from Firestore
        final batch = FirebaseFirestore.instance.batch();
        final userId = user.uid;
  
        // Delete all collections
        final collections = [
          'products',
          'sells',
          'sides',
          'ads',
          'extraExpenses',
        ];
  
        for (var collection in collections) {
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection(collection)
              .get();
  
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
        }
  
        // Delete user document
        batch.delete(
          FirebaseFirestore.instance.collection('users').doc(userId),
        );
  
        await batch.commit();
  
        // Clear local data
        await Hive.box('productsTable').clear();
        await Hive.box('sellsTable').clear();
        await Hive.box('sidesTable').clear();
        await Hive.box('adsTable').clear();
        await Hive.box('extraExpensesTable').clear();
        Cache.clear();
  
        // Delete Firebase Auth account
        await user.delete();
  
        emit(AppUserSuccess());
  
        // Navigate to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        emit(AppUserError(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(navigatorKey.currentContext!)!.failedToDeleteAccount(e.toString())}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

  Future<void> refreshUserData() async {
    emit(AppUserLoading());
    if (isLoggedInNow){
      try {
        // First get user data and check if successful
        var userData = await FirestoreServices().getUserData();
        if (userData == null) {
          emit(AppUserError(AppLocalizations.of(navigatorKey.currentContext!)!.failedToGetUserData));
          return;
        }
        print("userData package : ${userData['package']}");
        // Get package type and continue with data processing
        var packageType = userData['package'] ?? PACKAGE_TYPE_ONLINE;
        Package.getTypeFromString(packageType);
        print("packageType : $packageType");
        
        brandName = userData['brandName'];
        brandPhone = userData['brandPhone'];
        email = userData['email'];
        totalOrders = userData['totalOrders'] ?? 0;
        totalProfit = userData['totalProfit'] ?? 0;
        total = userData['total'] ?? 0;
        createdAt = userData['createdAt'] != null ? 
          DateTime.parse(userData['createdAt']) : null;
        
        // Save to cache
        await Cache.setName(brandName ?? '');
        await Cache.setPhone(brandPhone ?? '');
        await Cache.setEmail(email ?? '');
        await Cache.setTotalOrders(totalOrders);
        await Cache.setTotalProfit(totalProfit);
        await Cache.setTotal(total);
        await Cache.setPackageType(packageType);

        
        // if (Package.type == PackageType.online || Package.type == PackageType.shopify) {
          
        // } 
        print("Package.type : ${Package.type}");
        if (Package.type == PackageType.offline) {
          await HiveServices.openUserBoxes();
          // Get data from Hive
          //var productsBox = Hive.box(HiveServices.getTableName(productsTable));
          var sellsBox = Hive.box(HiveServices.getTableName(sellsTable));
          var adsBox = Hive.box(HiveServices.getTableName(adsTable));
          var expensesBox = Hive.box(HiveServices.getTableName(extraExpensesTable));
          
          // Calculate totals
          int salesTotal = 0;
          int profitTotal = 0;
          int ordersCount = 0;
          
          // Calculate from sells
          for (var key in sellsBox.keys) {
            try {
              var sellData = Map<String, dynamic>.from(sellsBox.get(key) ?? {});
              int priceOfSell = sellData['priceOfSell'] is int ? sellData['priceOfSell'] : 0;
              int profit = sellData['profit'] is int ? sellData['profit'] : 0;
              bool isRefunded = sellData['isRefunded'] == true;
              
              if (!isRefunded) {
                salesTotal += priceOfSell;
                profitTotal += profit;
                ordersCount++;
              }
            } catch (e) {
              print('Error processing sell data: $e');
            }
          }
          
          // Deduct ads costs
          for (var key in adsBox.keys) {
            try {
              var adData = Map<String, dynamic>.from(adsBox.get(key) ?? {});
              int cost = adData['cost'] is int ? adData['cost'] : 0;
              profitTotal -= cost;
            } catch (e) {
              print('Error processing ad data: $e');
            }
          }
          
          // Deduct extra expenses
          for (var key in expensesBox.keys) {
            try {
              var expenseData = Map<String, dynamic>.from(expensesBox.get(key) ?? {});
              int price = expenseData['price'] is int ? expenseData['price'] : 0;
              profitTotal -= price;
            } catch (e) {
              print('Error processing expense data: $e');
            }
          }
          
          // Update local variables
          total = salesTotal;
          totalProfit = profitTotal;
          totalOrders = ordersCount;
          brandName = Cache.getName();
          brandPhone = Cache.getPhone();
          email = Cache.getEmail();
          
          // Save to cache
          await Cache.setTotal(total);
          await Cache.setTotalProfit(totalProfit);
          await Cache.setTotalOrders(totalOrders);
        }

        if(Package.type == PackageType.shopify){
          ShopifyServices.setParamters(
            newAdminAcessToken: userData["adminAPIAcessToken"],
            newStoreId: userData["storeId"],
            newLocationId: userData["locationId"],
          );
          emit(AppUserDataValuesLoading());
        }
        else{
          emit(AppUserLoaded());
        }

      } catch (e) {
        emit(AppUserError(e.toString()));
      }
    }
    else{
      var userData = await FirestoreServices().getUserData();
      if (userData != null) {
        print("user dataaaaaa : $userData");
        Package.getTypeFromString(userData['package'] ?? PACKAGE_TYPE_ONLINE);
        brandName = userData['brandName'];
        brandPhone = userData['brandPhone'];
        email = userData['email'];
        totalOrders = userData['totalOrders'] ?? 0;
        totalProfit = userData['totalProfit'] ?? 0;
        total = userData['total'] ?? 0;
        createdAt = userData['createdAt'] != null ? 
          DateTime.parse(userData['createdAt']) : null;
        if(Package.type == PackageType.shopify){
          ShopifyServices.setParamters(
            newAdminAcessToken: userData["adminAPIAcessToken"],
            newStoreId: userData["storeId"],
            newLocationId: userData["locationId"],
          );
        }
        else if(Package.type == PackageType.offline){
          await HiveServices.openUserBoxes();
        }
        // If it's shopify, it should load until read the values from sells cubit
        if(Package.type == PackageType.shopify){
          emit(AppUserDataValuesLoading());
        }
        else{
          emit(AppUserLoaded());
        }
        
      } else {
        var packageType = Cache.getPackageType();
        print("packageType : $packageType");
        Package.getTypeFromString(packageType ?? PACKAGE_TYPE_ONLINE);
        if(Package.type == PackageType.offline){
          // Offline mode - get from cache
          brandName = Cache.getName();
          brandPhone = Cache.getPhone();
          email = Cache.getEmail();
          totalOrders = Cache.getTotalOrders() ?? 0;
          totalProfit = Cache.getTotalProfit() ?? 0;
          total = Cache.getTotal() ?? 0;

          await HiveServices.openUserBoxes();
          
          emit(AppUserLoaded());
        }
        else{
          emit(AppUserError('Could not get user data'));
          await logout(navigatorKey.currentContext!);
        }
      }
    }
  }

  void setTotalAndProfit(int newTotal, int newProfit, [int? newTotalOrders]){
    total = newTotal;
    totalProfit = newProfit;
    totalOrders = newTotalOrders ?? 0;
    emit(TotalAndProfitUpdatedState());
  }

  Future<void> changePassword(String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');
    await user.updatePassword(newPassword);
  }

  void setIsLoading(bool value){
    isLoading = value;
    emit(AppUserSuccess());
  }
}

