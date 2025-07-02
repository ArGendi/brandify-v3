import 'dart:developer';

import 'package:brandify/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/data.dart';
import 'package:brandify/models/handler/firebase_error_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<Data<String, Status>> login(String email, String password) async{
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      return Data<String, Status>("done", Status.success);
    }
    on FirebaseAuthException catch(e){
      return Data<String, Status>(FirebaseErrorHandler.getError(AppLocalizations.of(navigatorKey.currentContext!)!, e.code), Status.fail);
    }
    catch(e){
      log(e.toString());
      return Data<String, Status>(e.toString(), Status.fail);
    }
  }

  static Future<Data<String?, Status>> register(String email, String password) async{
    try{
      var res = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      return Data<String?, Status>(res.user?.uid, Status.success);
    }
    on FirebaseAuthException catch(e){
      return Data<String, Status>(FirebaseErrorHandler.getError(AppLocalizations.of(navigatorKey.currentContext!)!, e.code), Status.fail);
    }
    catch(e){
      log(e.toString());
      return Data<String, Status>(e.toString(), Status.fail);
    }
  }

  Future<UserCredential?> signUp({
    required String phone,
    required String password,
  }) async {
    try {
      final email = '$phone@brandify.com';

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<UserCredential?> signIn({
    required String phone,
    required String password,
  }) async {
    try {
      final email = '$phone@brandify.com';
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in.');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }
}