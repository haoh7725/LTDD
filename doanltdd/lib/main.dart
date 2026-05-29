import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/auth/login_screen.dart';
import 'views/candidate/candidate_home_screen.dart';
import 'views/employer/employer_home_screen.dart';
import 'views/admin/admin_home_screen.dart';
import 'utils/app_theme.dart';
import 'viewmodels/job_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => JobViewModel()),
      ],
      child: MaterialApp(
        title: 'Job App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.user == null) {
      return const LoginScreen();
    }

    switch (auth.role) {
      case 'employer':
        return EmployerHomeScreen();
      case 'admin':
        return AdminHomeScreen();
      default:
        return CandidateHomeScreen();
    }
  }
}