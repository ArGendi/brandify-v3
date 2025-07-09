import 'package:brandify/constants.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/main.dart';
import 'package:brandify/view/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:brandify/models/firebase/firestore/shopify_services.dart';
import 'package:brandify/view/widgets/custom_button.dart';
import 'package:brandify/view/widgets/custom_texfield.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ShopifySetupScreen extends StatefulWidget {
  const ShopifySetupScreen({super.key});

  @override
  State<ShopifySetupScreen> createState() => _ShopifySetupScreenState();
}

class _ShopifySetupScreenState extends State<ShopifySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminTokenController = TextEditingController();
  final _storefrontTokenController = TextEditingController();
  final _storeIdController = TextEditingController();
  final _locationIdController = TextEditingController();
  final _inventoryLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing values if any
    _adminTokenController.text = ShopifyServices.adminAPIAcessToken ?? '';
    //_storefrontTokenController.text = ShopifyServices.storeFrontAPIAcessToken ?? '';
    _storeIdController.text = ShopifyServices.storeId ?? '';
    
    _locationIdController.text = ShopifyServices.locationId?.toString() ?? '';
    _inventoryLinkController.text = '';
  }

  @override
  void dispose() {
    _adminTokenController.dispose();
    _storefrontTokenController.dispose();
    _storeIdController.dispose();
    _locationIdController.dispose();
    _inventoryLinkController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  String extractLocationId(String url) {
    try {
      Uri uri = Uri.parse(url);
      return uri.queryParameters['location_id'] ?? '';
    } catch (e) {
      print('Error parsing URL: $e');
      return '';
    }
  }
  
  Future<bool> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        List<String> linkParts = _inventoryLinkController.text.replaceFirst("https://", "").replaceFirst("http://", "").split('/');
        String storeId = linkParts[2];
        String locationId = extractLocationId(_inventoryLinkController.text);

        var res = await FirestoreServices().updateUserData({
          "adminAPIAcessToken": _adminTokenController.text,
          //"storeFrontAPIAcessToken": _storefrontTokenController.text,
          "storeId": storeId,
          "locationId": locationId,
          "package": PACKAGE_TYPE_SHOPIFY,
        });
        if(res.status == Status.success){
          ShopifyServices.setParamters(
            newAdminAcessToken: _adminTokenController.text,
            //newStoreFrontAcessToken: _storefrontTokenController.text,
            newStoreId: _storeIdController.text,
            newLocationId: _locationIdController.text,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.shopifySettingsSaved)),
          );
          return true;
        }
        else{
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred)),
          ); 
          return false;
        }

        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred)),
        );
        return false;
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.shopifySetupTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                        )
                      ),
                      child: Column(
                        children: [
                          CustomButton(
                            text: localizations.contactUsOnWhatsApp,
                            icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white,),
                            onPressed: () async {
                              final Uri url = Uri.parse('https://wa.me/201107356032?text=');
                              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(localizations.couldNotLaunchWhatsApp),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            localizations.shopifySetupHelpDesc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextFormField(
                      controller: _adminTokenController,
                      text: localizations.adminApiAccessToken,
                      onValidate: (value) {
                        if (value?.isEmpty ?? true) {
                          return localizations.pleaseEnterAdminApiAccessToken;
                        }
                        return null;
                      }, onSaved: (value) {},
                    ),
                    const SizedBox(height: 15),
                    CustomTextFormField(
                      controller: _inventoryLinkController,
                      text: localizations.shopifyInventoryLink,
                      onValidate: (value) {
                        if (value?.isEmpty ?? true) {
                          return localizations.pleaseEnterInventoryLink;
                        }
                        return null;
                      },
                      onSaved: (value) {},
                    ),
                    // const SizedBox(height: 15),
                    // CustomTextFormField(
                    //   controller: _storefrontTokenController,
                    //   text: 'Storefront API Access Token*',
                    //   onValidate: (value) {
                    //     if (value?.isEmpty ?? true) {
                    //       return 'Please enter Storefront API Access Token';
                    //     }
                    //     return null;
                    //   },
                    //   onSaved: (value) {},
                    // ),
                    
                    // const SizedBox(height: 15),
                    // CustomTextFormField(
                    //   controller: _storeIdController,
                    //   text: 'Store ID*',
                    //   onValidate: (value) {
                    //     if (value?.isEmpty ?? true) {
                    //       return 'Please enter Store ID';
                    //     }
                    //     return null;
                    //   },
                    //   onSaved: (value) {},
                    // ),
                    // const SizedBox(height: 15),
                    // CustomTextFormField(
                    //   controller: _locationIdController,
                    //   text: 'Location ID*',
                    //   keyboardType: TextInputType.number,
                    //   onValidate: (value) {
                    //     if (value?.isEmpty ?? true) {
                    //       return 'Please enter Location ID';
                    //     }
                    //     return null;
                    //   },
                    //   onSaved: (value) {},
                    // ),
                  ],
                ),
              ),
              
              SizedBox(height: 20,),
              _isLoading ? 
              Center(child: CircularProgressIndicator(color: mainColor,)) :
              CustomButton(
                text: localizations.saveSettings,
                onPressed: _isLoading ? null : () async {
                  bool res = await _saveSettings();
                  if(res){
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}