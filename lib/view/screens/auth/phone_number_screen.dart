import 'package:brandify/enum.dart';
import 'package:brandify/main.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/view/screens/home_screen.dart';
import 'package:brandify/view/screens/settings/shopify_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/view/screens/packages/package_selection_screen.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:brandify/view/widgets/custom_button.dart';
import 'package:brandify/view/widgets/custom_texfield.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brandify/cubits/country_code/country_code_cubit.dart';
import 'package:brandify/view/widgets/country_code_picker.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:brandify/cubits/phone_number/phone_number_cubit.dart';
import 'package:brandify/cubits/phone_number/phone_number_state.dart';

class PhoneNumberScreen extends StatelessWidget {
  final bool skipPackageSelection;

  const PhoneNumberScreen({super.key, this.skipPackageSelection = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PhoneNumberCubit(),
      child: _PhoneNumberScreenBody(skipPackageSelection),
    );
  }
}

class _PhoneNumberScreenBody extends StatelessWidget {
  final bool skipPackageSelection;
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  _PhoneNumberScreenBody(this.skipPackageSelection);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: BlocConsumer<PhoneNumberCubit, PhoneNumberState>(
            listener: (context, state) async{
              if (state is PhoneNumberSaved) {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)
                    ),
                    title: Text(AppLocalizations.of(context)!.shopifyDialogTitle),
                    content: Text(AppLocalizations.of(context)!.shopifyDialogBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(AppLocalizations.of(context)!.no),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(AppLocalizations.of(context)!.yes),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white
                        )
                      ),
                    ],
                  ),
                );
                if (result == true) {
                  // User wants Shopify
                  Package.type = PackageType.shopify;
                  var response = await FirestoreServices().updateUserData({
                    "package": PACKAGE_TYPE_SHOPIFY,
                  });
                  if (response.status == Status.success) {
                    await Cache.setPackageType(PACKAGE_TYPE_SHOPIFY);
                    navigatorKey.currentState?.push(
                      MaterialPageRoute(builder: (context) => ShopifySetupScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response.data),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  // User does not want Shopify
                  Package.type = PackageType.online;
                  var response = await FirestoreServices().updateUserData({
                    "package": PACKAGE_TYPE_ONLINE,
                  });
                  if (response.status == Status.success) {
                    await Cache.setPackageType(PACKAGE_TYPE_ONLINE);
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response.data),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                // Navigator.of(context).pushReplacement(
                //   MaterialPageRoute(builder: (_) => PackageSelectionScreen()),
                // );
              } else if (state is PhoneNumberError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              final cubit = context.read<PhoneNumberCubit>();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: mainColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)?.enterPhone ?? 'Please enter your phone number to continue.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 40),
                  Row(
                    children: [
                      CountryCodePicker(
                        onCountrySelected: (code) {
                          cubit.setCountryCode(code);
                        },
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Form(
                          key: _formKey,
                          child: CustomTextFormField(
                            controller: _phoneController,
                            text: AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number',
                            //prefix: Icon(Icons.phone, color: Colors.grey[600]),
                            keyboardType: TextInputType.phone,
                            onSaved: (value) {
                              String newValue = value ?? " ";
                              if(newValue[0] == '0'){
                                newValue = newValue.substring(1);
                              }
                              cubit.setPhone(newValue);
                            },
                            onValidate: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)?.phoneEmpty ?? 'Please enter your phone number';
                              }
                              // if (value.length != 11) {
                              //   return AppLocalizations.of(context)?.phoneInvalid ?? 'Phone number must be 11 digits';
                              // }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  state is PhoneNumberLoading
                      ? Center(child: CircularProgressIndicator(color: mainColor))
                      : CustomButton(
                          text: AppLocalizations.of(context)?.continueText ?? 'Continue',
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              cubit.savePhone(context);
                            }
                          },
                        ),
                  SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
} 