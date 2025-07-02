part of 'country_code_cubit.dart';

abstract class CountryCodeState {}

class CountryCodeInitial extends CountryCodeState {}

class CountryCodeSelected extends CountryCodeState {
  final String countryCode;
  CountryCodeSelected(this.countryCode);
} 