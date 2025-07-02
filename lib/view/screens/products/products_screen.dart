import 'dart:developer';

import 'package:brandify/cubits/app_user/app_user_cubit.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/view/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
// import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/add_product/add_product_cubit.dart';
import 'package:brandify/cubits/products/products_cubit.dart';
import 'package:brandify/main.dart';
import 'package:brandify/view/screens/products/add_product_screen.dart';
import 'package:brandify/view/widgets/product_card.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //ProductsCubit.get(context).getProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.productsInventory),
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[50], // Light grey background for better contrast
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: BlocBuilder<ProductsCubit, ProductsState>(
            builder: (context, state) {
              if (state is LoadingProductsState) {
                return Loading();
              } else
                return Visibility(
                  visible: ProductsCubit.get(context).products.isNotEmpty,
                  replacement: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          "assets/animations/request.json",
                          width: 300,
                        ),
                        //const SizedBox(height: 10),
                        Text(
                          AppLocalizations.of(context)!.noProductsYet,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
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
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller:
                                    ProductsCubit.get(context).searchController,
                                onChanged: (value) {
                                  ProductsCubit.get(
                                    context,
                                  ).filterProducts(value);
                                },
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey[600],
                                  ),
                                  hintText:
                                      AppLocalizations.of(
                                        context,
                                      )!.searchProducts,
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: mainColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  try {
                                    var result = await BarcodeScanner.scan();
                                    if (result.rawContent.isNotEmpty) {
                                      ProductsCubit.get(
                                        context,
                                      ).getProductByCode(
                                        context,
                                        result.rawContent,
                                      );
                                    }
                                  } catch (e) {
                                    print('Barcode scan error: $e');
                                  }
                                },
                                icon: Text(
                                  "𝄃𝄃𝄃𝄂",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: BlocBuilder<ProductsCubit, ProductsState>(
                          builder: (context, state) {
                            return GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 15,
                                    crossAxisSpacing: 15,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount:
                                  ProductsCubit.get(
                                    context,
                                  ).filteredProducts.length +
                                  2,
                              itemBuilder: (_, i) {
                                if (i <
                                    ProductsCubit.get(
                                      context,
                                    ).filteredProducts.length) {
                                  final product =
                                      ProductsCubit.get(
                                        context,
                                      ).filteredProducts[i];
                                  return Container(
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
                                    child: ProductCard(product: product),
                                  );
                                } else {
                                  return const SizedBox();
                                }
                              },
                            );
                          },
                        ),
                      ),
                      // const SizedBox(height: 30),
                    ],
                  ),
                );
            },
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<AppUserCubit, AppUserState>(
        builder: (context, state) {
          if(Package.type != PackageType.shopify){
            return FloatingActionButton.extended(
              onPressed: () {
                ProductsCubit.get(context).filteredProducts =
                    ProductsCubit.get(context).products;
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder:
                        (context) => BlocProvider(
                          create: (context) => AddProductCubit(),
                          child: const AddProductScreen(),
                        ),
                  ),
                );
              },
              label: Text(AppLocalizations.of(context)!.addProduct),
              icon: const Icon(Icons.add),
              backgroundColor: mainColor,
            );
          }
          else return Container();
        },
      ),
    );
  }
}
