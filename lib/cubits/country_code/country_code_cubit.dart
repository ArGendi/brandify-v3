import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_picker/country_picker.dart';

part 'country_code_state.dart';

class CountryCodeCubit extends Cubit<CountryCodeState> {
  CountryCodeCubit() : super(CountryCodeInitial());

  static CountryCodeCubit get(context) => BlocProvider.of(context);

  void setCountryCode(String countryCode) {
    emit(CountryCodeSelected(countryCode));
  }

  void initializeWithDefault() {
    // Set Egypt as default
    final egypt = CountryService().getAll().firstWhere(
      (country) => country.countryCode == 'EG',
    );
    emit(CountryCodeSelected(egypt.phoneCode));
  }

  void setCountry(Country country) {
    emit(CountryCodeSelected(country.phoneCode));
  }
} 