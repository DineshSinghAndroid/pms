import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/category/category_bloc.dart';
import 'bloc/category/category_event.dart';
import 'bloc/digital_studio/digital_studio_bloc.dart';
import 'bloc/digital_studio/digital_studio_event.dart';
import 'bloc/print_order/print_order_bloc.dart';
import 'bloc/product_type/product_type_bloc.dart';
import 'bloc/product_type/product_type_event.dart';
import 'bloc/purchase_request/purchase_request_bloc.dart';
import 'bloc/user/user_bloc.dart';
import 'bloc/user/user_event.dart';
import 'bloc/vendor/vendor_bloc.dart';
import 'bloc/vendor/vendor_event.dart';
import 'bloc/wing/wing_bloc.dart';
import 'bloc/wing/wing_event.dart';
import 'firebase_options.dart';
import 'bloc/payment/payment_bloc.dart';
import 'bloc/payment/payment_event.dart';
import 'repositories/category_repository.dart';
import 'repositories/digital_studio_repository.dart';
import 'repositories/payment_repository.dart';
import 'repositories/print_order_repository.dart';
import 'repositories/product_type_repository.dart';
import 'repositories/purchase_request_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/vendor_repository.dart';
import 'repositories/wing_repository.dart';
import 'repositories/news_tracking_repository.dart';
import 'bloc/news_tracking/news_tracking_bloc.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';
import 'theme/pms_theme.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_screen.dart';
import 'views/permissions/permission_required_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.instance.initialize(rootNavigatorKey);
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
        RepositoryProvider<PurchaseRequestRepository>(
          create: (context) => PurchaseRequestRepository(),
        ),
        RepositoryProvider<PrintOrderRepository>(
          create: (context) => PrintOrderRepository(),
        ),
        RepositoryProvider<PaymentRepository>(
          create: (context) => PaymentRepository(),
        ),
        RepositoryProvider<DigitalStudioRepository>(
          create: (context) => DigitalStudioRepository(),
        ),
        RepositoryProvider<NewsTrackingRepository>(
          create: (context) => NewsTrackingRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CategoryBloc>(
            create: (context) =>
                CategoryBloc(repository: context.read<CategoryRepository>())
                  ..add(const FetchCategoriesEvent()),
          ),
          BlocProvider<ProductTypeBloc>(
            create: (context) => ProductTypeBloc(
              repository: context.read<ProductTypeRepository>(),
            )..add(const FetchProductTypesEvent()),
          ),
          BlocProvider<WingBloc>(
            create: (context) =>
                WingBloc(repository: context.read<WingRepository>())
                  ..add(const FetchWingsEvent()),
          ),
          BlocProvider<VendorBloc>(
            create: (context) =>
                VendorBloc(repository: context.read<VendorRepository>())
                  ..add(const FetchVendorsEvent()),
          ),
          BlocProvider<UserBloc>(
            create: (context) =>
                UserBloc(repository: context.read<UserRepository>())
                  ..add(const FetchUsersEvent()),
          ),
          BlocProvider<PurchaseRequestBloc>(
            create: (context) => PurchaseRequestBloc(
              repository: context.read<PurchaseRequestRepository>(),
            ),
          ),
          BlocProvider<PrintOrderBloc>(
            create: (context) => PrintOrderBloc(
              repository: context.read<PrintOrderRepository>(),
            ),
          ),
          BlocProvider<PaymentBloc>(
            create: (context) => PaymentBloc(
              repository: context.read<PaymentRepository>(),
            )..add(const FetchPaymentsEvent()),
          ),
          BlocProvider<DigitalStudioBloc>(
            create: (context) => DigitalStudioBloc(
              repository: context.read<DigitalStudioRepository>(),
            )..add(const FetchDigitalStudioDataEvent()),
          ),
          BlocProvider<NewsTrackingBloc>(
            create: (context) => NewsTrackingBloc(
              repository: context.read<NewsTrackingRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          title: 'PMS Admin',
          debugShowCheckedModeBanner: false,
          theme: PmsTheme.light,
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
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          final phone = snapshot.data!.phoneNumber ?? '';
          if (phone.isNotEmpty) {
            final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
            NotificationService.instance.registerToken(cleanPhone);
          }
          return PermissionGate(user: snapshot.data!);
        }
        return const LoginScreen();
      },
    );
  }
}

/// Permission Enforcement Gate
class PermissionGate extends StatefulWidget {
  final User user;
  const PermissionGate({super.key, required this.user});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _allGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final granted = await PermissionService.areAllPermissionsGranted();
    if (mounted) {
      setState(() {
        _allGranted = granted;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    if (_allGranted) {
      return HomeScreen(user: widget.user);
    }

    return PermissionRequiredScreen(
      onAllGranted: () {
        setState(() => _allGranted = true);
      },
    );
  }
}
