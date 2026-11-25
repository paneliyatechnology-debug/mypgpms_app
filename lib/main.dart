import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/admission/presentation/bloc/admission_bloc.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Dependency Injection
  await di.initDependencies();

  runApp(const MYPGPMSApp());
}

class MYPGPMSApp extends StatelessWidget {

  const MYPGPMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>(),
        ),
        BlocProvider<AdmissionBloc>(
          create: (_) => di.sl<AdmissionBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'MYPGPMS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
