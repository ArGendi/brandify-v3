import 'package:brandify/cubits/language/language_cubit.dart';
import 'package:flutter/material.dart';
import 'package:brandify/constants.dart';
import 'package:brandify/l10n/l10n.dart';
import 'package:brandify/models/local/cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context)!.language),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _LanguageItem(
              title: 'English',
              locale: const Locale('en'),
              isSelected: L10n.getLocale(context).languageCode == 'en',
            ),
            const SizedBox(height: 10),
            _LanguageItem(
              title: 'العربية',
              locale: const Locale('ar'),
              isSelected: L10n.getLocale(context).languageCode == 'ar',
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageItem extends StatelessWidget {
  final String title;
  final Locale locale;
  final bool isSelected;

  const _LanguageItem({
    required this.title,
    required this.locale,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: mainColor) : null,
      onTap: () async {
        context.read<LanguageCubit>().changeLanguage(locale.languageCode);
        // await Cache.setLanguage();
        // L10n.setLocale(context, locale);
      },
    );
  }
}