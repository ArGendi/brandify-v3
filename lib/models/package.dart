import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/enum.dart';

class Package {
  static PackageType type = PackageType.online;

  static Future<void> checkAccessability({required Future Function() online, required Future Function() offline, Future Function()? shopify}) async{
    if(type == PackageType.offline){
      await offline();
    }
    else if(type == PackageType.online){
      await online();
    }
    else if(type == PackageType.shopify && shopify != null){
      await shopify();
    }
    else if(shopify == null){
      await online();
    }
    else{}
  }

  static ImageProvider<Object> getImageWidget(String? imageUrl){
    if(imageUrl == null){
      return Image.asset(
        width: double.infinity,
        height: 380,
        "assets/images/default.png",
        fit: BoxFit.cover,
      ).image; 
    }
    if(imageUrl.trim().startsWith("http")){
      return Image.network(
        imageUrl,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
            return Image.asset(
              width: double.infinity,
              height: 380,
              "assets/images/default.png",
              fit: BoxFit.cover,
            );
        },
        color: Colors.grey.shade300,
      ).image;
    }
    else{
      return Image.file(File(imageUrl)).image;
    }
  }

  static Widget getImageCachedWidget(String? imageUrl){
    if(imageUrl == null){
      return Image.asset(
        width: double.infinity,
        height: 380,
        "assets/images/default.png",
        fit: BoxFit.cover,
      ); 
    }
    if(imageUrl.trim().startsWith("http")){
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 380,
        fit: BoxFit.cover,
        placeholder: (context, url) => Image.asset(
          "assets/images/default.png",
          width: double.infinity,
          height: 380, 
          fit: BoxFit.cover,
        ),
        errorWidget: (context, url, error) => Image.asset(
          "assets/images/default.png",
          width: double.infinity,
          height: 380,
          fit: BoxFit.cover,
        ),
      );
      // return Image.network(
      //   imageUrl,
      //   loadingBuilder: (context, child, loadingProgress) {
      //     if (loadingProgress == null) return child;
      //       return Image.asset(
      //         width: double.infinity,
      //         height: 380,
      //         "assets/images/default.png",
      //         fit: BoxFit.cover,
      //       );
      //   },
      //   color: Colors.grey.shade300,
      // ).image;
    }
    else{
      return Image.file(
        File(imageUrl),
        width: double.infinity,
        height: 380,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          "assets/images/default.png",
          width: double.infinity,
          height: 380,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  static void getTypeFromString(String type) {
      if (type == PACKAGE_TYPE_ONLINE) {
        Package.type = PackageType.online;
      }
      else if (type == PACKAGE_TYPE_OFFLINE) {
        Package.type = PackageType.offline;
      }
      else if (type == PACKAGE_TYPE_SHOPIFY) {
        Package.type = PackageType.shopify;
      }
      else {
        Package.type = PackageType.offline;
      }
    }


}