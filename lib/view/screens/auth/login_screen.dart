// ignore_for_file: prefer_const_constructors

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/login/login_cubit.dart';
import 'package:brandify/cubits/country_code/country_code_cubit.dart';
import 'package:brandify/main.dart';
import 'package:brandify/view/screens/auth/forgot_password_screen.dart';
import 'package:brandify/view/screens/auth/register_screen.dart';
import 'package:brandify/view/widgets/custom_button.dart';
import 'package:brandify/view/widgets/custom_texfield.dart';
import 'package:brandify/view/widgets/country_code_picker.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin{
  late Animation<Offset> animation;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1400)
    );

    animation = Tween<Offset>(
      begin: Offset(0,-2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack)
    );

    Timer(Duration(milliseconds: 200), (){
      controller.forward();
    });

    // String lang = BlocProvider.of<LanguageCubit>(context).lang;
    // BlocProvider.of<PackagesCubit>(context).getPackages(lang);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var loginCubit = BlocProvider.of<LoginCubit>(context);
    return BlocProvider(
      create: (context) => CountryCodeCubit(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20,20,20,20),
            child: Center(
              child: ListView(
                // mainAxisAlignment: MainAxisAlignment.center,
                // mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 60, 
                  ),
                  Center(
                    child: SlideTransition(
                      position: animation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/images/logo_primary.png",
                            width: 70,
                            //height: 100,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Brandify",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: mainColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 1.5,
                        margin: EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: mainColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 25,),
                  Column(
                    children: [
                      // Text(
                      //   "Transform Your Business Vision Into Reality",
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(
                      //         color: Colors.grey[800],
                      //         fontSize: 16,
                      //         fontWeight: FontWeight.w600,
                      //         letterSpacing: 0.5,
                      //       ),
                      // ),
                      //SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.appSlogan,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      // Text(
                      //   "Go follow up your business",//"أدخل وتابع شغلك دلوقتي",
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(
                      //         //color: mainColor,
                      //         //fontSize: 18,
                      //       ),
                      // ),
                      const SizedBox(
                        height: 20,
                      ),
                      Form(
                        key: loginCubit.formKey,
                        child: Column(
                          children: [
                            // CustomTextFormField(
                            //   prefix: Icon(
                            //         Icons.text_fields_rounded,
                            //         color: Colors.grey[600],
                            //       ),
                            //   text: "Brand name",
                            //   keyboardType: TextInputType.emailAddress,
                            //   onSaved: (value) {
                            //         loginCubit.name = value.toString();
                            //       },
                            //   onValidate: (value) {
                            //         if (value!.isEmpty) {
                            //           return "Enter brand name";
                            //         }
                            //         return null;
                            //       },
                            // ),
                            // const SizedBox(
                            //   height: 10,
                            // ),
                            CustomTextFormField(
                              prefix: Icon(
                                Icons.email_rounded,
                                color: Colors.grey[600],
                              ),
                              text: AppLocalizations.of(context)?.email ?? 'Email',
                              keyboardType: TextInputType.emailAddress,
                              onSaved: (value) {
                                loginCubit.email = value!.trim();
                              },
                              onValidate: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.invalidEmail;
                                }
                                if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}").hasMatch(value)) {
                                  return AppLocalizations.of(context)!.invalidEmail;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            CustomTextFormField(
                              prefix: Icon(
                                Icons.lock,
                                color: Colors.grey[600],
                              ),
                              text: AppLocalizations.of(context)!.password,
                              obscureText: true,
                              onSaved: (value) {
                                loginCubit.password = value.toString();
                              },
                              onValidate: (value) {
                                if (value!.isEmpty) {
                                  return AppLocalizations.of(context)!.enterPassword;
                                }
                                else if(value.length < 8){
                                  return AppLocalizations.of(context)!.minPassword;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      //SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              AppLocalizations.of(context)!.forgotPassword,
                              style: TextStyle(
                                color: mainColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      BlocBuilder<LoginCubit, LoginState>(
                        builder: (context, state) {
                          if(state is LoadingState){
                            return const Center(
                              child: CircularProgressIndicator(color: mainColor,),
                            );
                          }
                          else{
                            return CustomButton(
                              text: AppLocalizations.of(context)!.login,
                              onPressed: () {
                                loginCubit.onLogin(context);
                              },
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10,),
                      CustomButton(
                        bgColor: Colors.green.shade600,
                        text: AppLocalizations.of(context)!.createAccount,
                        onPressed: () {
                          navigatorKey.currentState!.push(
                            MaterialPageRoute(builder: (context) => RegisterScreen())
                          );
                        },
                      ),
                      // const SizedBox(height: 5,),
                      // CustomButton(
                      //   bgColor: Colors.green.shade600,
                      //   text: AppLocalizations.of(context)!.new_registration,
                      //   onPressed: (){
                      //         Navigator.pushNamed(context, registerPath);
                      //       },
                      // ),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  // Spacer(),
                  // Text(
                  //   AppLocalizations.of(context)!.registration_agreement,
                  //   style: TextStyle(color: Colors.grey, height: 1),
                  // ),
                  // InkWell(
                  //   onTap: () {
                  //         Navigator.pushNamed(context, privacyPolicyPath);
                  //       },
                  //   child: Text(
                  //         AppLocalizations.of(context)!.terms_of_use_and_privacy_policy,
                  //         style: TextStyle(
                  //           color: mainColor,
                  //           //height: 0.1
                  //           //fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
