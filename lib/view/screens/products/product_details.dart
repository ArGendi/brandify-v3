import 'dart:developer';
import 'dart:io';

import 'package:brandify/enum.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brandify/cubits/add_product/add_product_cubit.dart';
import 'package:brandify/cubits/one_product_sells/one_product_sells_cubit.dart';
import 'package:brandify/cubits/products/products_cubit.dart';
import 'package:brandify/cubits/sell/sell_cubit.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/view/screens/one_product_sells_screen.dart';
import 'package:brandify/view/screens/products/add_product_screen.dart';
import 'package:brandify/view/screens/products/product_sells_history_screen.dart';
import 'package:brandify/view/screens/sell_screen.dart';
import 'package:brandify/view/widgets/custom_button.dart';
import 'package:brandify/view/widgets/custom_texfield.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductDetails extends StatefulWidget {
  final Product product;
  const ProductDetails({super.key, required this.product});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  int totalQuantity = 0;

  @override
  void initState() {
    super.initState();
    log(widget.product.shopifyId.toString());
    totalQuantity = widget.product.getNumberOfAllItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAskForCostPrice();
    });
  }

  void _checkAndAskForCostPrice() {
    if (Package.type == PackageType.shopify &&
        widget.product.price == widget.product.shopifyPrice) {
      showCostPriceDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Package.getImageCachedWidget(widget.product.image),
                  // Image(
                  //   image: Package.getImageWidget(widget.product.image),
                  //   fit: BoxFit.cover,
                  // ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Row(
                          children: [
                            Icon(Icons.history, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.viewHistory,
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          navigatorKey.currentState?.push(
                            MaterialPageRoute(
                              builder: (_) => OneProductSellsScreen(product: widget.product),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: Package.type != PackageType.shopify ? [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (context) => AddProductCubit(),
                        child: AddProductScreen(product: widget.product),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => showDeleteAlertDialog(context),
              ),
            ] :
            // Shopify: Only allow editing product price
            [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  showEditPriceDialog(context);
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name ?? "",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${AppLocalizations.of(context)!.itemsInStockCount(totalQuantity)}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              //const SizedBox(height: 4),
                              Text(
                                "${AppLocalizations.of(context)!.totalAmount(totalQuantity * (widget.product.price ?? 0))}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 15,),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${AppLocalizations.of(context)!.currency(widget.product.price ?? 0) }",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if(Package.type == PackageType.shopify)
                            SizedBox(height: 4,),
                            if(Package.type == PackageType.shopify)
                            Row(
                              children: [
                                FaIcon(FontAwesomeIcons.shopify, size: 15, color: Colors.green,),
                                SizedBox(width: 5,),
                                Text(
                                  "${AppLocalizations.of(context)!.currency(widget.product.shopifyPrice ?? 0) }",
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (widget.product.description != null && (widget.product.description?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!.productDescription,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.product.description ?? "",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.availableSizes,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    GridView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: widget.product.sizes.length,
                      itemBuilder: (context, index) {
                        final size = widget.product.sizes[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  size.name.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (size.quantity ?? 0) > 0 ?
                                      Theme.of(context).primaryColor.withOpacity(0.1)
                                      : Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    size.quantity.toString(),
                                    style: TextStyle(
                                      color: (size.quantity ?? 0) > 0 ? 
                                        Theme.of(context).primaryColor : Colors.white,
                                      fontWeight: FontWeight.w500,
                                      
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: AppLocalizations.of(context)!.sellNowButton,
                onPressed: () {
                  if(totalQuantity > 0){
                    navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (context) => SellCubit(),
                          child: SellScreen(product: widget.product),
                        ),
                      ),
                    );
                  }
                  else{
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                        content: Text(AppLocalizations.of(context)!.noItemsInStock),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomButton(
                text: AppLocalizations.of(context)!.refundButton,
                bgColor: Colors.red.shade900,
                onPressed: () {
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (_) => OneProductSellsScreen(product: widget.product),
                    ),
                  );
                },
              ),
            ),
          ],
          ),
        ),
      );
  }

  void showDeleteAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text(AppLocalizations.of(context)!.deleteProduct),
          content:  Text(AppLocalizations.of(context)!.deleteProductConfirm),
          actions: [
            TextButton(
              onPressed: () {
                navigatorKey.currentState?.pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                ProductsCubit.get(context).deleteProduct(widget.product, context);
                navigatorKey.currentState?.pop();
              },
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );
  }

  void showCostPriceDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _costPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Cost Price"),
          content: Form(
            key: _formKey,
            child: CustomTextFormField(
              controller: _costPriceController,
              text: "Cost Price",
              keyboardType: TextInputType.number,
              onValidate: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a cost price';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onSaved: (value) {},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                navigatorKey.currentState?.pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newCost = int.parse(_costPriceController.text);
                  setState(() {
                    widget.product.price = newCost;
                  });
                  await ProductsCubit.get(context)
                      .updateShopifyProductCost(widget.product, context);
                  navigatorKey.currentState?.pop();
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void showEditPriceDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _priceController = TextEditingController(text: widget.product.price?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.editProduct ?? 'Edit Product'),
          content: Form(
            key: _formKey,
            child: CustomTextFormField(
              controller: _priceController,
              text: AppLocalizations.of(context)?.productPrice ?? 'Product Price',
              keyboardType: TextInputType.number,
              onValidate: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)?.priceRequired ?? 'Enter price';
                }
                if (int.tryParse(value) == null) {
                  return AppLocalizations.of(context)?.priceRequired ?? 'Enter price';
                }
                return null;
              },
              onSaved: (value) {},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                navigatorKey.currentState?.pop();
              },
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newPrice = int.parse(_priceController.text);
                  setState(() {
                    widget.product.price = newPrice;
                  });
                  await ProductsCubit.get(context).updateShopifyProductCost(widget.product, context);
                  navigatorKey.currentState?.pop();
                }
              },
              child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
            ),
          ],
        );
      },
    );
  }
}
