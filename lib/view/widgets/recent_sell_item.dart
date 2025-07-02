import 'package:brandify/enum.dart';
import 'package:flutter/material.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/models/sell.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RecentSellItem extends StatelessWidget {
  final Sell sell;
  final Function(BuildContext, Sell) onTap;

  const RecentSellItem({
    super.key,
    required this.sell,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: () => onTap(context, sell),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: SizedBox(
              width: 50,
              height: 50,
              child: Package.getImageCachedWidget(sell.product?.image),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(${sell.quantity}) ${sell.product?.name}",
                  style: TextStyle(
                    decoration:
                        sell.isRefunded ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  sell.priceOfSell.toString(),
                  style: TextStyle(
                    decoration:
                        sell.isRefunded ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          if(sell.shopifyId != null)
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
                if(sell.status != null)
                SizedBox(width: 5),
                if(sell.status != null)
                Text(
                  getLocalizedShopifyStatus(context, sell.status),
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
          !sell.isRefunded
              ? Text(
                  sell.profit >= 0 ? "+${AppLocalizations.of(context)!.currency(sell.profit)}" : "${AppLocalizations.of(context)!.priceAmount(sell.profit)}",
                  style: TextStyle(
                    color: sell.profit >= 0 ? Colors.green : Colors.red,
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
}