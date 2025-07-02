import 'package:flutter/material.dart';
import 'package:brandify/models/sell.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SellInfo extends StatelessWidget {
  final Sell sell;
  const SellInfo({super.key, required this.sell});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${AppLocalizations.of(context)!.name}: ${sell.product?.name}"),
        Text("${AppLocalizations.of(context)!.size}: ${sell.size?.name}"),
        Text("${AppLocalizations.of(context)!.quantity}: ${sell.quantity}"),
        Text("${AppLocalizations.of(context)!.place}: ${sell.getPlace()}"),
        Text("${AppLocalizations.of(context)!.costPrice}: ${sell.product?.price}"),
        Text("${AppLocalizations.of(context)!.soldFor}: ${sell.priceOfSell}"),
        Text("${AppLocalizations.of(context)!.date}: ${sell.date.toString().split(".").first}"),
        Text("${AppLocalizations.of(context)!.sideExpensesCost}: ${sell.extraExpenses}"),
        if (sell.sideExpenses.isNotEmpty)
          Text("${AppLocalizations.of(context)!.sideExpensesAre}: ${sell.getAllSideExpenses()}"),
      ],
    );
  }
}