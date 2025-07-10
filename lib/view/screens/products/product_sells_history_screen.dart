import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/all_sells/all_sells_cubit.dart';
import 'package:brandify/cubits/one_product_sells/one_product_sells_cubit.dart';
import 'package:brandify/cubits/products/products_cubit.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/models/sell.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductSellsHistoryScreen extends StatefulWidget {
  final Product product;
  const ProductSellsHistoryScreen({super.key, required this.product});

  @override
  State<ProductSellsHistoryScreen> createState() => _ProductSellsHistoryScreenState();
}

class _ProductSellsHistoryScreenState extends State<ProductSellsHistoryScreen> {
  DateTimeRange? selectedDateRange;
  List<Sell> filteredSells = [];

  @override
  void initState() {
    super.initState();
    var now = DateTime.now();
    OneProductSellsCubit.get(context).getAllSellsOfProductInDateRange(
      widget.product,
      now.subtract(Duration(days: 30)),
      now
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.productSalesTitle(widget.product.name.toString()),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.dateRangeFilter,
            icon: Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          if (selectedDateRange != null)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: mainColor),
                  SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.selectedDateRange(selectedDateRange!.start.toString().split(' ')[0], selectedDateRange!.end.toString().split(' ')[0]),
                    style: TextStyle(color: mainColor, fontWeight: FontWeight.w500),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: mainColor),
                    onPressed: () {
                      setState(() {
                        selectedDateRange = null;
                        _filterSells();
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<OneProductSellsCubit, OneProductSellsState>(
              builder: (context, state) {
                if (state is LoadingOneProductState) {
                  return Center(child: CircularProgressIndicator());
                }
                
                final sells = OneProductSellsCubit.get(context).sells;
                filteredSells = _filterSells();
                
                if (filteredSells.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.noSalesInPeriod,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredSells.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sell = filteredSells[index];
                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sell.date.toString().split(' ')[0],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "${AppLocalizations.of(context)!.priceAmount(sell.priceOfSell ?? 0)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: mainColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "${AppLocalizations.of(context)!.quantity}: ${sell.quantity}",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (sell.size != null) ...[
                            SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.sizeLabel(sell.size?.name ?? ''),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        _filterSells();
      });
    }
  }

  List<Sell> _filterSells() {
    final sells = OneProductSellsCubit.get(context).sells;
    if (selectedDateRange == null) return sells;

    return sells.where((sell) {
      if (sell.date == null) return false;
      final sellDate = sell.date!;
      return sellDate.isAfter(selectedDateRange!.start.subtract(Duration(days: 1))) && 
             sellDate.isBefore(selectedDateRange!.end.add(Duration(days: 1)));
    }).toList();
  }
}