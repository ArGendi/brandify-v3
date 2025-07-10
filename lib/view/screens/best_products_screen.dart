import 'dart:io';

import 'package:brandify/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/best_products/best_products_cubit.dart';
import 'package:brandify/cubits/products/products_cubit.dart';
import 'package:brandify/cubits/all_sells/all_sells_cubit.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/models/sell.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/view/screens/products/product_details.dart';
import 'package:brandify/view/widgets/loading.dart';
import 'package:brandify/view/widgets/product_card.dart';
import 'package:brandify/view/widgets/custom_text.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BestProductsScreen extends StatefulWidget {
  final DateTimeRange? dateRange;
  const BestProductsScreen({super.key, this.dateRange});

  @override
  State<BestProductsScreen> createState() => _BestProductsScreenState();
}

class _BestProductsScreenState extends State<BestProductsScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(widget.dateRange != null){
      context.read<BestProductsCubit>().setRange(context, widget.dateRange!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bestSellingProducts),
        actions: [
          IconButton(
            onPressed: () => _shareBestProducts(context, widget.dateRange!),
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: () => _showFilterBottomSheet(context),
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: BlocBuilder<BestProductsCubit, BestProductsState>(
          builder: (context, state) {
            if(state is BestProductsLoadingState){
              return Loading();
            }
            else {
              return Visibility(
              visible: context.read<BestProductsCubit>().bestProducts.isNotEmpty,
              replacement: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        "assets/animations/request.json",
                        width: 300,
                      ),
                      //SizedBox(height: 20,),
                      Text(AppLocalizations.of(context)!.noProductsAddNow)
                    ],
                  ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      AppLocalizations.of(context)!.productsSortedBy(
                        context.watch<BestProductsCubit>().sortBy == 'quantity' 
                          ? AppLocalizations.of(context)!.quantity 
                          : AppLocalizations.of(context)!.profit
                      ),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                      child: ListView.builder(
                        itemCount:
                            context.read<BestProductsCubit>().bestProducts.length,
                        itemBuilder: (context, index) {
                          final productSales = context
                              .read<BestProductsCubit>()
                              .bestProducts[index];
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: Package.getImageCachedWidget(productSales.product.image),
                                ),
                              ),
                              // leading: CircleAvatar(
                              //   radius: 25,
                              //   backgroundImage: Package.getImageWidget(productSales.product.image),
                              // ),
                              title: CustomText(
                                text: productSales.product.name ??
                                    AppLocalizations.of(context)!.unnamedProduct,
                                fontWeight: FontWeight.bold,
                              ),
                              subtitle: CustomText(
                                text: "${AppLocalizations.of(context)!.quantitySold}: ${productSales.quantity}",
                              ),
                              trailing: CustomText(
                                text:
                                    productSales.profit >=0 ? 
                                      "+${AppLocalizations.of(context)!.priceAmount(productSales.profit)}"
                                      : "${AppLocalizations.of(context)!.priceAmount(productSales.profit)}",
                                color:  productSales.profit >=0 ?
                                   Colors.green : Colors.red,
                                //fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
            }
          },
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: AppLocalizations.of(context)!.sortProductsBy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.sort),
                title: Text(AppLocalizations.of(context)!.sortByQuantity),
                onTap: () {
                  context.read<BestProductsCubit>().sortByQuantity();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: Text(AppLocalizations.of(context)!.sortByProfit),
                onTap: () {
                  context.read<BestProductsCubit>().sortByProfit();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    );
  }
}

  Future<void> _shareBestProducts(BuildContext context, DateTimeRange dateRange) async {
    final bestProducts = context.read<BestProductsCubit>().bestProducts;
    if (bestProducts.isEmpty) return;

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(AppLocalizations.of(navigatorKey.currentContext!)!.bestSellingProductsReport, 
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)
            ),
          ),
          pw.Paragraph(
            text: AppLocalizations.of(navigatorKey.currentContext!)!.period(
              dateRange.start.toString().split(' ')[0],
              dateRange.end.toString().split(' ')[0]
            )
          ),
          pw.SizedBox(height: 20),
          
          pw.Table.fromTextArray(
            context: context,
            headers: [
              AppLocalizations.of(navigatorKey.currentContext!)!.product,
              AppLocalizations.of(navigatorKey.currentContext!)!.quantitySold,
              AppLocalizations.of(navigatorKey.currentContext!)!.profit
            ],
            data: bestProducts.map((product) => [
              product.product.name ?? AppLocalizations.of(navigatorKey.currentContext!)!.unnamedProduct,
              product.quantity.toString(),
              '${product.profit} LE',
            ]).toList(),
          ),
          
          pw.Footer(
            trailing: pw.Text(
              AppLocalizations.of(navigatorKey.currentContext!)!.generatedByBrandify(DateTime.now().toString().split(' ')[0]),
              style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
      ),
    );

    // Save and share the PDF
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/best_products_report.pdf');
    await file.writeAsBytes(await pdf.save());

    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path),], 
        text: AppLocalizations.of(context)!.bestSellingProductsReport,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      )
    );
  }
