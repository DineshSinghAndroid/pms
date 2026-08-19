import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/category/category_bloc.dart';
import 'bloc/category/category_event.dart';
import 'bloc/product_type/product_type_bloc.dart';
import 'bloc/product_type/product_type_event.dart';
import 'bloc/user/user_bloc.dart';
import 'bloc/user/user_event.dart';
import 'bloc/vendor/vendor_bloc.dart';
import 'bloc/vendor/vendor_event.dart';
import 'bloc/wing/wing_bloc.dart';
import 'bloc/wing/wing_event.dart';
import 'firebase_options.dart';
import 'repositories/category_repository.dart';
import 'repositories/product_type_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/vendor_repository.dart';
import 'repositories/wing_repository.dart';
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
        RepositoryProvider<CategoryRepository>(
          create: (context) => CategoryRepository(),
        ),
        RepositoryProvider<ProductTypeRepository>(
          create: (context) => ProductTypeRepository(),
        ),
        RepositoryProvider<WingRepository>(
          create: (context) => WingRepository(),
        ),
        RepositoryProvider<VendorRepository>(
          create: (context) => VendorRepository(),
        ),
        RepositoryProvider<UserRepository>(
          create: (context) => UserRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CategoryBloc>(
            create: (context) => CategoryBloc(
              repository: context.read<CategoryRepository>(),
            )..add(const FetchCategoriesEvent()),
          ),
          BlocProvider<ProductTypeBloc>(
            create: (context) => ProductTypeBloc(
              repository: context.read<ProductTypeRepository>(),
            )..add(const FetchProductTypesEvent()),
          ),
          BlocProvider<WingBloc>(
            create: (context) => WingBloc(
              repository: context.read<WingRepository>(),
            )..add(const FetchWingsEvent()),
          ),
          BlocProvider<VendorBloc>(
            create: (context) => VendorBloc(
              repository: context.read<VendorRepository>(),
            )..add(const FetchVendorsEvent()),
          ),
          BlocProvider<UserBloc>(
            create: (context) => UserBloc(
              repository: context.read<UserRepository>(),
            )..add(const FetchUsersEvent()),
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
