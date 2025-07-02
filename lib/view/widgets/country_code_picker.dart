import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_picker/country_picker.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/country_code/country_code_cubit.dart';

class CountryCodePicker extends StatefulWidget {
  final Function(String) onCountrySelected;
  final String? initialCountryCode;

  const CountryCodePicker({
    Key? key,
    required this.onCountrySelected,
    this.initialCountryCode,
  }) : super(key: key);

  @override
  State<CountryCodePicker> createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  Country? selectedCountry;

  @override
  void initState() {
    super.initState();
    // Set Egypt as default if no initial country is provided
    if (widget.initialCountryCode != null) {
      selectedCountry = CountryService().getAll().firstWhere(
        (country) => country.countryCode == widget.initialCountryCode,
        orElse: () => CountryService().getAll().firstWhere(
          (country) => country.countryCode == 'EG',
        ),
      );
    }
    selectedCountry ??= CountryService().getAll().firstWhere(
      (country) => country.countryCode == 'EG',
    ); // Egypt as default
    
    // Initialize the cubit with the selected country
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CountryCodeCubit.get(context).setCountry(selectedCountry!);
      widget.onCountrySelected(selectedCountry!.phoneCode);
    });
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, color: Colors.black),
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withOpacity(0.2),
            ),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          selectedCountry = country;
        });
        CountryCodeCubit.get(context).setCountry(country);
        widget.onCountrySelected(country.phoneCode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CountryCodeCubit, CountryCodeState>(
      builder: (context, state) {
        String countryCode = '+20'; // Default to Egypt
        String flagEmoji = '🇪🇬';
        
        if (state is CountryCodeSelected) {
          countryCode = '+${state.countryCode}';
          // Find the country by phone code to get the flag
          try {
            final country = CountryService().getAll().firstWhere(
              (c) => c.phoneCode == state.countryCode,
            );
            flagEmoji = country.flagEmoji;
          } catch (e) {
            // Fallback to Egypt if country not found
            flagEmoji = '🇪🇬';
          }
        }
        
        return GestureDetector(
          onTap: _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  flagEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  countryCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: mainColor,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 