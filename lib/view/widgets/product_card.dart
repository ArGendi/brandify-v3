import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:brandify/cubits/products/products_cubit.dart';
import 'package:brandify/main.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/view/screens/products/product_details.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    int numberOfAllItems = product.getNumberOfAllItems();
    return GestureDetector(
      onTap: () {
        ProductsCubit.get(context).filteredProducts = ProductsCubit.get(context).products;
        navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => ProductDetails(product: product)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Package.getImageCachedWidget(product.image),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: numberOfAllItems > 0? Colors.black.withOpacity(0.7) : Colors.red.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.itemsInStockCount(numberOfAllItems),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ), 
                ]
              ),
              // child: Container(
              //   decoration: BoxDecoration(
              //     borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              //     color: Colors.grey[200],
              //     image: DecorationImage(
              //       fit: BoxFit.cover,
              //       image: Package.getImageWidget(product.image),
              //     ),
              //   ),
              //   child: Align(
              //     alignment: Alignment.topRight,
              //     child: Container(
              //       margin: const EdgeInsets.all(10),
              //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //       decoration: BoxDecoration(
              //         color: Colors.black.withOpacity(0.7),
              //         borderRadius: BorderRadius.circular(20),
              //       ),
              //       child: Text(
              //         "${product.getNumberOfAllItems()} in stock",
              //         style: const TextStyle(
              //           color: Colors.white,
              //           fontSize: 12,
              //           fontWeight: FontWeight.w500,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.priceAmount(product.price ?? 0),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}