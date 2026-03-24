import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/providers/home_provider.dart';

class MaintenanceApp extends StatelessWidget {
  const MaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: MaterialApp(
        title: '微行动',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surface,
            error: AppColors.error,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            centerTitle: false,
          ),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
            ),
            color: AppColors.surface,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDecorations.radiusMedium),
              ),
              textStyle: AppTextStyles.button,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDecorations.radiusMedium),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDecorations.radiusMedium),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDecorations.spacingMedium,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            hintStyle: const TextStyle(color: AppColors.textHint),
          ),
          dialogTheme: DialogTheme(
            backgroundColor: AppColors.surface,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusLarge),
            ),
            titleTextStyle: AppTextStyles.titleLarge,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.transparent,
            modalBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDecorations.radiusXLarge),
              ),
            ),
          ),
          listTileTheme: ListTileThemeData(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDecorations.spacingLarge,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: AppColors.textPrimary,
            contentTextStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnPrimary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusMedium),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
