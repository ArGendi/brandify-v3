import 'package:bloc/bloc.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/app_user/app_user_cubit.dart';
import 'package:brandify/view/screens/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/firebase/auth_services.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:brandify/models/firebase/firestore/shopify_services.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/view/screens/home_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:brandify/models/handler/firebase_error_handler.dart';
part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late String email;
  late String password;

  LoginCubit() : super(LoginInitial());
  static LoginCubit get(BuildContext context) => BlocProvider.of(context);

  void onLogin(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      bool valid = formKey.currentState!.validate();
      if (!valid) return;

      formKey.currentState!.save();
      emit(LoadingState());

      // Login attempt
      var loginResponse = await AuthServices.login(email, password);
      if (loginResponse.status != Status.success) {
        emit(FailState());
        String errorMsg = loginResponse.data ?? '';
        // Try to extract Firebase error code if present
        if (errorMsg.contains(']')) {
          // Format: [firebase_auth/wrong-password] message
          final codeMatch = RegExp(r'\[(.*?)\]').firstMatch(errorMsg);
          if (codeMatch != null && codeMatch.groupCount > 0) {
            final code = codeMatch.group(1)?.split('/').last;
            if (code != null) {
              errorMsg = FirebaseErrorHandler.getError(l10n, code);
            }
          }
        }
        _showError(context, errorMsg.isNotEmpty ? errorMsg : l10n.loginFailed('Unknown error'));
        return;
      }

      // Get user data
      try {
        var userData = await FirestoreServices().getUserData();
        if (userData == null) {
          emit(FailState());
          _showError(context, l10n.failedToLoadUserData);
          return;
        }

        AppUserCubit.get(context).setIsLoggedInNow(true);
        
        // Save user data
        // await Cache.setInitialUserData(
        //   name: userData['brandName'] ?? "Brandify", 
        //   phone: userData['brandPhone'],
        //   total: userData['total']?? 0,
        //   totalProfit: userData['totalProfit']?? 0,
        //   totalOrders: userData['totalOrders']?? 0,
        //   packageType: userData['package']?? PACKAGE_TYPE_ONLINE,
        // );

        
        // Validate and set Shopify parameters
        // if (!_validateShopifyData(userData)) {
        //   emit(FailState());
        //   _showError(context, 'Invalid store configuration');
        //   return;
        // }

        // Package.getTypeFromString(
        //   userData["package"] ?? PACKAGE_TYPE_ONLINE,
        // );
        emit(SuccessState());
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => HomeScreen()), 
          (_) => false
        );
      } catch (e) {
        emit(FailState());
        _showError(context, l10n.errorLoadingUserData(e.toString()));
      }
    } catch (e) {
      emit(FailState());
      _showError(context, l10n.unexpectedError(e.toString()));
    }
  }

  bool _validateShopifyData(Map<String, dynamic> userData) {
    return userData['adminAPIAcessToken']?.isNotEmpty == true &&
           userData['storeFrontAPIAcessToken']?.isNotEmpty == true &&
           userData['storeId']?.isNotEmpty == true &&
           userData['locationId']?.isNotEmpty == true;
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
       // behavior: SnackBarBehavior.floating,
      )
    );
  }
}
