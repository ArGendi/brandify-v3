import 'dart:io';

import 'package:brandify/main.dart';
import 'package:brandify/models/firebase/firestore/shopify_services.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/view/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/all_sells/all_sells_cubit.dart';
import 'package:brandify/cubits/one_product_sells/one_product_sells_cubit.dart';
import 'package:brandify/cubits/sell/sell_cubit.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/models/sell.dart';
import 'package:brandify/view/widgets/sell_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class OneProductSellsScreen extends StatefulWidget {
  final Product product;
  const OneProductSellsScreen({super.key, required this.product});

  @override
  State<OneProductSellsScreen> createState() => _OneProductSellsScreenState();
}

class _OneProductSellsScreenState extends State<OneProductSellsScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var now = DateTime.now();
    OneProductSellsCubit.get(context).getAllSellsOfProductInDateRange(
      widget.product,
      now.subtract(Duration(days: 30)),
      now,
      isFirstTime: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.productSells(widget.product.name ?? ""),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.filterByDate,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      ListTile(
                        leading: Icon(Icons.today),
                        title: Text(AppLocalizations.of(context)!.today),
                        onTap: () {
                          Navigator.pop(context);
                          OneProductSellsCubit.get(context).getAllSellsOfProductInDateRange(
                            widget.product,
                            DateTime.now(),
                            DateTime.now(),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.calendar_view_week),
                        title: Text(AppLocalizations.of(context)!.thisWeek),
                        onTap: () {
                          final now = DateTime.now();
                          final startOfWeek = now.subtract(Duration(days: 7));
                          OneProductSellsCubit.get(context).getAllSellsOfProductInDateRange(
                            widget.product,
                            startOfWeek,
                            now,
                          );
                          // OneProductSellsCubit.get(context).filterByDate(
                          //   startOfWeek,
                          //   now,
                          // );
                          
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.calendar_month),
                        title: Text(AppLocalizations.of(context)!.thisMonth),
                        onTap: () {
                          final now = DateTime.now();
                          final startOfMonth = now.subtract(Duration(days: 30));
                          OneProductSellsCubit.get(context).getAllSellsOfProductInDateRange(
                            widget.product,
                            startOfMonth,
                            now,
                          );
                          // OneProductSellsCubit.get(context).filterByDate(
                          //   startOfMonth,
                          //   now,
                          // );
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.date_range),
                        title: Text(AppLocalizations.of(context)!.customRange),
                        onTap: () async {
                          //Navigator.pop(context);
                          final DateTimeRange? picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: DateTimeRange(
                              start: DateTime.now().subtract(Duration(days: 7)),
                              end: DateTime.now(),
                            ),
                          );
                          if (picked != null) {
                            OneProductSellsCubit.get(context).getAllSellsOfProductInDateRange(
                              widget.product,
                              picked.start,
                              picked.end,
                            );
                            Navigator.pop(context);
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.clear_all),
                        title: Text(AppLocalizations.of(context)!.clearFilter),
                        onTap: () {
                          Navigator.pop(context);
                          OneProductSellsCubit.get(context).clearFilter();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: BlocBuilder<OneProductSellsCubit, OneProductSellsState>(
          builder: (context, state) {
            if (state is OneProductSellsChangedState) {
              return const Center(child: CircularProgressIndicator());
            }
            var sells = OneProductSellsCubit.get(context).filteredSells;
            return Visibility(
              visible: sells.isNotEmpty,
              replacement: Center(
                child: Text(AppLocalizations.of(context)!.noSells),
              ),
              child: ListView.separated(
                itemBuilder: (context, i){
                  return InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      showDetailsAlertDialog(context, sells[i]);
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: mainColor,
                          child: Icon(
                            Icons.shopping_bag,
                            color: Colors.white,
                          )
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "(${sells[i].quantity}) ${sells[i].product?.name}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    decoration: sells[i].isRefunded
                                        ? TextDecoration.lineThrough
                                        : null),
                              ),
                              Text(
                                sells[i].priceOfSell.toString(),
                                style: TextStyle(
                                    decoration: sells[i].isRefunded
                                        ? TextDecoration.lineThrough
                                        : null),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(sells[i].date!),
                            style: TextStyle(
                              fontSize: 10,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        if(sells[i].shopifyId != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 10),
                            Text(
                              "( ",
                              style: TextStyle(
                                fontSize: 12
                              ),
                            ),
                            FaIcon(FontAwesomeIcons.shopify, size: 15, color: Colors.green,),
                            if(sells[i].status != null)
                            SizedBox(width: 5),
                            if(sells[i].status != null)
                            Text(
                              getLocalizedShopifyStatus(context, sells[i].status),
                              style: TextStyle(
                                fontSize: 12
                              ),
                            ),
                            Text(
                              " )",
                              style: TextStyle(
                                fontSize: 12
                              ),
                            ),
                          ],
                        ),
                      SizedBox(width: 10),
                        !sells[i].isRefunded
                            ? Text(
                                sells[i].profit >= 0
                                    ? "+${sells[i].profit}"
                                    : "-${sells[i].profit}",
                                style: TextStyle(
                                  color: sells[i].profit >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.refunded,
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                      ],
                    ),
                  );
                }, 
                separatorBuilder: (context, i) => SizedBox(height: 10,), 
                itemCount: OneProductSellsCubit.get(context).filteredSells.length,
              ),
            );
          }
        ),
      ),
    );
  }

  String getLocalizedShopifyStatus(BuildContext context, String? status) {
    final localizations = AppLocalizations.of(context)!;
    switch (status) {
      case 'pending':
        return localizations.shopifyStatus_pending;
      case 'authorized':
        return localizations.shopifyStatus_authorized;
      case 'partially_paid':
        return localizations.shopifyStatus_partially_paid;
      case 'paid':
        return localizations.shopifyStatus_paid;
      case 'partially_refunded':
        return localizations.shopifyStatus_partially_refunded;
      case 'refunded':
        return localizations.shopifyStatus_refunded;
      case 'voided':
        return localizations.shopifyStatus_voided;
      default:
        return status ?? '';
    }
  }

  // void showFilterBottomSheet(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) => Container(
  //       padding: EdgeInsets.all(20),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(
  //             AppLocalizations.of(context)!.filterByDate,
  //             style: TextStyle(
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           SizedBox(height: 20),
  //           ListTile(
  //             leading: Icon(Icons.today),
  //             title: Text(AppLocalizations.of(context)!.today),
  //             onTap: () {
  //               Navigator.pop(context);
  //               OneProductSellsCubit.get(context).filterByDate(
  //                 DateTime.now(),
  //                 DateTime.now(),
  //               );
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.calendar_view_week),
  //             title: Text(AppLocalizations.of(context)!.thisWeek),
  //             onTap: () {
  //               final now = DateTime.now();
  //               final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  //               OneProductSellsCubit.get(context).filterByDate(
  //                 startOfWeek,
  //                 now,
  //               );
  //               Navigator.pop(context);
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.calendar_month),
  //             title: Text(AppLocalizations.of(context)!.thisMonth),
  //             onTap: () {
  //               final now = DateTime.now();
  //               final startOfMonth = DateTime(now.year, now.month, 1);
  //               OneProductSellsCubit.get(context).filterByDate(
  //                 startOfMonth,
  //                 now,
  //               );
  //               Navigator.pop(context);
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.date_range),
  //             title: Text(AppLocalizations.of(context)!.customRange),
  //             onTap: () async {
  //               Navigator.pop(context);
  //               final DateTimeRange? picked = await showDateRangePicker(
  //                 context: context,
  //                 firstDate: DateTime(2020),
  //                 lastDate: DateTime.now(),
  //                 initialDateRange: DateTimeRange(
  //                   start: DateTime.now().subtract(Duration(days: 7)),
  //                   end: DateTime.now(),
  //                 ),
  //               );
  //               if (picked != null) {
  //                 OneProductSellsCubit.get(context).filterByDate(
  //                   picked.start,
  //                   picked.end,
  //                 );
  //               }
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.clear_all),
  //             title: Text(AppLocalizations.of(context)!.clearFilter),
  //             onTap: () {
  //               Navigator.pop(context);
  //               OneProductSellsCubit.get(context).clearFilter();
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  void showDetailsAlertDialog(BuildContext context, Sell sell) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Center(
            child: Text(
              AppLocalizations.of(context)!.sellInformation,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 20),
          SellInfo(sell: sell),
          SizedBox(height: 20),
          if (!sell.isRefunded)
          sell.shopifyId != null? Container():
            BlocBuilder<AllSellsCubit, AllSellsState>(
              builder: (context, state) {
                if (state is LoadingRefundSellsState) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  );
                }
                return CustomButton(
                  bgColor: Colors.red,
                  onPressed: () async{
                    context.read<AllSellsCubit>().sells = context.read<OneProductSellsCubit>().filteredSells;
                    await AllSellsCubit.get(context).refund(context, sell);
                    navigatorKey.currentState?..pop()..pop();
                  },
                  text: AppLocalizations.of(context)!.refund,
                );
              },
            ),
          SizedBox(height: 10),
          CustomButton(
            onPressed: () => Navigator.pop(context),
            text: AppLocalizations.of(context)!.close,
            bgColor: Colors.grey.shade600,
          ),
        ],
      ),
    ));
  }

  Future<void> _openShopifyOrder(BuildContext context, int orderId) async {
    try {
      // Get the store ID from ShopifyServices
      final storeId = ShopifyServices.storeId;
      if (storeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shopify store not configured'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Construct the Shopify admin URL for the order
      final url = "https://admin.shopify.com/store/$storeId/orders/$orderId";
      
      // Launch the URL
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Shopify order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening Shopify order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

