import 'package:brandify/cubits/app_user/app_user_cubit.dart';
import 'package:brandify/enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/ads/ads_cubit.dart';
import 'package:brandify/cubits/all_sells/all_sells_cubit.dart';
import 'package:brandify/cubits/extra_expenses/extra_expenses_cubit.dart';
import 'package:brandify/cubits/reports/reports_cubit.dart';
import 'package:brandify/cubits/sell/sell_cubit.dart';
import 'package:brandify/main.dart';
import 'package:brandify/models/ad.dart';
import 'package:brandify/models/extra_expense.dart';
import 'package:brandify/models/sell.dart';
import 'package:brandify/view/screens/reports/reports_result.dart';
import 'package:brandify/view/screens/reports/tabs/day_tab.dart';
import 'package:brandify/view/screens/reports/tabs/month_tab.dart';
import 'package:brandify/view/screens/reports/tabs/week_tab.dart';
import 'package:brandify/view/screens/reports/tabs/year_tab.dart';
import 'package:brandify/view/widgets/custom_button.dart';
import 'package:brandify/view/widgets/report_wide_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // List<Sell> allSells = AllSellsCubit.get(context).sells;
    // List<Ad> allAds = AdsCubit.get(context).ads;
    // List<ExtraExpense> allExtraExpenses =
    //     ExtraExpensesCubit.get(context).expenses;
    // print("saleeeeeees::::: $allSells");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reports,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xFFD5E4DD),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD5E4DD), // Main color
              Color(0xFFF5F8F6), // Lighter variant
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: mainColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: BlocBuilder<ReportsCubit, ReportsState>(
                  builder: (context, state) {
                    if(!context.read<AppUserCubit>().privileges.contains(Privilege.viewReports)){
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_off_rounded),
                              SizedBox(height: 10,),
                              Text("You don't have the access"),
                            ],
                          ),
                        ),
                      );
                    }
                    else if(ReportsCubit.get(context).isLoading){
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context)!.loadingReports,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    else return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildReportCard(
                                context,
                                AppLocalizations.of(context)!.today,
                                ReportsCubit.get(context).today?.totalProfit ??
                                    0,
                                mainColor, //Color(0xFF93B0A2), // Darker variant
                                () {
                                  var now = DateTime.now();
                                  return _navigateToReport(
                                    context, AppLocalizations.of(context)!.today,
                                    DateTime(now.year, now.month, now.day),
                                    DateTime(now.year, now.month, now.day).add(Duration(days: 1)),
                                  );
                                }
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildReportCard(
                                context,
                                AppLocalizations.of(context)!.sevenDays,
                                ReportsCubit.get(context).week?.totalProfit ??
                                    0,
                                mainColor,//Color(0xFF7D9889), // Even darker
                                () {
                                  var now = DateTime.now();
                                  return _navigateToReport(
                                    context,
                                    AppLocalizations.of(context)!.thisWeek,
                                    now.subtract(Duration(days: 7)),
                                    now,
                                  );
                                }
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildReportCard(
                                context,
                                AppLocalizations.of(context)!.thisMonth,
                                ReportsCubit.get(context).month?.totalProfit ??
                                    0,
                                mainColor,//Color(0xFF678073), // More darker
                                () {
                                  var now = DateTime.now();
                                  return _navigateToReport(
                                    context,
                                    AppLocalizations.of(context)!.thisMonth,
                                    DateTime(now.year, now.month),
                                    now,
                                  );
                                }
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildReportCard(
                                context,
                                AppLocalizations.of(context)!.threeMonths,
                                ReportsCubit.get(context)
                                        .threeMonths
                                        ?.totalProfit ??
                                    0,
                                mainColor,//Color(0xFF51685D), // Darkest variant
                                () {
                                  var now = DateTime.now();
                                  return _navigateToReport(
                                    context,
                                    AppLocalizations.of(context)!.threeMonths,
                                    DateTime(now.year, now.month - 2),
                                    now,
                                  );
                                }
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),
              if(context.read<AppUserCubit>().privileges.contains(Privilege.viewReports))
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: mainColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(AppLocalizations.of(context)!.customRange,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              )),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<ReportsCubit, ReportsState>(
                      builder: (context, state) => _buildDateButton(
                        context,
                        ReportsCubit.get(context).fromDate == null
                            ? AppLocalizations.of(context)!.selectStartDate
                            : ReportsCubit.get(context).getFromDate(),
                        Icons.calendar_today,
                        () => _selectFromDate(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    BlocBuilder<ReportsCubit, ReportsState>(
                      builder: (context, state) => _buildDateButton(
                        context,
                        ReportsCubit.get(context).toDate == null
                            ? AppLocalizations.of(context)!.selectEndDate
                            : ReportsCubit.get(context).getToDate(),
                        Icons.calendar_today,
                        () => _selectToDate(context),
                      ),
                    ),
                    const SizedBox(height: 15),
                    CustomButton(
                      text: AppLocalizations.of(context)!.generateReport,
                      icon: const Icon(Icons.analytics, color: Colors.white),
                      onPressed: () => _generateReport(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, num profit,
      Color color, VoidCallback onTap) {
    String sign = profit > 0 ? "+" : "";
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "",//"$sign$profit",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(BuildContext context, String text, IconData icon,
      VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: mainColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: mainColor),
              const SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(
                  color: mainColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add these functions after the existing widget methods

  void _navigateToReport(BuildContext context, String title, DateTime from, DateTime to) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsResult(
          title: title,
          from: from,
          to: to,
        ),
      ),
    );
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ReportsCubit.get(context).setFromDate(picked);
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ReportsCubit.get(context).setToDate(picked);
    }
  }

  void _generateReport(BuildContext context) {
    if (ReportsCubit.get(context).fromDate != null &&
        ReportsCubit.get(context).toDate != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportsResult(
            from: ReportsCubit.get(context).fromDate!,
            to: ReportsCubit.get(context).toDate!,
          ),
        ),
      );
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectDateFromAndToFirst))
      );
    }
  }
}
