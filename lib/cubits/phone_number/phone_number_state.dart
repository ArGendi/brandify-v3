abstract class PhoneNumberState {}
class PhoneNumberInitial extends PhoneNumberState {}
class PhoneNumberCountryChanged extends PhoneNumberState {
  final String countryCode;
  PhoneNumberCountryChanged(this.countryCode);
}
class PhoneNumberChanged extends PhoneNumberState {
  final String phone;
  PhoneNumberChanged(this.phone);
}
class PhoneNumberLoading extends PhoneNumberState {}
class PhoneNumberSaved extends PhoneNumberState {}
class PhoneNumberError extends PhoneNumberState {
  final String message;
  PhoneNumberError(this.message);
} 