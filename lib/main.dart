import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:si2_p1_mobile/config/env.dart';
import 'package:si2_p1_mobile/firebase_options.dart';
import 'package:si2_p1_mobile/config/router/app_router.dart';
import 'package:si2_p1_mobile/config/theme/app_theme.dart';
import 'package:si2_p1_mobile/config/theme/theme_provider.dart';
import 'package:si2_p1_mobile/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Env.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    return MaterialApp.router(
      title: 'Auxilio Mecanico',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
