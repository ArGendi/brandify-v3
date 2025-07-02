import 'dart:developer';
import 'dart:io';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as c;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/add_product/add_product_cubit.dart';
import 'package:brandify/cubits/products/products_cubit.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/models/size.dart';
import 'package:brandify/view/screens/products/products_screen.dart';
import 'package:brandify/view/widgets/custom_button.dart';
import 'package:brandify/view/widgets/custom_texfield.dart';
import 'package:brandify/view/widgets/loading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {

  Widget getProductImage(Product? addOrEdit){
    print("imageeee: ${addOrEdit}");
    print("imageeee: ${AddProductCubit.get(context).product.image}");
    if (addOrEdit != null) {
      return Package.getImageCachedWidget(addOrEdit.image);
    }
    else {
      if(AddProductCubit.get(context).product.image == null){
        return Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: Colors.white,
            ),
            Text(
              AppLocalizations.of(context)!.addPhoto,
              style: TextStyle(
                  color: Colors.white),
            )
          ],
        );
      }
      else {
        return Image.file(File(AddProductCubit.get(context).product.image!));
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.product != null) {
      AddProductCubit.get(context).setProduct(widget.product!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null 
          ? AppLocalizations.of(context)!.addProduct 
          : AppLocalizations.of(context)!.editProduct),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: AddProductCubit.get(context).formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        _imageBottomSheet(context);
                      },
                      child: BlocBuilder<AddProductCubit, AddProductState>(
                        builder: (context, state) {
                          if (state is LoadingImageState) {
                            return SizedBox(
                              width: double.infinity,
                              height: 180,
                              child: Loading(),
                            );
                          } else {
                            return BlocBuilder<AddProductCubit, AddProductState>(
                              builder: (context, state) {
                                return Container(
                                  width: double.infinity,
                                  height: 180,
                                  decoration: BoxDecoration(
                                      color: mainColor,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: getProductImage(widget.product),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    // Row(
                    //   children: [
                    //     SizedBox(width: 5,),
                    //     Text(
                    //       AppLocalizations.of(context)!.mandatoryFieldsNote,
                    //       style: TextStyle(color: Colors.green),
                    //     ),
                    //   ],
                    // ),
                    // SizedBox(
                    //   height: 5,
                    // ),
                    Row(
                      children: [
                        Expanded(
                          child: BlocBuilder<AddProductCubit, AddProductState>(
                            builder: (context, state) {
                              print(state);
                              return CustomTextFormField(
                                controller:
                                    AddProductCubit.get(context).codeController,
                                // initial:
                                //     AddProductCubit.get(context).product.code,
                                text:  AppLocalizations.of(context)!.barcode,
                                onSaved: (value) {
                                  AddProductCubit.get(context).product.code =
                                      value;
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          onTap: () async {
                            try {
                              var result = await BarcodeScanner.scan();
                              if (result.rawContent.isNotEmpty) {
                                AddProductCubit.get(context).setCode(result.rawContent);
                              }
                            } catch (e) {
                              print('Barcode scan error: $e');
                            }
                            // var res = await Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) =>
                            //           const SimpleBarcodeScannerPage(),
                            //     ));
                            // if (res is String) {
                            //   log("barcode: $res");
                            // if(res != "-1"){
                            //   AddProductCubit.get(context).setCode(res);
                            // }
                            // }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: mainColor),
                            child: Padding(
                              padding: const EdgeInsets.all(13.0),
                              child: Text(
                                "𝄃𝄃𝄃𝄂",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    CustomTextFormField(
                      initial: AddProductCubit.get(context).product.name,
                      text:  AppLocalizations.of(context)!.nameLabel,
                      onSaved: (value) {
                        AddProductCubit.get(context).product.name = value;
                      },
                      onValidate: (value) {
                        if (value!.isEmpty) {
                          return  AppLocalizations.of(context)!.nameRequired;
                        } else
                          return null;
                      },
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    CustomTextFormField(
                      initial:
                          AddProductCubit.get(context)
                                  .product
                                  .price?.toString(),
                      keyboardType: TextInputType.number,
                      text: AppLocalizations.of(context)!.requiredCostPrice,
                      hintText: AppLocalizations.of(context)!.pricePaidHint,
                      onSaved: (value) {
                        if (value!.isNotEmpty) {
                          AddProductCubit.get(context).product.price =
                              int.parse(value);
                        }
                      },
                      onValidate: (value) {
                        if (value!.isEmpty) {
                          return  AppLocalizations.of(context)!.priceRequired;
                        } else return null;
                      },
                    ),
                    SizedBox(
                      height: 3,
                    ),
                    Row(
                      children: [
                        SizedBox(width: 5,),
                        Expanded(child: Text(
                          AppLocalizations.of(context)!.originalPriceHint,
                          style: TextStyle(fontSize: 11),
                        )),
                      ],
                    ),
                    if (Package.type == PackageType.shopify)
                      Column(
                        children: [
                          SizedBox(
                            height: 15,
                          ),
                          CustomTextFormField(
                            initial:
                                AddProductCubit.get(context).product.price !=
                                        null
                                    ? AddProductCubit.get(context)
                                        .product
                                        .shopifyPrice
                                        .toString()
                                    : null,
                            keyboardType: TextInputType.number,
                            text:  AppLocalizations.of(context)!.shopifyPrice,
                            onSaved: (value) {
                              if (value!.isNotEmpty) {
                                AddProductCubit.get(context)
                                    .product
                                    .shopifyPrice = int.parse(value);
                              }
                            },
                            onValidate: (value) {
                              if (value!.isEmpty) {
                                return  AppLocalizations.of(context)!.shopifyPriceRequired;
                              } else
                                return null;
                            },
                          ),
                        ],
                      ),
                      SizedBox(
                      height: 15,
                    ),
                    CustomTextFormField(
                      initial: AddProductCubit.get(context).product.description,
                      text:  AppLocalizations.of(context)!.productDescription,
                      onSaved: (value) {
                        AddProductCubit.get(context).product.description =
                            value;
                      },
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    BlocBuilder<AddProductCubit, AddProductState>(
                      builder: (context, state) {
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, i) {
                            return Row(
                              children: [
                                Expanded(
                                  child: CustomTextFormField(
                                    controller: AddProductCubit.get(context)
                                        .sizesControllers[i]
                                        .sizeController,
                                    text: AppLocalizations.of(context)!.size,
                                    onSaved: (value) {},
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: CustomTextFormField(
                                    controller: AddProductCubit.get(context)
                                        .sizesControllers[i]
                                        .quantityController,
                                    keyboardType: TextInputType.number,
                                    text: AppLocalizations.of(context)!.requiredQuantity,
                                    onSaved: (value) {},
                                  ),
                                ),
                                if (i != 0)
                                  SizedBox(
                                    width: 10,
                                  ),
                                if (i != 0)
                                  IconButton(
                                    onPressed: () {
                                      AddProductCubit.get(context)
                                          .removeSize(i);
                                    },
                                    icon: Icon(
                                      Icons.clear,
                                      size: 15,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            );
                          },
                          separatorBuilder: (context, i) => SizedBox(
                            height: 10,
                          ),
                          itemCount:
                              AddProductCubit.get(context).product.sizes.length,
                        );
                      },
                    ),
                    // SizedBox(
                    //   height: 10,
                    // ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: CustomButton(
                        icon: Icon(Icons.add),
                        text: AppLocalizations.of(context)!.addAnotherSize,
                        onPressed: () {
                          AddProductCubit.get(context).addSize();
                        },
                        bgColor: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, state) {
                  if (state is LoadingEditProductState ||
                      state is LoadingOneProductState) {
                    return Loading();
                  } else {
                    return CustomButton(
                      text: widget.product == null ? 
                      AppLocalizations.of(context)!.addProduct : AppLocalizations.of(context)!.editProduct,
                      onPressed: () async {
                        Product? product = await AddProductCubit.get(context)
                            .validate(context);
                        if (product != null) {
                          if (widget.product == null) {
                            ProductsCubit.get(context)
                                .addProduct(product, context);
                          } else {
                            ProductsCubit.get(context)
                                .editProduct(widget.product!, product, context);
                          }
                        }
                      },
                      //bgColor: Colors.black,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _imageBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      //isScrollControlled: true,
      context: context,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CustomButton(
                    icon: Icon(
                      Icons.photo,
                      color: Colors.white,
                    ),
                    text: AppLocalizations.of(context)!.photosButton,
                    onPressed: () {
                      AddProductCubit.get(context)
                          .getImage(ImageSource.gallery);
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  CustomButton(
                    icon: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                    ),
                    text: AppLocalizations.of(context)!.cameraButton,
                    onPressed: () {
                      AddProductCubit.get(context).getImage(ImageSource.camera);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}
