import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:brandify/models/ad.dart';
import 'package:brandify/models/extra_expense.dart';
import 'package:brandify/models/report.dart';
import 'package:brandify/models/sell.dart';
import 'package:brandify/view/screens/reports/reports_result.dart';
import 'package:brandify/utils/date_utils.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
   Report? today;
   Report? week;
   Report? month;
   Report? threeMonths;
   DateTime? fromDate;
   DateTime? toDate;
   Report? currentReport;
   bool isLoading = false;

  ReportsCubit() : super(ReportsInitial());
  static ReportsCubit get(BuildContext context) => BlocProvider.of(context);

  void setIsLoading(bool value){
    isLoading = value;
    emit(GetReportState());
  }

  void setTodayReport(List<Sell> sells, List<Ad> ads, List<ExtraExpense> extraExpenses){

    List<Sell> todaySells = sells.where((e) => e.date!.difference(DateTime.now()).inDays == 0).toList();
    List<Sell> unRefundedSells = todaySells.where((e) => e.isRefunded == false).toList(); 
    List<Ad> todayAds = ads.where((e) => e.date!.difference(DateTime.now()).inDays == 0).toList();
    List<ExtraExpense> todayExtraExpenses = extraExpenses.where((e) => e.date!.difference(DateTime.now()).inDays == 0).toList();
    int totalIncome = 0;
    int totalProfit = 0;
    int totalNumberOfSells = 0;
    int totalAds = 0;
    int totalExtraExpense = 0;

    for(var sell in unRefundedSells){
      if(!sell.isRefunded){
        if(sell.shopifyId != null && sell.status != "paid"){
          continue;
        }
        totalIncome += sell.priceOfSell!;
        totalProfit += sell.profit;
        totalNumberOfSells += sell.quantity ?? 0;
      }
    }
    for(var ad in todayAds){
      totalProfit -= ad.cost ?? 0;
      totalAds += ad.cost?? 0;
    }
    for(var extraExpense in todayExtraExpenses){
      totalProfit -= extraExpense.price ?? 0;
      totalExtraExpense += extraExpense.price?? 0;
    }

    todaySells.sort((a,b) => b.date!.compareTo(a.date!));
    today = Report(
      noOfSells: totalNumberOfSells,
      totalIncome: totalIncome,
      totalProfit: totalProfit,
      totalAdsCost: totalAds,
      totalExtraExpensesCost: totalExtraExpense,
      sells: todaySells,
      ads: todayAds,
      extraExpenses: todayExtraExpenses,
      dateRange: DateTimeRange(start: DateTime.now().subtract(Duration(days: 1)), end: DateTime.now()),
    );
    emit(GetReportState());
  }

  void setWeekReport(List<Sell> sells, List<Ad> ads, List<ExtraExpense> extraExpenses){
    List<Sell> weekSells = sells.where((e) => DateTime.now().difference(e.date!).inDays <= 7).toList();
    List<Ad> weekAds = ads.where((e) => DateTime.now().difference(e.date!).inDays <= 7).toList();
    List<ExtraExpense> weekExtraExpenses = extraExpenses.where((e) => DateTime.now().difference(e.date!).inDays <= 7).toList();
    int totalIncome = 0;
    int totalProfit = 0;
    int totalNumberOfSells = 0;
    int totalAds = 0;
    int totalExtraExpense = 0;

    for(var sell in weekSells){
      if(!sell.isRefunded){
        if(sell.shopifyId != null && sell.status != "paid"){
          continue;
        }
        totalIncome += sell.priceOfSell!;
        totalProfit += sell.profit;
        totalNumberOfSells += sell.quantity ?? 0;
      }
    }
    for(var ad in weekAds){
      totalProfit -= ad.cost ?? 0;
      totalAds += ad.cost?? 0;
    }
    for(var extraExpense in weekExtraExpenses){
      totalProfit -= extraExpense.price ?? 0;
      totalExtraExpense += extraExpense.price?? 0;
    }

    weekSells.sort((a,b) => b.date!.compareTo(a.date!));
    week = Report(
      noOfSells: totalNumberOfSells,
      totalIncome: totalIncome,
      totalProfit: totalProfit,
      totalAdsCost: totalAds,
      totalExtraExpensesCost: totalExtraExpense,
      sells: weekSells,
      ads: weekAds,
      extraExpenses: weekExtraExpenses,
      dateRange: DateTimeRange(start: DateTime.now().subtract(Duration(days: 7)), end: DateTime.now()),
    );
    emit(GetReportState());
  }

  void setMonthReport(List<Sell> sells, List<Ad> ads, List<ExtraExpense> extraExpenses){
    List<Sell> monthSells = sells.where((e) => DateTime.now().difference(e.date!).inDays <= 30).toList();
    List<Ad> monthAds = ads.where((e) => DateTime.now().difference(e.date!).inDays <= 30).toList();
    List<ExtraExpense> monthExtraExpenses = extraExpenses.where((e) => DateTime.now().difference(e.date!).inDays <= 30).toList();
    int totalIncome = 0;
    int totalProfit = 0;
    int totalNumberOfSells = 0;
    int totalAds = 0;
    int totalExtraExpense = 0;

    for(var sell in monthSells){
      if(!sell.isRefunded){
        if(sell.shopifyId != null && sell.status != "paid"){
          continue;
        }
        totalIncome += sell.priceOfSell!;
        totalProfit += sell.profit;
        totalNumberOfSells += sell.quantity ?? 0;
      }
    }
    for(var ad in monthAds){
      totalProfit -= ad.cost ?? 0;
      totalAds += ad.cost?? 0;
    }
    for(var extraExpense in monthExtraExpenses){
      totalProfit -= extraExpense.price ?? 0;
      totalExtraExpense += extraExpense.price?? 0;
    }

    monthSells.sort((a,b) => b.date!.compareTo(a.date!));
    month = Report(
      noOfSells: totalNumberOfSells,
      totalIncome: totalIncome,
      totalProfit: totalProfit,
      totalAdsCost: totalAds,
      totalExtraExpensesCost: totalExtraExpense,
      sells: monthSells,  
      ads: monthAds,
      extraExpenses: monthExtraExpenses,
      dateRange: DateTimeRange(start: DateTime.now().subtract(Duration(days: 30)), end: DateTime.now()),
    );
    emit(GetReportState());
  }

  void setThreeMonthsReport(List<Sell> sells, List<Ad> ads, List<ExtraExpense> extraExpenses){
    List<Sell> threeMonthsells = sells.where((e) => DateTime.now().difference(e.date!).inDays <= 90).toList();
    List<Ad> threeMonthsAds = ads.where((e) => DateTime.now().difference(e.date!).inDays <= 90).toList();
    List<ExtraExpense> threeMonthsExtraExpenses = extraExpenses.where((e) => DateTime.now().difference(e.date!).inDays <= 90).toList();
    int totalIncome = 0;
    int totalProfit = 0;
    int totalNumberOfSells = 0;
    int totalAds = 0;
    int totalExtraExpense = 0;
    
    for(var sell in threeMonthsells){
      if(!sell.isRefunded){
        if(sell.shopifyId != null && sell.status != "paid"){
          continue;
        }
        totalIncome += sell.priceOfSell!;
        totalProfit += sell.profit;
        totalNumberOfSells += sell.quantity ?? 0;
      }
    }
    for(var ad in threeMonthsAds){
      totalProfit -= ad.cost ?? 0;
      totalAds += ad.cost?? 0;
    }
    for(var extraExpense in threeMonthsExtraExpenses){
      totalProfit -= extraExpense.price ?? 0;
      totalExtraExpense += extraExpense.price?? 0;
    }

    threeMonthsells.sort((a,b) => b.date!.compareTo(a.date!));
    threeMonths = Report(
      noOfSells: totalNumberOfSells,
      totalIncome: totalIncome,
      totalProfit: totalProfit,
      totalAdsCost: totalAds,
      totalExtraExpensesCost: totalExtraExpense,
      sells: threeMonthsells,
      ads: threeMonthsAds,
      extraExpenses: threeMonthsExtraExpenses,
      dateRange: DateTimeRange(start: DateTime.now().subtract(Duration(days: 90)), end: DateTime.now()),
    );
    emit(GetReportState());
  }

  Report setFromToReport(List<Sell> sells, List<Ad> ads, List<ExtraExpense> extraExpenses){
    List<Sell> temp = sells.where((e) => isBetweenInclusive(e.date!, fromDate!, toDate!)).toList();
    List<Ad> tempAds = ads.where((e) => isBetweenInclusive(e.date!, fromDate!, toDate!)).toList();
    List<ExtraExpense> tempExtraExpenses = extraExpenses.where((e) => isBetweenInclusive(e.date!, fromDate!, toDate!)).toList();
    int totalIncome = 0;
    int totalProfit = 0;
    int totalNumberOfSells = 0;
    int totalAds = 0;
    int totalExtraExpense = 0;

    for(var sell in temp){
      if(!sell.isRefunded){
        if(sell.shopifyId != null && sell.status != "paid"){
          continue;
        }
        totalIncome += sell.priceOfSell!;
        totalProfit += sell.profit;
        totalNumberOfSells += sell.quantity ?? 0;
      }
    }
    for(var ad in tempAds){
      totalProfit -= ad.cost ?? 0;
      totalAds += ad.cost?? 0;
    }
    for(var extraExpense in tempExtraExpenses){
      totalProfit -= extraExpense.price ?? 0;
      totalExtraExpense += extraExpense.price?? 0;
    }

    temp.sort((a,b) => b.date!.compareTo(a.date!));
    return Report(
      noOfSells: totalNumberOfSells,
      totalIncome: totalIncome,
      totalProfit: totalProfit,
      totalAdsCost: totalAds,
      totalExtraExpensesCost: totalExtraExpense,
      sells: temp,
      ads: tempAds,
      extraExpenses: tempExtraExpenses,
      dateRange: DateTimeRange(start: fromDate!, end: toDate!),
    );
  }

  bool isBetweenInclusive(DateTime target, DateTime start, DateTime end) {
    return DateTimeUtils.isBetweenInclusive(target, start, end);
  }

  void setFromDate(DateTime value){
    fromDate = value;
    emit(GetReportState());
  }

  void setToDate(DateTime value){
    toDate = value;
    emit(GetReportState());
  }

  String getFromDate(){
    return "${fromDate?.day}/${fromDate?.month}/${fromDate?.year}";
  }

  String getToDate(){
    return "${toDate?.day}/${toDate?.month}/${toDate?.year}";
  }

  void onGetResults(BuildContext context, List<Sell> sells, List<Ad> ads, List<ExtraExpense> extraExpenses){
    if(fromDate != null && toDate != null){
      currentReport = setFromToReport(sells, ads, extraExpenses);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsResult()));
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectDateFromAndToFirst))
      );
    }
  }

  void deductFromCurrentReport(int quantity, int profit, int totalIncome){
    currentReport?.noOfSells -= quantity;
    currentReport?.totalProfit -= profit;
    currentReport?.totalIncome -= totalIncome;

    currentReport != today ? today?.totalProfit -= profit : null;
    currentReport != week ? week?.totalProfit -= profit : null;
    currentReport != month ? month?.totalProfit -= profit : null;
    currentReport != threeMonths ? threeMonths?.totalProfit -= profit : null;
    emit(GetReportState());
  }

  void markRefundSell(Sell value){
    int i = currentReport?.sells.indexOf(value) ?? -1;
    if(i != -1){
      currentReport?.sells[i].isRefunded = true;
      emit(SellRemovedFromReportState());
    }
  }
  
  Report? customReport;
  
  void setCustomReport(
    List<Sell> allSells,
    List<Ad> allAds,
    List<ExtraExpense> allExtraExpenses,
    DateTime fromDate,
    DateTime toDate,
  ) {
    List<Sell> periodSells = allSells.where((sell) {
      return sell.date!.isAfter(fromDate.subtract(const Duration(days: 1))) &&
          sell.date!.isBefore(toDate.add(const Duration(days: 1)));
    }).toList();
  
    List<Ad> periodAds = allAds.where((ad) {
      return ad.date!.isAfter(fromDate.subtract(const Duration(days: 1))) &&
          ad.date!.isBefore(toDate.add(const Duration(days: 1)));
    }).toList();
  
    List<ExtraExpense> periodExpenses = allExtraExpenses.where((expense) {
      return expense.date!.isAfter(fromDate.subtract(const Duration(days: 1))) &&
          expense.date!.isBefore(toDate.add(const Duration(days: 1)));
    }).toList();
  
    customReport = Report(
      sells: periodSells,
      ads: periodAds,
      extraExpenses: periodExpenses,
    );
    
    currentReport = customReport;
    emit(SetCustomReportState());
  }

  void reset(){
    today = null;
    week = null;
    month = null;
    threeMonths = null;
    customReport = null;
    fromDate = null;
    toDate = null;
    emit(ReportsInitial());
  }
}
