import 'package:brandify/cubits/ads/ads_cubit.dart';
import 'package:brandify/cubits/all_sells/all_sells_cubit.dart';
import 'package:brandify/cubits/app_user/app_user_cubit.dart';
import 'package:brandify/cubits/extra_expenses/extra_expenses_cubit.dart';
import 'package:brandify/cubits/products/products_cubit.dart';
import 'package:brandify/cubits/sides/sides_cubit.dart';
import 'package:brandify/main.dart';
import 'package:brandify/models/local/hive_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:brandify/models/package.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'package_state.dart';

class PackageCubit extends Cubit<PackageState> {
  
  PackageCubit() : super(PackageInitial());

  static PackageCubit get(context) => BlocProvider.of(context);

  // Add this function at class level
  void _resetAllCubits(BuildContext context) {
    AdsCubit.get(context).reset();
    ExtraExpensesCubit.get(context).reset();
    AllSellsCubit.get(context).reset();
    ProductsCubit.get(context).reset();
  }

  Future<void> convertPackage(BuildContext context) async {  // Add context parameter
    final l10n = AppLocalizations.of(context)!;
    final String _productsTable = HiveServices.getTableName(productsTable);
    final String _sellsTable = HiveServices.getTableName(sellsTable);
    final String _sidesTable = HiveServices.getTableName(sidesTable);
    final String _adsTable = HiveServices.getTableName(adsTable);
    final String _extraExpensesTable = HiveServices.getTableName(extraExpensesTable);

    emit(PackageLoading());
    try {
      if (Package.type == PackageType.offline) {
        // Converting from offline to online
        print("Converting from offline to online");
        print(Hive.box(_productsTable).values.toList());

        final Map<String, dynamic> localData = {
          productsTable: Hive.box(_productsTable).values.toList(),
          sellsTable: Hive.box(_sellsTable).values.toList(),
          sidesTable: Hive.box(_sidesTable).values.toList(),
          adsTable: Hive.box(_adsTable).values.toList(),
          extraExpensesTable: Hive.box(_extraExpensesTable).values.toList(),
        };
        print("here 1");

        final response = await FirestoreServices().uploadLocalData(localData);
        
        if (response.status == Status.success) {
          final docIds = Map<String, List<String>>.from(response.data);
          
          // Update Products Cubit
          var productsCubit = ProductsCubit.get(navigatorKey.currentState!.context);
          for (int i = 0; i < productsCubit.products.length; i++) {
            productsCubit.products[i].backendId = docIds[productsTable]?[i];
          }
          
          // Update Sells Cubit
          var sellsCubit = AllSellsCubit.get(navigatorKey.currentState!.context);
          for (int i = 0; i < sellsCubit.sells.length; i++) {
            sellsCubit.sells[i].backendId = docIds[sellsTable]?[i];
          }
          
          // Update Sides Cubit
          var sidesCubit = SidesCubit.get(navigatorKey.currentState!.context);
          for (int i = 0; i < sidesCubit.sides.length; i++) {
            sidesCubit.sides[i].backendId = docIds[sidesTable]?[i];
          }
          
          // Update Ads Cubit
          var adsCubit = AdsCubit.get(navigatorKey.currentState!.context);
          for (int i = 0; i < adsCubit.ads.length; i++) {
            adsCubit.ads[i].backendId = docIds[adsTable]?[i];
          }
          
          // Update Extra Expenses Cubit
          var expensesCubit = ExtraExpensesCubit.get(navigatorKey.currentState!.context);
          for (int i = 0; i < expensesCubit.expenses.length; i++) {
            expensesCubit.expenses[i].backendId = docIds[extraExpensesTable]?[i];
          }

          await FirestoreServices().updateUserData({
            "package": PACKAGE_TYPE_ONLINE,
            "total": Cache.getTotal() ?? 0,
            "totalProfit": Cache.getTotalProfit()?? 0,
          });
          await Cache.setPackageType(PACKAGE_TYPE_ONLINE);

          
           
          // Clear all Hive boxes
          await Hive.box(_productsTable).clear();
          await Hive.box(_sellsTable).clear();
          await Hive.box(_sidesTable).clear();
          await Hive.box(_adsTable).clear();
          await Hive.box(_extraExpensesTable).clear();
          
          //_resetAllCubits(context);
          //await AppUserCubit.get(context).getUserData();  // Add this line here
          
          Package.type = PackageType.online;
          emit(PackageSuccess(l10n.successfullyConvertedToOnline));
        } else {
          emit(PackageError(l10n.failedToUploadData));
        }
      } else {
        // Converting from online to offline
        final response = await FirestoreServices().getAllData();
        print("hereeeeee 1");
        if (response.status == Status.success) {
          // Save data to Hive boxes
          print("hereeeeee 2");
          await Cache.setPhone(AppUserCubit.get(navigatorKey.currentState!.context).brandPhone?? "");
          await Cache.setEmail(AppUserCubit.get(navigatorKey.currentState!.context).email?? "");
          print("hereeeeee 3");
          await HiveServices.openUserBoxes();
          print("hereeeeee 4");
          var productsIds = (await Hive.box(_productsTable).addAll(response.data[productsTable] ?? [])).toList();
          var sellsIds = (await Hive.box(_sellsTable).addAll(response.data[sellsTable] ?? [])).toList();
          var sidesIds = (await Hive.box(_sidesTable).addAll(response.data[sidesTable] ?? [])).toList();
          var adsIds = (await Hive.box(_adsTable).addAll(response.data[adsTable] ?? [])).toList();
          var extraExpensesIds = (await Hive.box(_extraExpensesTable).addAll(response.data[extraExpensesTable] ?? [])).toList();
          print("hereeeeee 5");

          var productsCubit = ProductsCubit.get(navigatorKey.currentState!.context);
          for (int i = 0; i < productsCubit.products.length; i++) {
            productsCubit.products[i].id = productsIds[i];
          }
          print("11111111");
          
          // Update Sells Cubit
          var sellsCubit = AllSellsCubit.get(navigatorKey.currentState!.context);
          for (int i = 0; i < sellsCubit.sells.length; i++) {
            sellsCubit.sells[i].id = sellsIds[i];
          }
          print("22222222");
          
          // Update Sides Cubit
          var sidesCubit = SidesCubit.get(navigatorKey.currentState!.context);
          for (int i = 0; i < sidesCubit.sides.length; i++) {
            sidesCubit.sides[i].id = sidesIds[i];
          }
          print("33333333");
          
          // Update Ads Cubit
          var adsCubit = AdsCubit.get(navigatorKey.currentState!.context);
          for (int i = 0; i < adsCubit.ads.length; i++) {
            adsCubit.ads[i].id = adsIds[i];
          }
          print("44444444");
          
          // Update Extra Expenses Cubit
          var expensesCubit = ExtraExpensesCubit.get(navigatorKey.currentState!.context);
          for (int i = 0; i < expensesCubit.expenses.length; i++) {
            expensesCubit.expenses[i].id = extraExpensesIds[i];
          }
          print("hereeeeee 6");
          // Delete existing online data first
          // final deleteResponse = await FirestoreServices().deleteAllUserData();
          // if (deleteResponse.status != Status.success) {
          //   emit(PackageError('Failed to clear online data'));
          //   await Hive.box(_productsTable).clear();
          //   await Hive.box(_sellsTable).clear();
          //   await Hive.box(_sidesTable).clear();
          //   await Hive.box(_adsTable).clear();
          //   await Hive.box(_extraExpensesTable).clear();
          //   return;
          // }
          print("hereeeeee 7");

          await FirestoreServices().updateUserData({
            "package": PACKAGE_TYPE_OFFLINE,
          });
          print("hereeeeee 8");
          await Cache.setName(AppUserCubit.get(navigatorKey.currentState!.context).brandName ?? "");
          await Cache.setEmail(AppUserCubit.get(navigatorKey.currentState!.context).email?? "");
          await Cache.setPhone(AppUserCubit.get(navigatorKey.currentState!.context).brandPhone?? "");
          await Cache.setTotal(AppUserCubit.get(navigatorKey.currentState!.context).total);
          await Cache.setTotalProfit(AppUserCubit.get(navigatorKey.currentState!.context).totalProfit);
          await Cache.setPackageType(PACKAGE_TYPE_OFFLINE);
           
          //_resetAllCubits(context);
          //await AppUserCubit.get(context).getUserData();
          print("hereeeeee 9");
          Package.type = PackageType.offline;
          
          emit(PackageSuccess(l10n.successfullyConvertedToOffline));
        } else {
          emit(PackageError(response.data['error']));
        }
      }
    } catch (e) {
      emit(PackageError(e.toString()));
    }
  }
}