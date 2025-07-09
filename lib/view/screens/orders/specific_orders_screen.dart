import 'package:brandify/constants.dart';
import 'package:brandify/cubits/app_user/app_user_cubit.dart';
import 'package:brandify/main.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brandify/cubits/all_sells/all_sells_cubit.dart';
import 'package:brandify/models/sell.dart';
import 'package:brandify/view/widgets/custom_button.dart';
import 'package:brandify/view/widgets/loading.dart';
import 'package:brandify/view/widgets/recent_sell_item.dart';
import 'package:brandify/view/widgets/sell_info.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:brandify/models/firebase/firestore/shopify_services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:brandify/view/widgets/custom_texfield.dart';

class SpecificOrdersScreen extends StatefulWidget {
  final List<Sell> orders;

  const SpecificOrdersScreen({super.key, required this.orders});

  @override
  State<SpecificOrdersScreen> createState() => _SpecificOrdersScreenState();
}

class _SpecificOrdersScreenState extends State<SpecificOrdersScreen> {
  List<Sell> filteredOrders = [];
  List<Sell> selectedOrders = []; // Add this
  bool isSelectionMode = false; // Add this
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    filteredOrders = List.from(widget.orders);
  }

  double calculateTotalProfit() {
    return filteredOrders
        .where((order) => !order.isRefunded)
        .fold(0, (sum, order) => sum + (order.profit));
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        filteredOrders =
            widget.orders.where((order) {
              return order.date != null &&
                  order.date!.isAfter(
                    picked.start.subtract(Duration(days: 1)),
                  ) &&
                  order.date!.isBefore(picked.end.add(Duration(days: 1)));
            }).toList();
      });
    }
  }

  Future<void> _createAndShareReceipt() async {
    final l10n = AppLocalizations.of(context)!;
    final pdf = pw.Document();
    int quantity = 0;

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              AppUserCubit.get(navigatorKey.currentContext!).brandName ?? l10n.ordersReceipt,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            DateTime.now().toString().split(".").first,
            style: pw.TextStyle(
              fontSize: 10,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.SizedBox(height: 20),

          ...selectedOrders.map((order) {
            quantity += order.quantity ?? 0;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // pw.Text(
                //   '${l10n.orderDate}: ${order.date?.toString().split(' ')[0]}',
                // ),
                pw.Text('${l10n.product}: ${order.product?.name}'),
                pw.Text('${l10n.size}: ${order.size?.name ?? l10n.notAvailable}'),
                pw.Text('${l10n.quantityLabel(order.quantity ?? 0)}'),
                pw.Text('${l10n.price}: ${l10n.currency(order.priceOfSell ?? 0)}'),
                if (order.isRefunded)
                  pw.Text(
                    l10n.refunded,
                    style: pw.TextStyle(
                      color: PdfColors.red,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                pw.SizedBox(height: 5),
                pw.Divider(),
              ],
            );
          }).toList(),

          pw.SizedBox(height: 20),
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${l10n.totalOrders}: $quantity'),
              pw.Text(
                '${l10n.total}: ${l10n.currency(selectedOrders.fold(0.0, (double sum, Sell order) => sum + (order.priceOfSell ?? 0)).toString())}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),

          // pw.Footer(
          //   leading: pw.Text(
          //     l10n.fromBrandify(
          //       Cache.getName() ?? 'Brandify',
          //       DateTime.now().toString().split(' ')[0],
          //     ),
          //     style: pw.TextStyle(
          //       fontSize: 10,
          //       fontStyle: pw.FontStyle.italic,
          //     ),
          //   ),
          // ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/orders_receipt.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: AppLocalizations.of(context)!.ordersReceipt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double totalProfit = calculateTotalProfit();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orders),
        actions: [
          IconButton(
            icon: Icon(isSelectionMode ? Icons.close : Icons.checklist_rtl),
            onPressed: () {
              setState(() {
                isSelectionMode = !isSelectionMode;
                selectedOrders.clear();
              });
            },
          ),
          // if (isSelectionMode && selectedOrders.isNotEmpty)
          //   IconButton(
          //     icon: Icon(Icons.share),
          //     onPressed: _createAndShareReceipt,
          //   ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CustomTextFormField(
              text: l10n.searchProducts,
              hintText: l10n.searchProducts,
              onSaved: (_) {},
              onChange: (value) {
                setState(() {
                  filteredOrders = widget.orders.where((order) {
                    final productName = order.product?.name?.toLowerCase() ?? '';
                    final search = value?.toLowerCase() ?? '';
                    return productName.contains(search);
                  }).toList();
                });
              },
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.totalProfit,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${AppLocalizations.of(context)!.priceAmount(totalProfit)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          totalProfit >= 0
                              ? Colors.green[700]
                              : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            if (selectedDateRange != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  l10n.ordersFromTo(
                    DateFormat('MMM d, y').format(selectedDateRange!.start),
                    DateFormat('MMM d, y').format(selectedDateRange!.end),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<AllSellsCubit, AllSellsState>(
                builder: (context, state) {
                  return ListView.separated(
                    itemBuilder:
                        (context, i) => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                selectedOrders.contains(filteredOrders[i])
                                    ? Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.08)
                                    : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: RecentSellItem(
                            sell: filteredOrders[i],
                            onTap: (x, y) => _handleOrderTap(i),
                          ),
                        ),
                    separatorBuilder: (_, __) => SizedBox(height: 10),
                    itemCount: filteredOrders.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          isSelectionMode && selectedOrders.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: _createAndShareReceipt,
                label: Text(l10n.createReceipt),
                icon: Icon(Icons.share),
              )
              : null,
    );
  }

  void _handleOrderTap(int index) {
    if (isSelectionMode) {
      setState(() {
        if (selectedOrders.contains(filteredOrders[index])) {
          selectedOrders.remove(filteredOrders[index]);
          if (selectedOrders.isEmpty) {
            isSelectionMode = false;
          }
        } else {
          selectedOrders.add(filteredOrders[index]);
        }
      });
    } else {
      _showSellDetails(context, filteredOrders[index]);
    }
  }

  void _showSortBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.sortByProfit,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.arrow_upward),
                  title: Text(l10n.highestProfit),
                  onTap: () {
                    setState(() {
                      filteredOrders.sort(
                        (a, b) => b.profit.compareTo(a.profit),
                      );
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.arrow_downward),
                  title: Text(l10n.lowestProfit),
                  onTap: () {
                    setState(() {
                      filteredOrders.sort(
                        (a, b) => a.profit.compareTo(b.profit),
                      );
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showSellDetails(BuildContext context, Sell sell) {
    final l10n = AppLocalizations.of(context)!;
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
                    l10n.orderDetails,
                    style: Theme.of(context).textTheme.titleLarge,
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
                                text: l10n.refund,
                                onPressed: () {
                                  AllSellsCubit.get(context).refund(context, sell);
                                },
                                //bgColor: Color(0xFF5E6C58),
                              );
                            }
                          },
                        ),
                if (!sell.isRefunded) const SizedBox(height: 10),
                CustomButton(
                  text: l10n.close,
                  onPressed: () => Navigator.pop(context),
                  bgColor: Color(0xFF5E6C58),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _openShopifyOrder(BuildContext context, int orderId) async {
    try {
      // Get the store ID from ShopifyServices
      final storeId = ShopifyServices.storeId;
      if (storeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.shopifyStoreNotConfigured),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Construct the Shopify admin URL for the order
      final url = 'https://admin.shopify.com/';

      
      // Launch the URL
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.couldNotOpenShopifyOrder),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorOpeningShopifyOrder(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
