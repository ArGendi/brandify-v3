import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:brandify/models/slack/slack_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/brand.dart';
import 'package:brandify/models/data.dart';
import 'package:brandify/models/firebase/auth_services.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:brandify/view/screens/home_screen.dart';
import 'package:brandify/models/handler/firebase_error_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late String name;
  late String email;
  late String password;
  late String confirmPassword;

  RegisterCubit() : super(RegisterInitial());
  static RegisterCubit get(BuildContext context) => BlocProvider.of(context);

  Future<Data<String, RegisterStatus>> onRegister(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    formKey.currentState!.save();
    bool valid = formKey.currentState!.validate();
    if(valid){
      emit(RegisterLoadingState());
      var response = await AuthServices.register(email, password);
      if(response.status == Status.success){
        Brand newBrand = Brand(name: name, email: email);
        Map<String, dynamic> brandData = {
          "total": 0,
          "totalProfit": 0,
          "totalOrders": 0,
          "createdAt": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          "phoneType": Platform.isAndroid ? "Android" : "IOS",
        };
        brandData.addAll(newBrand.toJson());
        var brandResponse = await FirestoreServices().setUserData(brandData);
        if(brandResponse.status == Status.success){
          newBrand.backendId = brandResponse.data;
          Cache.setInitialUserData(
            name: name,
            email: email,
          );
          // SlackServices().sendMessage(
          //   message: "New Brand Registered: ${newBrand.name} - ${newBrand.phone}",
          // );
          emit(RegisterSuccessState());
          return Data("", RegisterStatus.pass);
        }
        else{
          emit(RegisterFailState());
          String errorMsg = response.data!;
          if (errorMsg.contains(']')) {
            final codeMatch = RegExp(r'\[(.*?)\]').firstMatch(errorMsg);
            if (codeMatch != null && codeMatch.groupCount > 0) {
              final code = codeMatch.group(1)?.split('/').last;
              if (code != null) {
                errorMsg = FirebaseErrorHandler.getError(l10n, code);
              }
            }
          }
          return Data(errorMsg, RegisterStatus.backendError);
        }
      }
      else{
        emit(RegisterFailState());
        return Data(response.data!, RegisterStatus.backendError);
      }
    }
    else{
      return Data("", RegisterStatus.missingParameters);
    }
  }
}
