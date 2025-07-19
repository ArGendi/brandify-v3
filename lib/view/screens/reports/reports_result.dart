import 'dart:io';
import 'dart:async';

import 'package:brandify/cubits/products/products_cubit.dart';
import 'package:brandify/main.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/ads/ads_cubit.dart';
import 'package:brandify/cubits/all_sells/all_sells_cubit.dart';
import 'package:brandify/cubits/extra_expenses/extra_expenses_cubit.dart';
import 'package:brandify/cubits/pie_chart/pie_chart_cubit.dart';
import 'package:brandify/cubits/reports/reports_cubit.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/models/report.dart';
import 'package:brandify/models/sell.dart';
import 'package:brandify/view/screens/all_sells_screen.dart';
import 'package:brandify/view/screens/best_products_screen.dart';
import 'package:brandify/view/screens/pie_chart_screen.dart';
import 'package:brandify/view/widgets/ad_item.dart';
import 'package:brandify/view/widgets/custom_button.dart';
import 'package:brandify/view/widgets/expense_item.dart';
import 'package:brandify/view/widgets/loading.dart';
import 'package:brandify/view/widgets/report_card.dart';
import 'package:brandify/view/widgets/reports/pie_chart_section.dart';
import 'package:brandify/view/widgets/reports/recent_transactions_section.dart';
import 'package:brandify/view/widgets/reports/report_summary_section.dart';
import 'package:brandify/view/widgets/sell_info.dart';
import 'package:brandify/view/widgets/recent_sell_item.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:brandify/view/widgets/detail_row.dart';
import 'package:brandify/models/firebase/firestore/shopify_services.dart';

class ReportsResult extends StatefulWidget {
  final String title;
  final DateTime from;
  final DateTime to;
  const ReportsResult({
    super.key,
    this.title = "Report",
    required this.from,
    required this.to,
  });

  @override
  State<ReportsResult> createState() => _ReportsResultState();
}

class _ReportsResultState extends State<ReportsResult> {
  String? loadingMessage;
  Timer? _timer4s;
  Timer? _timer8s;

  void getReportData() async {
    context.read<ReportsCubit>().startLoading();
    int adsCost = await context.read<AdsCubit>().getAdsInDateRange(widget.from, widget.to);
    int expensesCost = await context.read<ExtraExpensesCubit>().getExpensesInDateRange(
      widget.from,
      widget.to,
    );
    await context.read<AllSellsCubit>().getSellsInDateRange(
      widget.from,
      widget.to,
      expenses: expensesCost + adsCost,
      allProducts: context.read<ProductsCubit>().products,
    );
    context.read<ReportsCubit>().setCurrentReport(
      context.read<AllSellsCubit>().sells,
      context.read<AdsCubit>().ads,
      context.read<ExtraExpensesCubit>().expenses,
      widget.from,
      widget.to,
    );
    PieChartCubit.get(
      context,
    ).buildPieChart(ReportsCubit.get(context).currentReport?.sells ?? []);
  }

  @override
  void initState() {
    super.initState();
    loadingMessage = null;
    _timer4s = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => loadingMessage = AppLocalizations.of(context)!.loadingDoingMyBest);
    });
    _timer8s = Timer(const Duration(seconds: 16), () {
      if (mounted) setState(() => loadingMessage = AppLocalizations.of(context)!.loadingAreYouReady);
    });
    getReportData();
  }

  @override
  void dispose() {
    _timer4s?.cancel();
    _timer8s?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var current = ReportsCubit.get(context).currentReport;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Color(0xFF5E6C58),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareReport(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5E6C58), Color(0xFFECEFEB)],
            stops: [0.0, 0.3],
          ),
        ),
        child: BlocBuilder<ReportsCubit, ReportsState>(
          builder: (context, state) {
            if(state is LoadingReportsState){
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LoadingAnimationWidget.inkDrop(
                      color: mainColor,
                      size: 40,
                    ),
                    if (loadingMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        loadingMessage!,
                        style: const TextStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: ListView(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(25),
                    margin: const EdgeInsets.only(top: 10, bottom: 25),
                    child: ReportSummarySection(),
                  ),
                  // Sales Distribution Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(25),
                    margin: const EdgeInsets.only(bottom: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pie_chart, color: Color(0xFF5E6C58)),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!.salesDistribution,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5E6C58),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        PieChartSection(),
                      ],
                    ),
                  ),
                  // Highest Products Button
                  Container(
                    margin: const EdgeInsets.only(bottom: 25),
                    child: _buildHighestProductsButton(context, current),
                  ),
                  // Recent Transactions Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long, color: Color(0xFF5E6C58)),
                            const SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(context)!.recentTransactions,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5E6C58),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        RecentTransactionsSection(
                          showSellDetails:
                              (context, sell) =>
                                  _showSellDetails(context, sell),
                          showExpenseDetails: _showExpenseDetails,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHighestProductsButton(BuildContext context, dynamic current) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        if ((ReportsCubit.get(context).currentReport?.sells ?? []).isNotEmpty) {
          return CustomButton(
            text: AppLocalizations.of(context)!.showHighestProducts,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => BestProductsScreen(),
                ),
              );
            },
          );
        }
        return Center(
          child: Text(AppLocalizations.of(context)!.startSellingToSeeResults),
        );
      },
    );
  }

  void _showExpenseDetails(BuildContext context, dynamic exp) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.expenseDetails,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                DetailRow(
                  icon: Icons.info,
                  label: AppLocalizations.of(context)!.nameLabel,
                  value: exp.name ?? "",
                ),
                SizedBox(height: 10),
                DetailRow(
                  icon: Icons.info,
                  label: AppLocalizations.of(context)!.price,
                  value: "${exp.price} LE",
                ),
                SizedBox(height: 10),
                DetailRow(
                  icon: Icons.info,
                  label: AppLocalizations.of(context)!.date,
                  value: exp.date.toString().split(' ')[0],
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.close),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showSellDetails(BuildContext context, Sell sell) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.orderDetails,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5E6C58),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SellInfo(sell: sell),
                const SizedBox(height: 20),
                if (!sell.isRefunded)
                  sell.shopifyId != null
                      ? Container()
                      : BlocBuilder<AllSellsCubit, AllSellsState>(
                        builder: (context, state) {
                          if (state is LoadingRefundSellsState) {
                            return Center(child: Loading());
                          } else {
                            return CustomButton(
                              text: AppLocalizations.of(context)!.refundButton,
                              onPressed: () {
                                AllSellsCubit.get(
                                  context,
                                ).refund(context, sell);
                              },
                            );
                          }
                        },
                      ),
                if (!sell.isRefunded) const SizedBox(height: 10),
                CustomButton(
                  text: AppLocalizations.of(context)!.close,
                  onPressed: () => Navigator.pop(context),
                  bgColor: Color(0xFF5E6C58),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _shareReport(BuildContext context) async {
    var current = ReportsCubit.get(context).currentReport;
    if (current != null) {
      // Calculate product summary from sells
      final Map<String, Map<String, dynamic>> productSummary = {};
      for (var sell in current.sells) {
        if (sell.isRefunded) continue;
        
        // Use a more reliable key - prefer backendId, then shopifyId, then name
        String productKey = '';
        if (sell.product?.backendId != null) {
          productKey = sell.product!.backendId!;
        } else if (sell.product?.shopifyId != null) {
          productKey = sell.product!.shopifyId.toString();
        } else if (sell.product?.name != null) {
          productKey = sell.product!.name!;
        } else {
          continue; // Skip if no reliable identifier
        }
        
        if (!productSummary.containsKey(productKey)) {
          productSummary[productKey] = {
            'name': sell.product?.name ?? 'Unknown Product',
            'quantity': 0,
            'totalPrice': 0.0,
            'totalProfit': 0.0,
          };
        }
        
        // Add the current sell's data to the product summary
        productSummary[productKey]!['quantity'] += sell.quantity ?? 0;
        productSummary[productKey]!['totalPrice'] += (sell.priceOfSell ?? 0) * (sell.quantity ?? 0);
        productSummary[productKey]!['totalProfit'] += sell.profit * (sell.quantity ?? 0);
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build:
              (context) => [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    AppLocalizations.of(
                      navigatorKey.currentContext!,
                    )!.salesReport,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Paragraph(
                  text:
                      '${current.dateRange!.start.toString().split(' ')[0]} to ${current.dateRange!.end.toString().split(' ')[0]}',
                ),
                pw.SizedBox(height: 20),

                // Summary Section
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    AppLocalizations.of(navigatorKey.currentContext!)!.summary,
                  ),
                ),
                pw.Table.fromTextArray(
                  context: context,
                  data: [
                    [
                      AppLocalizations.of(navigatorKey.currentContext!)!.metric,
                      AppLocalizations.of(navigatorKey.currentContext!)!.value,
                    ],
                    [
                      AppLocalizations.of(
                        navigatorKey.currentContext!,
                      )!.totalSales,
                      '${current.noOfSells}',
                    ],
                    [
                      AppLocalizations.of(navigatorKey.currentContext!)!.profit,
                      '${AppLocalizations.of(navigatorKey.currentContext!)!.currency(current.totalProfit)}',
                    ],
                    [
                      AppLocalizations.of(
                        navigatorKey.currentContext!,
                      )!.totalExpenses,
                      '${AppLocalizations.of(navigatorKey.currentContext!)!.currency(current.totalExtraExpensesCost + current.totalAdsCost)}',
                    ],
                  ],
                ),
                pw.SizedBox(height: 20),

                // Products Section
                if (productSummary.isNotEmpty) ...[
                  pw.Header(
                    level: 1,
                    child: pw.Text(
                      AppLocalizations.of(
                        navigatorKey.currentContext!,
                      )!.productsSummary,
                    ),
                  ),
                  pw.Table.fromTextArray(
                    context: context,
                    headers: [
                      AppLocalizations.of(
                        navigatorKey.currentContext!,
                      )!.product,
                      AppLocalizations.of(
                        navigatorKey.currentContext!,
                      )!.quantitySold,
                      AppLocalizations.of(
                        navigatorKey.currentContext!,
                      )!.totalRevenue,
                      AppLocalizations.of(navigatorKey.currentContext!)!.profit,
                    ],
                    data:
                        productSummary.values
                            .map(
                              (product) => [
                                product['name'],
                                product['quantity'].toString(),
                                '${AppLocalizations.of(navigatorKey.currentContext!)!.priceAmount(product['totalPrice'])}',
                                '${AppLocalizations.of(navigatorKey.currentContext!)!.priceAmount(product['totalProfit'])}',
                              ],
                            )
                            .toList(),
                  ),
                  pw.SizedBox(height: 20),
                ],

                // Ads Section
                if (current.ads.isNotEmpty) ...[
                  pw.Header(
                    level: 1,
                    child: pw.Text(
                      AppLocalizations.of(navigatorKey.currentContext!)!.ads,
                    ),
                  ),
                  pw.Table.fromTextArray(
                    context: context,
                    headers: [
                      AppLocalizations.of(
                        navigatorKey.currentContext!,
                      )!.nameLabel,
                      AppLocalizations.of(navigatorKey.currentContext!)!.cost,
                      AppLocalizations.of(navigatorKey.currentContext!)!.date,
                    ],
                    data:
                        current.ads
                            .map(
                              (ad) => [
                                ad.platform?.name ?? '',
                                '${AppLocalizations.of(navigatorKey.currentContext!)!.priceAmount(ad.cost ?? 0)}',
                                ad.date.toString().split(' ')[0],
                              ],
                            )
                            .toList(),
                  ),
                  pw.SizedBox(height: 20),
                ],

                // Expenses Section
                if (current.extraExpenses.isNotEmpty) ...[
                  pw.Header(
                    level: 1,
                    child: pw.Text(
                      AppLocalizations.of(
                        navigatorKey.currentContext!,
                      )!.expensesSummary,
                    ),
                  ),
                  pw.Table.fromTextArray(
                    context: context,
                    headers: [
                      AppLocalizations.of(
                        navigatorKey.currentContext!,
                      )!.nameLabel,
                      AppLocalizations.of(navigatorKey.currentContext!)!.cost,
                      AppLocalizations.of(navigatorKey.currentContext!)!.date,
                    ],
                    data:
                        current.extraExpenses
                            .map(
                              (expense) => [
                                expense.name ?? '',
                                '${AppLocalizations.of(navigatorKey.currentContext!)!.priceAmount(expense.price ?? 0)}',
                                expense.date.toString().split(' ')[0],
                              ],
                            )
                            .toList(),
                  ),
                ],

                // Footer
                pw.Footer(
                  trailing: pw.Text(
                    AppLocalizations.of(
                      navigatorKey.currentContext!,
                    )!.generatedByBrandify(
                      DateTime.now().toString().split(' ')[0],
                    ),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
        ),
      );

      // Save the PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sales_report.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path),], 
          text: AppLocalizations.of(context)!.salesReport,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        )
      );
    }
  }

  Future<void> _openShopifyOrder(BuildContext context, int orderId) async {
    try {
      // Get the store ID from ShopifyServices
      final storeId = ShopifyServices.storeId;
      if (storeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.shopifyStoreNotConfigured,
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Construct the Shopify admin URL for the order
      final url = "https://admin.shopify.com/";

      // Launch the URL
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.couldNotOpenShopifyOrder,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.errorOpeningShopifyOrder(e.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
