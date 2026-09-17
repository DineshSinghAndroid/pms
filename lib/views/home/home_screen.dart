import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/category/category_bloc.dart';
import '../../bloc/category/category_event.dart';
import '../../bloc/print_order/print_order_bloc.dart';
import '../../bloc/print_order/print_order_event.dart';
import '../../bloc/product_type/product_type_bloc.dart';
import '../../bloc/product_type/product_type_event.dart';
import '../../bloc/purchase_request/purchase_request_bloc.dart';
import '../../bloc/purchase_request/purchase_request_event.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_event.dart';
import '../../bloc/vendor/vendor_bloc.dart';
import '../../bloc/vendor/vendor_event.dart';
import '../../bloc/wing/wing_bloc.dart';
import '../../bloc/wing/wing_event.dart';
import '../../bloc/digital_studio/digital_studio_bloc.dart';
import '../../bloc/digital_studio/digital_studio_event.dart';
import '../../bloc/news_tracking/news_tracking_bloc.dart';
import '../../bloc/news_tracking/news_tracking_event.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/purchase_request_repository.dart';
import '../../repositories/product_type_repository.dart';
import '../../repositories/wing_repository.dart';
import '../../bloc/payment/payment_bloc.dart';
import '../../bloc/payment/payment_event.dart';
import '../categories/categories_tab_view.dart';
import '../dashboard/dashboard_tab_view.dart';
import '../delivery_logs/delivery_logs_tab_view.dart';
import '../digital_studio/digital_studio_management_tab_view.dart';
import '../news_tracking/news_tracking_tab_view.dart';
import '../payments/payments_tab_view.dart';
import '../layout/side_menu_drawer.dart';
import '../post_orders/post_orders_tab_view.dart';
import '../print_orders/print_orders_tab_view.dart';
import '../product_types/product_types_tab_view.dart';
import '../purchase_requests/purchase_requests_tab_view.dart';
import '../settings/settings_tab_view.dart';
import '../users/users_tab_view.dart';
import '../vendors/vendors_tab_view.dart';
import '../wings/wings_tab_view.dart';
import '../legal/legal_doc_tab_view.dart';
import '../../repositories/notification_repository.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../services/app_update_service.dart';
import '../../services/user_location_sync_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_gradient_background.dart';
import '../../widgets/pms_status_chip.dart';
import '../../theme/pms_theme.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final NotificationRepository _notificationRepo = NotificationRepository();
  NavMenu _selectedMenu = NavMenu.dashboard;
  DateTime? _lastBackPressTime;
  UserModel? _userProfile;
  bool _isLoadingProfile = true;
  bool _isAccountInactive = false;
  String _inactiveMessage = 'Your user account is marked inactive. Contact Super Admin.';
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.onNotificationReceived = () {
      if (mounted) _fetchUnreadCount();
    };
    _loadUserProfile();
    _checkAppUpdate();
    UserLocationSyncService().syncCurrentLocation(source: 'app_launch');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.onNotificationReceived = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _selectedMenu == NavMenu.dashboard) {
      _checkAppUpdate();
    }
  }

  void _checkAppUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('📲 [HomeScreen] Checking app update on home page arrival...');
        AppUpdateService().checkForUpdate(context);
      }
    });
  }

  Future<void> _loadUserProfile() async {
    final phone = widget.user.phoneNumber ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final standardPhone = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
    if (standardPhone.isNotEmpty) {
      ApiService.setUserPhone(standardPhone);
    }

    try {
      final repo = context.read<UserRepository>();
      final profile = await repo.getProfile(cleanPhone);
      final isSuper = profile?.isSuperAdmin ?? false;
      if (profile != null && !profile.isActive && !isSuper) {
        throw const InactiveUserException();
      }

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });

        // Register device FCM token with backend for push notifications
        NotificationService.instance.registerToken(cleanPhone);
        _fetchUnreadCount();

        // Trigger appropriate data fetches depending on role
        if (isDesigner && _userProfile != null) {
          context.read<PurchaseRequestBloc>().add(
            FetchPurchaseRequestsEvent(
              designerId: _userProfile!.id,
              phone: cleanPhone,
            ),
          );
          context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: cleanPhone));
        } else if (isVendor) {
          context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: cleanPhone));
          context.read<PaymentBloc>().add(const FetchPaymentsEvent());
        } else if (isDigitalStudioEmployee) {
          context.read<DigitalStudioBloc>().add(FetchDigitalStudioDataEvent(phone: cleanPhone));
          _selectedMenu = NavMenu.digitalStudio;
        } else {
          context.read<PurchaseRequestBloc>().add(
            const FetchPurchaseRequestsEvent(),
          );
          context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: cleanPhone));
          context.read<PrintOrderBloc>().add(const FetchDeliveryLogsEvent());
          context.read<PaymentBloc>().add(const FetchPaymentsEvent());
          context.read<PaymentBloc>().add(const FetchEligiblePaymentItemsEvent());
        }

        if (!isDesigner && (isSuperAdmin || isManager || isDigitalStudioIncharge || isWingIncharge || isDigitalStudioEmployee)) {
          context.read<DigitalStudioBloc>().add(FetchDigitalStudioDataEvent(phone: cleanPhone));
        }

        if (isSuperAdmin || isManager) {
          context.read<NewsTrackingBloc>().add(FetchNewsTrackingDataEvent(phone: cleanPhone));
        }

        if (isSuperAdmin) {
          debugPrint('👑 [HomeScreen] SuperAdmin detected. Fetching users directory...');
          context.read<UserBloc>().add(FetchUsersEvent(phone: standardPhone));
        }

        // Pre-fetch active designers so the Assign button opens instantly with 0ms delay
        final roleLower = (_userProfile?.role ?? '').toLowerCase().trim();
        if (isSuperAdmin || isManager || isDigitalStudioIncharge || roleLower == 'admin') {
          debugPrint('🎨 [HomeScreen] Pre-fetching designers for PR assignment...');
          PurchaseRequestRepository().getDesigners();
        }

        // Pre-fetch product types and wings so Create PR opens instantly with 0ms delay
        if (isSuperAdmin || isManager || isWingIncharge || roleLower == 'admin') {
          debugPrint('📦 [HomeScreen] Pre-fetching Product Types and Wings for PR creation...');
          context.read<ProductTypeBloc>().add(const FetchProductTypesEvent());
          context.read<WingBloc>().add(const FetchWingsEvent());
          ProductTypeRepository().getProductTypes();
          WingRepository().getWings();
        }

        // Check for app update as soon as user profile loads on home page
        _checkAppUpdate();
      }
    } on InactiveUserException catch (e) {
      if (mounted) {
        setState(() {
          _isAccountInactive = true;
          _inactiveMessage = e.message;
          _isLoadingProfile = false;
        });
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
        _checkAppUpdate();
      }
    }
  }

  bool get isSuperAdmin => _userProfile?.isSuperAdmin ?? false;
  bool get isAdmin =>
      isSuperAdmin ||
      _userProfile?.role.toLowerCase() == 'admin' ||
      _userProfile?.role.toLowerCase() == 'administrator' ||
      _userProfile?.role.toLowerCase() == 'superadmin' ||
      _userProfile?.role.toLowerCase() == 'super_admin';

  bool get isManager => _userProfile?.role.toLowerCase() == 'manager';
  bool get isDesigner =>
      _userProfile?.role == 'Designer' ||
      _userProfile?.role.toLowerCase() == 'designer';
  bool get isDigitalStudioIncharge =>
      _userProfile?.role == 'Digital Studio Incharge' ||
      _userProfile?.role.toLowerCase() == 'digital_studio_incharge';
  bool get isDigitalStudioEmployee =>
      _userProfile?.isDigitalStudioEmployee ?? false;
  bool get isStoreIncharge =>
      _userProfile?.role == 'Store Incharge' ||
      _userProfile?.role.toLowerCase() == 'store incharge' ||
      _userProfile?.role.toLowerCase() == 'store_incharge';
  bool get isWingIncharge => _userProfile?.isWingIncharge ?? false;
  bool get isVendor => _userProfile?.role.toLowerCase() == 'vendor';

  void _onMenuSelected(NavMenu menu) {
    setState(() {
      _selectedMenu = menu;
    });
    if (menu == NavMenu.dashboard) {
      _checkAppUpdate();
    }
  }

  void _refreshCurrentTab() {
    final phone = widget.user.phoneNumber ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    if (!isDesigner &&
        (isSuperAdmin ||
            isManager ||
            isDigitalStudioIncharge ||
            isWingIncharge ||
            (_userProfile?.isDigitalStudioEmployee ?? false))) {
      context.read<DigitalStudioBloc>().add(RefreshDigitalStudioEvent(phone: cleanPhone));
    }

    if (isDigitalStudioIncharge) {
      context.read<PurchaseRequestBloc>().add(const FetchPurchaseRequestsEvent());
      context.read<CategoryBloc>().add(const RefreshCategoriesEvent());
      context.read<ProductTypeBloc>().add(const RefreshProductTypesEvent());
      context.read<WingBloc>().add(const RefreshWingsEvent());
    } else if (isSuperAdmin || isWingIncharge || isStoreIncharge || isManager) {
      context.read<PurchaseRequestBloc>().add(
        isWingIncharge
            ? FetchPurchaseRequestsEvent(phone: cleanPhone)
            : const FetchPurchaseRequestsEvent(),
      );
      context.read<CategoryBloc>().add(const RefreshCategoriesEvent());
      context.read<ProductTypeBloc>().add(const RefreshProductTypesEvent());
      context.read<WingBloc>().add(const RefreshWingsEvent());
      context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: cleanPhone));

      if (isSuperAdmin || isManager) {
        context.read<VendorBloc>().add(const RefreshVendorsEvent());
        context.read<PaymentBloc>().add(const FetchPaymentsEvent());
        context.read<PaymentBloc>().add(const FetchEligiblePaymentItemsEvent());
        context.read<NewsTrackingBloc>().add(FetchNewsTrackingDataEvent(phone: cleanPhone));
      }
      if (isSuperAdmin) {
        context.read<UserBloc>().add(RefreshUsersEvent(phone: cleanPhone));
      }
      if (isSuperAdmin || isManager || isStoreIncharge) {
        context.read<PrintOrderBloc>().add(const FetchDeliveryLogsEvent());
      }
    } else if (isDesigner) {
      context.read<PurchaseRequestBloc>().add(
        FetchPurchaseRequestsEvent(
          designerId: _userProfile?.id,
          phone: cleanPhone,
        ),
      );
      context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: cleanPhone));
    } else {
      context.read<VendorBloc>().add(const RefreshVendorsEvent());
      context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: cleanPhone));
    }
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final phone = widget.user.phoneNumber ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) return;
    try {
      final res = await _notificationRepo.getNotifications(cleanPhone);
      if (mounted) {
        setState(() {
          _unreadNotificationCount = res.unreadCount;
        });
      }
    } catch (_) {}
  }

  Widget _buildBody() {
    final effectiveUserPhone = widget.user.phoneNumber ?? _userProfile?.phone ?? '';

    switch (_selectedMenu) {
      case NavMenu.dashboard:
        return DashboardTabView(
          isSuperAdmin: isSuperAdmin,
          isDesigner: isDesigner,
          userProfile: _userProfile,
          userPhone: effectiveUserPhone,
          onNavigate: (menu) {
            setState(() {
              _selectedMenu = menu;
            });
          },
        );
      case NavMenu.vendors:
        return (!isDigitalStudioEmployee && (isSuperAdmin || isManager))
            ? const VendorsTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: effectiveUserPhone,
                onNavigate: (m) => setState(() => _selectedMenu = m),
              );
      case NavMenu.purchaseRequests:
        return (!isDigitalStudioIncharge && !isDigitalStudioEmployee)
            ? PurchaseRequestsTabView(
                isSuperAdmin: isSuperAdmin,
                currentUser: _userProfile,
              )
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: effectiveUserPhone,
                onNavigate: (m) => setState(() => _selectedMenu = m),
              );
      case NavMenu.printOrders:
        return (!isDigitalStudioIncharge && !isDigitalStudioEmployee && (isSuperAdmin || isStoreIncharge || isManager || isDesigner || _userProfile?.role.toLowerCase() == 'vendor'))
            ? PrintOrdersTabView(
                isSuperAdmin: isSuperAdmin || isStoreIncharge || isManager,
                isDesigner: isDesigner,
                userProfile: _userProfile,
              )
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: effectiveUserPhone,
                onNavigate: (m) => setState(() => _selectedMenu = m),
              );
      case NavMenu.deliveryLogs:
        return (!isDigitalStudioEmployee && (isSuperAdmin || isManager || isStoreIncharge))
            ? DeliveryLogsTabView(
                userProfile: _userProfile,
                isSuperAdmin: isSuperAdmin,
              )
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: effectiveUserPhone,
                onNavigate: (m) => setState(() => _selectedMenu = m),
              );
      case NavMenu.payments:
        return (!isDigitalStudioEmployee && (isSuperAdmin || isManager))
            ? PaymentsTabView(
                currentUser: _userProfile,
                isSuperAdmin: isSuperAdmin,
              )
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: effectiveUserPhone,
                onNavigate: (m) => setState(() => _selectedMenu = m),
              );
      case NavMenu.postOrders:
        return (!isDigitalStudioEmployee && (isSuperAdmin || isDigitalStudioIncharge || isDesigner || isManager))
            ? PostOrdersTabView(
                isSuperAdmin: isSuperAdmin || isDigitalStudioIncharge || isManager,
                isDesigner: isDesigner,
                currentUser: _userProfile,
              )
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: effectiveUserPhone,
                onNavigate: (m) => setState(() => _selectedMenu = m),
              );
      case NavMenu.digitalStudio:
        return (!isDesigner &&
                (isSuperAdmin ||
                    isManager ||
                    isDigitalStudioIncharge ||
                    isWingIncharge ||
                    (_userProfile?.isDigitalStudioEmployee ?? false)))
            ? DigitalStudioManagementTabView(
                currentUser: _userProfile,
                isSuperAdmin: isSuperAdmin,
                isManager: isManager,
                isDigitalStudioIncharge: isDigitalStudioIncharge,
                isDesigner: isDesigner,
                isWingIncharge: isWingIncharge,
              )
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: effectiveUserPhone,
                onNavigate: (m) => setState(() => _selectedMenu = m),
              );
      case NavMenu.newsTracking:
        return (isSuperAdmin || isManager)
            ? NewsTrackingTabView(
                currentUser: _userProfile,
                isSuperAdmin: isSuperAdmin,
                userPhone: effectiveUserPhone,
              )
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: effectiveUserPhone,
                onNavigate: (m) => setState(() => _selectedMenu = m),
              );
      case NavMenu.categories:
        return isSuperAdmin
            ? const CategoriesTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: effectiveUserPhone,
              );
      case NavMenu.productTypes:
        return isSuperAdmin
            ? const ProductTypesTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: effectiveUserPhone,
              );
      case NavMenu.wings:
        return isSuperAdmin
            ? const WingsTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: effectiveUserPhone,
              );
      case NavMenu.users:
        return isSuperAdmin
            ? UsersTabView(
                isSuperAdmin: true,
                userPhone: effectiveUserPhone,
              )
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: effectiveUserPhone,
              );
      case NavMenu.settings:
        return SettingsTabView(
          isSuperAdmin: isSuperAdmin,
          isAdmin: isAdmin,
          userPhone: effectiveUserPhone,
        );
      case NavMenu.privacyPolicy:
        return const LegalDocTabView(type: LegalDocType.privacyPolicy);
      case NavMenu.termsAndConditions:
        return const LegalDocTabView(type: LegalDocType.termsAndConditions);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAccountInactive) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      size: 44,
                      color: PmsTheme.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Account Inactive',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: PmsTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _inactiveMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: PmsTheme.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Back to Login',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PmsTheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoadingProfile) {
      return const Scaffold(
        body: AppGradientBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final String roleTitle;
    final Color roleColor;
    if (isSuperAdmin) {
      roleTitle = 'Super Admin';
      roleColor = PmsTheme.primary;
    } else if (isManager) {
      roleTitle = 'Manager';
      roleColor = PmsTheme.primary;
    } else if (isDigitalStudioIncharge) {
      roleTitle = 'Digital Studio Incharge';
      roleColor = PmsTheme.secondary;
    } else if (isStoreIncharge) {
      roleTitle = 'Store Incharge';
      roleColor = const Color(0xFF0891B2);
    } else if (isWingIncharge) {
      roleTitle = 'Wing Incharge';
      roleColor = PmsTheme.teal;
    } else if (isDesigner) {
      roleTitle = 'Designer';
      roleColor = const Color(0xFFD97706);
    } else if (isVendor) {
      roleTitle = 'Printing Vendor';
      roleColor = const Color(0xFF059669);
    } else {
      roleTitle = _userProfile?.role ?? 'User';
      roleColor = PmsTheme.textSecondary;
    }

    final String displayName = (_userProfile?.name != null &&
            _userProfile!.name.trim().isNotEmpty)
        ? _userProfile!.name.trim()
        : (isSuperAdmin ? 'Super Admin' : roleTitle);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

        // 1. If side drawer is open, close it
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }

        // 2. If user is on a sub-view / other tab, return to Dashboard first
        if (_selectedMenu != NavMenu.dashboard) {
          setState(() {
            _selectedMenu = NavMenu.dashboard;
          });
          _checkAppUpdate();
          return;
        }

        // 3. Double-back press confirmation within 2 seconds
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Press back again to exit',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              backgroundColor: PmsTheme.textPrimary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }

        // User pressed back twice within 2 seconds
        SystemNavigator.pop();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
        backgroundColor: PmsTheme.glassSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: PmsTheme.textPrimary),
            tooltip: 'Open Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const AppLogo(size: 34, showShadow: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isDesigner ? 'PMS Designer' : 'PMS Admin',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: PmsTheme.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: PmsTheme.textSecondary,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      PmsStatusChip(label: roleTitle, color: roleColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: PmsTheme.textMuted),
            tooltip: 'Refresh Data',
            onPressed: _refreshCurrentTab,
          ),
          IconButton(
            icon: Badge.count(
              count: _unreadNotificationCount,
              isLabelVisible: _unreadNotificationCount > 0,
              backgroundColor: PmsTheme.error,
              textColor: Colors.white,
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              child: const Icon(Icons.notifications_rounded, color: PmsTheme.textPrimary, size: 24),
            ),
            tooltip: 'Notifications',
            onPressed: () async {
              final newCount = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(
                    userPhone: widget.user.phoneNumber ?? '',
                    isSuperAdmin: isSuperAdmin,
                  ),
                ),
              );
              if (newCount != null && mounted) {
                setState(() => _unreadNotificationCount = newCount);
              } else {
                _fetchUnreadCount();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: PmsTheme.error),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: PmsTheme.background,
        child: SideMenuDrawer(
          selectedMenu: _selectedMenu,
          onMenuSelected: (menu) {
            _onMenuSelected(menu);
            Navigator.pop(context); // Close drawer
          },
          user: widget.user,
          userProfile: _userProfile,
          isSuperAdmin: isSuperAdmin,
          isDesigner: isDesigner,
        ),
      ),
      body: AppGradientBackground(child: _buildBody()),
      ),
    );
  }
}
