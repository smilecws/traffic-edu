import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_locale_scope.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/locale_service.dart';
import 'services/question_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuizApp());
}

class QuizApp extends StatefulWidget {
  const QuizApp({super.key});

  @override
  State<QuizApp> createState() => _QuizAppState();
}

class _QuizAppState extends State<QuizApp> {
  Locale _locale = const Locale('ko');

  @override
  void initState() {
    super.initState();
    LocaleService.loadPreferredLocale().then((locale) {
      if (!mounted) return;
      QuestionService.setLanguageCode(locale.languageCode);
      setState(() => _locale = locale);
    });
  }

  Future<void> _setLocale(Locale locale) async {
    if (!LocaleService.isSupported(locale)) return;
    await LocaleService.saveLanguageCode(locale.languageCode);
    QuestionService.setLanguageCode(locale.languageCode);
    if (mounted) setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surfaceWhite,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderLight,
    );
    return AppLocaleScope(
      setLocale: _setLocale,
      child: MaterialApp(
        title: '운전면허 학과시험 1000제',
        debugShowCheckedModeBanner: false,
        locale: _locale,
        supportedLocales: LocaleService.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.juaTextTheme(),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.surfaceWhite,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            titleTextStyle: GoogleFonts.jua(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
