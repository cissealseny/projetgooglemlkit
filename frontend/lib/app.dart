import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/premium_router.dart';
import 'core/theme/premium_theme.dart';
import 'core/di/injection.dart';
import 'features/auth/bloc/auth_bloc.dart';

class MLKitApp extends StatelessWidget {
  const MLKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
            create: (_) => getIt<AuthBloc>()..add(CheckAuthStatus())),
      ],
      child: MaterialApp.router(
        title: 'ML Kit Pro',
        debugShowCheckedModeBanner: false,
        theme: PremiumTheme.light,
        darkTheme: PremiumTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: premiumRouter,
      ),
    );
  }
}
