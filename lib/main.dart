import 'package:brandify/cubits/country_code/country_code_cubit.dart';
import 'package:brandify/cubits/language/language_cubit.dart';
import 'package:brandify/cubits/phone_number/phone_number_cubit.dart';
import 'package:brandify/view/screens/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/cubits/add_product/add_product_cubit.dart';
import 'package:brandify/cubits/ads/ads_cubit.dart';
import 'package:brandify/cubits/all_sells/all_sells_cubit.dart';
import 'package:brandify/cubits/app_user/app_user_cubit.dart';
import 'package:brandify/cubits/best_products/best_products_cubit.dart';
import 'package:brandify/cubits/extra_expenses/extra_expenses_cubit.dart';
import 'package:brandify/cubits/login/login_cubit.dart';
import 'package:brandify/cubits/lowest_products/lowest_products_cubit.dart';
import 'package:brandify/cubits/one_product_sells/one_product_sells_cubit.dart';
import 'package:brandify/cubits/pie_chart/pie_chart_cubit.dart';
import 'package:brandify/cubits/products/products_cubit.dart';
import 'package:brandify/cubits/register/register_cubit.dart';
import 'package:brandify/cubits/reports/reports_cubit.dart';
import 'package:brandify/cubits/sell/sell_cubit.dart';
import 'package:brandify/cubits/sides/sides_cubit.dart';
import 'package:brandify/firebase_options.dart';
import 'package:brandify/models/firebase/firestore/shopify_services.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:brandify/models/local/hive_services.dart';
import 'package:brandify/models/product.dart';
import 'package:brandify/view/screens/auth/register_screen.dart';
import 'package:brandify/view/screens/best_products_screen.dart';
import 'package:brandify/view/screens/dummy.dart';
import 'package:brandify/view/screens/packages/package_selection_screen.dart';
import 'package:brandify/view/screens/products/add_product_screen.dart';
import 'package:brandify/view/screens/home_screen.dart';
import 'package:brandify/view/screens/auth/login_screen.dart';
import 'package:brandify/view/screens/products/products_screen.dart';
import 'package:brandify/view/screens/sell_screen.dart';
import 'package:brandify/view/screens/settings/shopify_setup_screen.dart';
import 'package:brandify/view/screens/shopify_orders_screen.dart';
import 'package:brandify/view/screens/welcome_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brandify/l10n/l10n.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await ShopifyServices.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  await Cache.init();
  //Cache.setPackageType("offline");
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LanguageCubit()),
        BlocProvider(create: (_) => LoginCubit()),
        BlocProvider(create: (_) => ProductsCubit()),
        BlocProvider(create: (_) => SidesCubit()),
        BlocProvider(create: (_) => AllSellsCubit()),
        BlocProvider(create: (_) => ReportsCubit()),
        BlocProvider(create: (_) => BestProductsCubit()),
        BlocProvider(create: (_) => LowestProductsCubit()),
        BlocProvider(create: (_) => AdsCubit()),
        BlocProvider(create: (_) => OneProductSellsCubit()),
        BlocProvider(create: (_) => PieChartCubit()),
        BlocProvider(create: (_) => RegisterCubit()),
        BlocProvider(create: (_) => AppUserCubit()),
        BlocProvider(create: (_) => ExtraExpensesCubit()),
        BlocProvider(create: (_) => CountryCodeCubit()),
        BlocProvider(create: (_) => PhoneNumberCubit()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Brandify',
          navigatorKey: navigatorKey,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('ar'), // Arabic
          ],
          locale: Locale(Cache.getLanguage() ?? 'en'),
          theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: mainColor),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
                elevation: 5,
                centerTitle: true,
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
              ),
              fontFamily: locale.languageCode == 'ar' ? 'Jazeera' : 'CreatoDisplay',
            ),
          home: FirebaseAuth.instance.currentUser != null ? HomeScreen() : WelcomeScreen(),
          //home: WelcomeScreen(),
        );
      },
    );
  }
}
