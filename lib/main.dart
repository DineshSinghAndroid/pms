import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/announcement_bloc.dart';
import 'bloc/announcement_event.dart';
import 'firebase_options.dart';
import 'repositories/announcement_repository.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const PmsApp());
}

class PmsApp extends StatelessWidget {
  const PmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AnnouncementRepository>(
          create: (context) => AnnouncementRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AnnouncementBloc>(
            create: (context) => AnnouncementBloc(
              repository: context.read<AnnouncementRepository>(),
            )..add(const FetchAnnouncementEvent()),
          ),
        ],
        child: MaterialApp(
          title: 'PMS Admin',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB), // Blue 600
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// Authentication State Listener Gate
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen(user: snapshot.data!);
        }
        return const LoginScreen();
      },
    );
  }
}
