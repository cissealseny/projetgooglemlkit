import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/bloc/bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent runtime font download failures on offline/dev emulators.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize dependency injection
  await configureDependencies();

  // Set bloc observer
  Bloc.observer = AppBlocObserver();

  runApp(const MLKitApp());
}
