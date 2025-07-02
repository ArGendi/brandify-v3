import 'package:bloc/bloc.dart';
import 'package:brandify/main.dart';
import 'package:brandify/models/local/hive_services.dart';
import 'package:brandify/view/widgets/detail_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/all_sells/all_sells_cubit.dart';
import 'package:brandify/cubits/app_user/app_user_cubit.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/ad.dart';
import 'package:brandify/models/firebase/firestore/ads_services.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:brandify/models/package.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'ads_state.dart';

class AdsCubit extends Cubit<AdsState> {
  int cost = 0;
  SocialMediaPlatform? selectedPlatform;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  DateTime date = DateTime.now();
  List<Ad> ads = [];
  String? description;

  AdsCubit() : super(AdsInitial());
  static AdsCubit get(BuildContext context) => BlocProvider.of(context);

  // void onAdd(BuildContext context) async{
  //   bool valid = formKey.currentState?.validate() ?? false;
  //   if(valid){
  //     formKey.currentState?.save();
  //     if(selectedPlatform != null){
  //       Ad newAd = Ad(cost: cost, platform: selectedPlatform, date: date);
  //       await Package.checkAccessability(
  //         online: () async{
  //           var res = await FirestoreServices().add(adsTable, newAd.toJson());
  //           if(res.status == Status.success){
  //             newAd.backendId = res.data;
  //             ads.add(newAd);
  //             formKey.currentState?.reset();
  //             AllSellsCubit.get(context).deductFromProfit(newAd.cost ?? 0);
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               SnackBar(content: Text("Added successfuly"), backgroundColor: Colors.green.shade700,)
  //             );
  //           }
  //           else{
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               SnackBar(content: Text("Error occured"), backgroundColor: Colors.red.shade700,)
  //             );
  //           }
  //         }, 
  //         offline: () async{
  //           newAd.id = await Hive.box(adsTable).add(newAd.toJson());
  //           ads.add(newAd);
  //           formKey.currentState?.reset();
  //           AllSellsCubit.get(context).deductFromProfit(newAd.cost ?? 0);
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text("Added successfuly"), backgroundColor: Colors.green.shade700,)
  //           );
  //         },
  //       );
  //       emit(AdsChangedState());
  //       Navigator.pop(context);
  //     }
  //     else{
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Choose a platform"))
  //       );
  //     }
  //   }
  // }

  //  Future<int> getAllAds() async{
  //   if(ads.isNotEmpty) return 0;
  //   try{
  //     int totalCost = 0;
  //     await Package.checkAccessability(
  //       online: () async{
  //         var response = await AdsServices().getAds();
  //         if(response.status == Status.success){
  //           ads.addAll(response.data);
  //           for(var ad in ads){
  //             totalCost += ad.cost ?? 0;
  //           }
  //         }
  //       }, 
  //       offline: () async{
  //         totalCost = getAllAdsFromHive();
  //       },
  //     );
  //     emit(AdsChangedState());
  //     return totalCost;
  //   }
  //   catch(e){
  //     print(e);
  //     return 0;
  //   }
  // }

  int getAllAdsFromHive(){
    try{
      List<Ad> tempAds = [];
      int totalCost = 0;
      var adsBox = Hive.box(HiveServices.getTableName(adsTable));
      var keys = adsBox.keys.toList();
      for(var key in keys){
        Ad temp = Ad.fromJson(adsBox.get(key));
        temp.id = key;
        tempAds.add(temp);
        totalCost += temp.cost ?? 0;
      }
      ads = tempAds;
      emit(AdsChangedState());
      return totalCost;
    }
    catch(e){
      print(e);
      return 0;
    }
  }

  void setPlatform(SocialMediaPlatform value){
    selectedPlatform = value;
    emit(AdsChangedState());
  }

  String getDate(){
    return "${date.day}/${date.month}/${date.year}";
  }

  void setDate(DateTime value){
    date = value;
    emit(AdsChangedState());
  }

  Color getAdColor(Ad ad){
    switch(ad.platform){
      case SocialMediaPlatform.facebook: return Colors.blue.shade700;
      case SocialMediaPlatform.instagram: return Colors.red.shade700;
      case SocialMediaPlatform.tiktok: return Colors.black;
      default: return Colors.grey.shade600;
    }
  }

  Widget getAdIcon(Ad ad){
    switch(ad.platform){
      case SocialMediaPlatform.facebook: return FaIcon(FontAwesomeIcons.facebook, color: Colors.white,);
      case SocialMediaPlatform.instagram: return FaIcon(FontAwesomeIcons.instagram, color: Colors.white,);
      case SocialMediaPlatform.tiktok: return FaIcon(FontAwesomeIcons.tiktok, color: Colors.white,);
      default: return Icon(Icons.question_mark_rounded, color: Colors.white,);
    }
  }

  void sortAdsByPrice({bool descending = true}) {
    ads.sort((a, b) => descending
        ? (b.cost ?? 0).compareTo(a.cost ?? 0)
        : (a.cost ?? 0).compareTo(b.cost ?? 0));
    emit(AdsChangedState());
  }

  void sortAdsByDate({bool descending = true}) {
    ads.sort((a, b) => descending
        ? (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now())
        : (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));
    emit(AdsChangedState());
  }

  List<Ad> filteredAds = [];

  Future<int> getAllAds() async {
    try {
      //if (ads.isNotEmpty) return 0;

      emit(AdsLoading());
      int totalCost = 0;
      await Package.checkAccessability(
        online: () async {
          var response = await AdsServices().getAds();
          if (response.status == Status.success) {
            ads = response.data;
            filteredAds = List.from(ads); // Initialize filtered ads with all ads
            for(var ad in ads){
              totalCost += ad.cost ?? 0;
            }
          }
        },
        offline: () async {
          totalCost = getAllAdsFromHive();
          filteredAds = List.from(ads); // Initialize filtered ads with all ads
        },
      );
      emit(AdsLoaded());
      return totalCost;
    } catch (e) {
      emit(AdsError( e.toString()));
      return 0;
    }
  }

  void filterAdsByDate(DateTime start, DateTime end) {
    filteredAds = ads.where((ad) {
      return ad.date != null && 
             ad.date!.isAfter(start.subtract(Duration(days: 1))) && 
             ad.date!.isBefore(end.add(Duration(days: 1)));
    }).toList();
    emit(AdsLoaded());
  }

  void onAdd(BuildContext context) async {
    bool valid = formKey.currentState?.validate() ?? false;
    if (valid && selectedPlatform != null) {
      formKey.currentState?.save();
      Ad newAd = Ad(
        cost: cost, 
        platform: selectedPlatform, 
        date: date,
        description: description,
      );
      emit(AdsLoading());
      await Package.checkAccessability(
        online: () async {
          var res = await FirestoreServices().add(adsTable, newAd.toJson());
          if (res.status == Status.success) {
            newAd.backendId = res.data;
            
            ads.add(newAd);
            filteredAds = List.from(ads); // Update filtered ads
            formKey.currentState?.reset();
            AllSellsCubit.get(context).deductFromProfit(newAd.cost ?? 0);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.addedSuccessfully), backgroundColor: Colors.green.shade700,)
            );
          }
        },
        offline: () async {
          newAd.id = await Hive.box(HiveServices.getTableName(adsTable)).add(newAd.toJson());
          ads.add(newAd);
          filteredAds = List.from(ads); // Update filtered ads
          formKey.currentState?.reset();
          AllSellsCubit.get(context).deductFromProfit(newAd.cost ?? 0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.addedSuccessfully), backgroundColor: Colors.green.shade700,)
          );
        },
      );
      AppUserCubit.get(context).addToProfit(-(newAd.cost ?? 0));
      emit(AdsLoaded());
      Navigator.pop(context);
    }
  }

  Future<void> deleteAd(BuildContext context, Ad ad) async {
      emit(LoadingDeleteAdState());
      try {
        await Package.checkAccessability(
          online: () async {
            var res = await FirestoreServices().delete(adsTable, ad.backendId!);
            if (res.status == Status.success) {
              ads.remove(ad);
              filteredAds.remove(ad);
              emit(SuccessDeleteAdState());
              AppUserCubit.get(context).addToProfit(ad.cost?? 0);
            } else {
              emit(ErrorDeleteAdState());
            }
          },
          offline: () async {
            final box = await Hive.openBox(HiveServices.getTableName(adsTable));
            await box.delete(ad.id);
            ads.remove(ad);
            filteredAds.remove(ad);
            emit(SuccessDeleteAdState());
            AppUserCubit.get(context).addToProfit(ad.cost?? 0);
          }
        );
        
      } catch (e) {
        emit(ErrorDeleteAdState());
      }
    }

    void reset() {
      ads = [];
      filteredAds = [];
      emit(AdsInitial());
    }

  void clear() {
    ads = [];
    filteredAds = [];
    emit(AdsInitial());
  }

  void showEnhancedAdDetails(BuildContext context, Ad ad) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.advertisementDetails,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
            ),
            SizedBox(height: 20),
            DetailRow(
              icon: Icons.campaign,
              label: AppLocalizations.of(context)!.platform,
              value: ad.platform?.name ?? AppLocalizations.of(context)!.notAvailable,
            ),
            DetailRow(
              icon: Icons.attach_money,
              label: AppLocalizations.of(context)!.cost,
              value: "${AppLocalizations.of(context)!.currency(ad.cost ?? 0)}",
            ),
            DetailRow(
              icon: Icons.calendar_today,
              label: AppLocalizations.of(context)!.date,
              value: ad.date.toString().split(" ").first,
            ),
            if(ad.description != null) 
              DetailRow(
                icon: Icons.description,
                label: AppLocalizations.of(context)!.descriptionLabel,
                value: ad.description ?? "",
              ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.close, style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
