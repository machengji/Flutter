import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        title: '微行动助手',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const HomePage(),
      ),
    );
  }
}
