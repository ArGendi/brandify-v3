import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/app_user/app_user_cubit.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/firebase/firestore/firestore_services.dart';
import 'package:brandify/models/firebase/firestore/shopify_services.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:brandify/models/package.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:brandify/models/firebase/auth_services.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: AppUserCubit.get(context).brandName);
    _phoneController = TextEditingController(text: AppUserCubit.get(context).brandPhone);
    _emailController = TextEditingController(text: AppUserCubit.get(context).email);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountSettings),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () => _toggleEdit(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Center(
                    //   child: Stack(
                    //     children: [
                    //       CircleAvatar(
                    //         radius: 50,
                    //         backgroundColor: mainColor,
                    //         child: Icon(Icons.person, size: 50, color: Colors.white),
                    //       ),
                    //       if (_isEditing)
                    //         Positioned(
                    //           right: 0,
                    //           bottom: 0,
                    //           child: Container(
                    //             padding: EdgeInsets.all(8),
                    //             decoration: BoxDecoration(
                    //               color: mainColor,
                    //               shape: BoxShape.circle,
                    //             ),
                    //             child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    //           ),
                    //         ),
                    //     ],
                    //   ),
                    // ),
                    // SizedBox(height: 30),
                    _buildSection(
                      title: AppLocalizations.of(context)!.personalInfo,
                      children: [
                        _buildTextField(
                          label: AppLocalizations.of(context)!.brandName,
                          controller: _nameController,
                          enabled: _isEditing,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return AppLocalizations.of(context)!.brandNameRequired;
                            return null;
                          },
                        ),
                        SizedBox(height: 15),
                        _buildTextField(
                          label: AppLocalizations.of(context)!.phoneNumber,
                          controller: _phoneController,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return AppLocalizations.of(context)!.phoneRequired;
                            return null;
                          },
                        ),
                        SizedBox(height: 15),
                        _buildTextField(
                          label: AppLocalizations.of(context)!.email,
                          controller: _emailController,
                          enabled: false,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return AppLocalizations.of(context)!.invalidEmail;
                            return null;
                          },
                        ),
                        if (_isEditing)
                          SizedBox(height: 15),
                        if (_isEditing)
                          _buildTextField(
                            label: AppLocalizations.of(context)!.password,
                            controller: _passwordController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.visiblePassword,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && value.length < 8) {
                                // Use fallback if passwordTooShort is not defined
                                try {
                                  return AppLocalizations.of(context)!.passwordTooShort;
                                } catch (_) {
                                  return 'Password must be at least 8 characters';
                                }
                              }
                              return null;
                            },
                            obscureText: true,
                          ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      title: AppLocalizations.of(context)!.packageInfo,
                      children: [
                        _buildInfoTile(
                          AppLocalizations.of(context)!.currentPackage,
                          Package.type.name.toUpperCase(),
                          Icons.card_membership,
                        ),
                        _buildInfoTile(
                          AppLocalizations.of(context)!.features,
                          Package.type == PackageType.offline 
                              ? AppLocalizations.of(context)!.basicFeatures
                              : AppLocalizations.of(context)!.fullFeatures,
                          Icons.featured_play_list,
                        ),
                        // TextButton(
                        //   onPressed: () {
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(builder: (_) => PackageSelectionScreen()),
                        //     );
                        //   },
                        //   child: Text('Change Package'),
                        //   style: TextButton.styleFrom(
                        //     foregroundColor: mainColor,
                        //     padding: EdgeInsets.symmetric(horizontal: 0),
                        //   ),
                        // ),
                      ],
                    ),
                    // SizedBox(height: 20),
                    // _buildSection(
                    //   title: 'Store Information',
                    //   children: [
                    //     _buildInfoTile(
                    //       'Store ID',
                    //       ShopifyServices.storeId ?? 'Not set',
                    //       Icons.store,
                    //     ),
                    //     _buildInfoTile(
                    //       'Location ID',
                    //       (ShopifyServices.locationId ?? 'Not set').toString(),
                    //       Icons.location_on,
                    //     ),
                    //   ],
                    // ),
                    SizedBox(height: 20),
                    Container(
                      margin: EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 5,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => Container(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    margin: EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  Icon(
                                    Icons.delete_forever,
                                    size: 40,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 15),
                                  Text(
                                    AppLocalizations.of(context)!.deleteAccount,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    AppLocalizations.of(context)!.deleteConfirmMessage,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(AppLocalizations.of(context)!.cancel),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.symmetric(vertical: 15),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(context); // Close the bottom sheet
                                            final reauthenticated = await _showReauthenticateDialog();
                                            if (reauthenticated == true) {
                                              // Re-fetch context before async gap
                                              if (!mounted) return;
                                              AppUserCubit.get(context).deleteAccount(context);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(vertical: 15),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(AppLocalizations.of(context)!.delete),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.delete_forever_outlined, color: Colors.white),
                        ),
                        title: Text(
                          AppLocalizations.of(context)!.deleteAccount,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!.deleteAccountDesc,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: mainColor),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: mainColor),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showReauthenticateDialog() async {
    final TextEditingController passwordController = TextEditingController();
    bool isAuthenticating = false;
    final formKey = GlobalKey<FormState>();

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)
                  ),
                  title: Text(AppLocalizations.of(context)!.reauthenticate),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppLocalizations.of(context)!.reauthenticateMessage),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.currentPassword,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.passwordEmpty;
                            }
                            return null;
                          },
                        ),
                        if (isAuthenticating) ...[
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(),
                        ]
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isAuthenticating ? null : () => Navigator.of(dialogContext).pop(false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    ElevatedButton(
                      onPressed: isAuthenticating
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                setState(() {
                                  isAuthenticating = true;
                                });
                                try {
                                  final email = AppUserCubit.get(context).email;
                                  if (email == null) {
                                    throw Exception("Email not found");
                                  }
                                  await AuthServices().reauthenticate(email: email, password: passwordController.text);
                                  Navigator.of(dialogContext).pop(true);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)!.authenticationFailed(e.toString()),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  Navigator.of(dialogContext).pop(false);
                                } finally {
                                  setState(() {
                                    isAuthenticating = false;
                                  });
                                }
                              }
                            },
                      child: Text(AppLocalizations.of(context)!.confirm),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;
  }

  void _toggleEdit() async {
    if (_isEditing) {
      if (_formKey.currentState?.validate() ?? false) {
        if (_passwordController.text.isNotEmpty) {
          final reauthenticated = await _showReauthenticateDialog();
          if (!reauthenticated) {
            return; // Stop if re-authentication fails or is cancelled
          }
        }
        setState(() => _isLoading = true);
        // Save changes
        var response = await AppUserCubit.get(context).updateUser(
          name: _nameController.text,
          //phone: _phoneController.text,
        );
        bool passwordChanged = false;
        String? passwordError;
        if (_passwordController.text.isNotEmpty) {
          try {
            await AppUserCubit.get(context).changePassword(_passwordController.text);
            passwordChanged = true;
          } catch (e) {
            passwordError = e.toString();
          }
        }
        setState(() => _isLoading = false);
        if (response == true && passwordError == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.changesSaved)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(passwordError ?? AppLocalizations.of(context)!.saveFailed),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        _passwordController.clear();
      } else {
        return;
      }
    }
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) _passwordController.clear();
    });
  }
}