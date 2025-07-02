import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:flutter/material.dart';
import 'phone_number_state.dart';

class PhoneNumberCubit extends Cubit<PhoneNumberState> {
  PhoneNumberCubit() : super(PhoneNumberInitial());

  String countryCode = '+20';
  String phone = '';
  bool isLoading = false;

  void setCountryCode(String code) {
    countryCode = '+$code';
    emit(PhoneNumberCountryChanged(countryCode));
  }

  void setPhone(String value) {
    phone = value;
    emit(PhoneNumberChanged(phone));
  }

  Future<void> savePhone(BuildContext context) async {
    emit(PhoneNumberLoading());
    try {
      final fullPhone = countryCode + phone;
      await Cache.setPhone(fullPhone);
      await FirestoreServices().updateUserData({'brandPhone': fullPhone});
      emit(PhoneNumberSaved());
    } catch (e) {
      emit(PhoneNumberError(e.toString()));
    }
  }
} 