import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:brandify/cubits/language/language_cubit.dart';
import 'package:brandify/main.dart';
import 'package:brandify/view/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/app_user/app_user_cubit.dart';
import 'package:brandify/cubits/package/package_cubit.dart';
import 'package:brandify/enum.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:brandify/models/package.dart';
import 'package:brandify/view/screens/account_settings_screen.dart';
import 'package:brandify/view/screens/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:brandify/view/screens/settings/shopify_setup_screen.dart';
import 'package:brandify/view/screens/user_management_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Info Section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: mainColor,
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: BlocBuilder<AppUserCubit, AppUserState>(
                          builder: (context, state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppUserCubit.get(context).brandName ??
                                      "Brandify",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  AppUserCubit.get(context).brandPhone ??
                                      "01xxxxxxxxx",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                // Settings Options
                Text(
                  AppLocalizations.of(context)!.settings,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 20),

                _buildSettingItem(
                  AppLocalizations.of(context)!.accountSettings,
                  Icons.manage_accounts_outlined,
                  AppLocalizations.of(context)!.manageAccount,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccountSettingsScreen(),
                      ),
                    );
                  },
                ),
                
                  BlocBuilder<AppUserCubit, AppUserState>(
                    builder: (context, state) {
                      if (context.read<AppUserCubit>().privileges.contains(
                        Privilege.userManagement,
                      )){
                        return _buildSettingItem(
                          'User Management',
                          Icons.group,
                          'Create and manage users with limited privileges',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserManagementScreen(),
                              ),
                            );
                          },
                        );
                      }
                      else{
                        return Container();
                      }
                    },
                  ),

                // _buildSettingItem(
                //   AppLocalizations.of(context)!.changePackage,
                //   Icons.card_membership_outlined,
                //   AppLocalizations.of(context)!.upgradePlan,
                //   () {
                //     if(Package.type == PackageType.offline)
                //     showModalBottomSheet(
                //       context: context,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.vertical(
                //           top: Radius.circular(20),
                //         ),
                //       ),
                //       builder:
                //           (context) => BlocProvider(
                //             create: (context) => PackageCubit(),
                //             child: BlocConsumer<PackageCubit, PackageState>(
                //               listener: (context, state) {
                //                 if (state is PackageSuccess) {
                //                   Navigator.pop(context);
                //                   ScaffoldMessenger.of(context).showSnackBar(
                //                     SnackBar(content: Text(state.message)),
                //                   );
                //                   Navigator.pushAndRemoveUntil(
                //                     context,
                //                     MaterialPageRoute(
                //                       builder: (_) => HomeScreen(),
                //                     ),
                //                     (route) => false,
                //                   );
                //                 } else if (state is PackageError) {
                //                   ScaffoldMessenger.of(context).showSnackBar(
                //                     SnackBar(
                //                       content: Text(state.error),
                //                       backgroundColor: Colors.red,
                //                     ),
                //                   );
                //                 }
                //               },
                //               builder: (context, state) {
                //                 return Container(
                //                   padding: EdgeInsets.all(20),
                //                   child: Column(
                //                     mainAxisSize: MainAxisSize.min,
                //                     children: [
                //                       Container(
                //                         width: 40,
                //                         height: 4,
                //                         margin: EdgeInsets.only(bottom: 20),
                //                         decoration: BoxDecoration(
                //                           color: Colors.grey[300],
                //                           borderRadius: BorderRadius.circular(
                //                             2,
                //                           ),
                //                         ),
                //                       ),
                //                       Icon(
                //                         Icons.swap_horiz,
                //                         size: 40,
                //                         color: mainColor,
                //                       ),
                //                       SizedBox(height: 15),
                //                       Text(
                //                         AppLocalizations.of(context)!.changePackage,
                //                         style: TextStyle(
                //                           fontSize: 20,
                //                           fontWeight: FontWeight.bold,
                //                         ),
                //                       ),
                //                       SizedBox(height: 10),
                //                       Text(
                //                         AppLocalizations.of(context)!.switchPackageConfirm(Package.type == PackageType.offline ? 'online' : 'offline'),
                //                         textAlign: TextAlign.center,
                //                         style: TextStyle(
                //                           color: Colors.grey[600],
                //                           fontSize: 16,
                //                         ),
                //                       ),
                //                       SizedBox(height: 20),
                //                       if (state is PackageLoading)
                //                         CircularProgressIndicator(
                //                           color: mainColor,
                //                         )
                //                       else
                //                         Row(
                //                           children: [
                //                             Expanded(
                //                               child: TextButton(
                //                                 onPressed:
                //                                     () =>
                //                                         Navigator.pop(context),
                //                                 child: Text(AppLocalizations.of(context)!.cancel),
                //                                 style: TextButton.styleFrom(
                //                                   padding: EdgeInsets.symmetric(
                //                                     vertical: 15,
                //                                   ),
                //                                 ),
                //                               ),
                //                             ),
                //                             SizedBox(width: 10),
                //                             Expanded(
                //                               child: BlocBuilder<
                //                                 PackageCubit,
                //                                 PackageState>(
                //                                 builder: (context, state) {
                //                                   if(state is PackageLoading){
                //                                     return Loading();
                //                                   }
                //                                   else{
                //                                     return ElevatedButton(
                //                                     onPressed: () async{
                //                                       await PackageCubit.get(
                //                                         context,
                //                                       ).convertPackage(context);
                //                                       navigatorKey.currentState?.pop();
                //                                     },
                //                                     style: ElevatedButton.styleFrom(
                //                                       backgroundColor:
                //                                           mainColor,
                //                                       foregroundColor:
                //                                           Colors.white,
                //                                       padding:
                //                                           EdgeInsets.symmetric(
                //                                             vertical: 15,
                //                                           ),
                //                                       shape: RoundedRectangleBorder(
                //                                         borderRadius:
                //                                             BorderRadius.circular(
                //                                               10,
                //                                             ),
                //                                       ),
                //                                     ),
                //                                     child: Text(AppLocalizations.of(context)!.convert),
                //                                   );
                //                                   }
                //                                 },
                //                               ),
                //                             ),
                //                           ],
                //                         ),
                //                     ],
                //                   ),
                //                 );
                //               },
                //             ),
                //           ),
                //     );
                //     else{
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         SnackBar(
                //           content: Text(AppLocalizations.of(context)!.alreadyOnline),
                //         ),
                //       );
                //     }
                //   },
                // ),
                _buildSettingItem(
                  AppLocalizations.of(context)!.language,
                  Icons.language_outlined,
                  AppLocalizations.of(context)!.changeLanguage,
                  () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder:
                          (context) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
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
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: mainColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.language,
                                    size: 40,
                                    color: mainColor,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  AppLocalizations.of(context)!.selectLanguage,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Container(
                                  //margin: EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Cache.getLanguage() == 'en'
                                                    ? mainColor.withOpacity(0.1)
                                                    : Colors.transparent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check_circle,
                                            color:
                                                Cache.getLanguage() == 'en'
                                                    ? mainColor
                                                    : Colors.transparent,
                                          ),
                                        ),
                                        title: Text(
                                          AppLocalizations.of(context)!.english,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(15),
                                          ),
                                        ),
                                        onTap: () {
                                          context
                                              .read<LanguageCubit>()
                                              .changeLanguage('en');
                                          Navigator.pop(context);
                                        },
                                      ),
                                      Divider(height: 10),
                                      ListTile(
                                        leading: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Cache.getLanguage() == 'ar'
                                                    ? mainColor.withOpacity(0.1)
                                                    : Colors.transparent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check_circle,
                                            color:
                                                Cache.getLanguage() == 'ar'
                                                    ? mainColor
                                                    : Colors.transparent,
                                          ),
                                        ),
                                        title: Text(
                                          AppLocalizations.of(context)!.arabic,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            bottom: Radius.circular(15),
                                          ),
                                        ),
                                        onTap: () {
                                          context
                                              .read<LanguageCubit>()
                                              .changeLanguage('ar');
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                    );
                  },
                ),

                _buildSettingItem(
                  AppLocalizations.of(context)!.contactUs,
                  Icons.support_agent_outlined,
                  AppLocalizations.of(context)!.getSupport,
                  () {
                    final Uri whatsappUrl = Uri.parse(
                      'https://wa.me/+201107356032?text=',
                    );
                    launchUrl(
                      whatsappUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                BlocBuilder<AppUserCubit, AppUserState>(
                  builder: (context, state) {
                    if (Package.type == PackageType.online) {
                      return _buildSettingItem(
                        AppLocalizations.of(context)!.connectShopifyTitle,
                        Icons.shopping_bag,
                        AppLocalizations.of(context)!.connectShopifySubtitle,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopifySetupScreen(),
                            ),
                          );
                        },
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
                SizedBox(height: 20),
                _buildLogoutButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap, {
    Color color = mainColor,
  }) {
    return Container(
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
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder:
                (context) => Container(
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
                      Icon(Icons.logout, size: 40, color: Colors.red),
                      SizedBox(height: 15),
                      Text(
                        AppLocalizations.of(context)!.logout,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.logoutConfirm,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      // if(Package.type == PackageType.offline)
                      // Text(
                      //   '!! All your data will be deleted !!',
                      //   style: TextStyle(
                      //     color: Colors.red[600],
                      //     fontSize: 16,
                      //   ),
                      // ),
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
                              onPressed: () {
                                Navigator.pop(context);
                                AppUserCubit.get(context).logout(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(AppLocalizations.of(context)!.logout),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.logout,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
