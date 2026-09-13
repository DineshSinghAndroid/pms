import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
import '../../services/notification_service.dart';
import '../../widgets/app_logo.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationRepository _notificationRepo = NotificationRepository();
  NavMenu _selectedMenu = NavMenu.dashboard;
  UserModel? _userProfile;
  bool _isLoadingProfile = true;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.onNotificationReceived = () {
      if (mounted) _fetchUnreadCount();
    };
    _loadUserProfile();
  }

  @override
  void dispose() {
    NotificationService.instance.onNotificationReceived = null;
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final phone = widget.user.phoneNumber ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    try {
      final repo = context.read<UserRepository>();
      final profile = await repo.getProfile(cleanPhone);
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  bool get isSuperAdmin {
    final r = _userProfile?.role.toLowerCase() ?? '';
    if (r == 'superadmin' || r == 'super admin') {
      return true;
    }
    final phone = widget.user.phoneNumber ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    return cleanPhone.endsWith('7414055310');
  }

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
        context.read<UserBloc>().add(const RefreshUsersEvent());
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
    switch (_selectedMenu) {
      case NavMenu.dashboard:
        return DashboardTabView(
          isSuperAdmin: isSuperAdmin,
          isDesigner: isDesigner,
          userProfile: _userProfile,
          userPhone: widget.user.phoneNumber ?? '+91 7414055310',
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
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
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
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
                onNavigate: (m) => setState(() => _selectedMenu = m),
              );
      case NavMenu.printOrders:
        return (!isDigitalStudioIncharge && !isDigitalStudioEmployee && (isSuperAdmin || isStoreIncharge || isManager || isDesigner || isWingIncharge || _userProfile?.role.toLowerCase() == 'vendor'))
            ? PrintOrdersTabView(
                isSuperAdmin: isSuperAdmin || isStoreIncharge || isManager,
                isDesigner: isDesigner,
                userProfile: _userProfile,
              )
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
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
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
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
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
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
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
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
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
                onNavigate: (m) => setState(() => _selectedMenu = m),
              );
      case NavMenu.newsTracking:
        return (isSuperAdmin || isManager)
            ? NewsTrackingTabView(
                currentUser: _userProfile,
                isSuperAdmin: isSuperAdmin,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
              )
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
                onNavigate: (m) => setState(() => _selectedMenu = m),
              );
      case NavMenu.categories:
        return isSuperAdmin
            ? const CategoriesTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
              );
      case NavMenu.productTypes:
        return isSuperAdmin
            ? const ProductTypesTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
              );
      case NavMenu.wings:
        return isSuperAdmin
            ? const WingsTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
              );
      case NavMenu.users:
        return isSuperAdmin
            ? const UsersTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
              );
      case NavMenu.settings:
        return const SettingsTabView();
      case NavMenu.privacyPolicy:
        return const LegalDocTabView(type: LegalDocType.privacyPolicy);
      case NavMenu.termsAndConditions:
        return const LegalDocTabView(type: LegalDocType.termsAndConditions);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    final String roleTitle;
    final Color roleColor;
    if (isSuperAdmin) {
      roleTitle = 'Super Admin';
      roleColor = const Color(0xFF2563EB);
    } else if (isManager) {
      roleTitle = 'Manager';
      roleColor = const Color(0xFF4F46E5);
    } else if (isDigitalStudioIncharge) {
      roleTitle = 'Digital Studio Incharge';
      roleColor = const Color(0xFF7C3AED);
    } else if (isStoreIncharge) {
      roleTitle = 'Store Incharge';
      roleColor = const Color(0xFF0891B2);
    } else if (isWingIncharge) {
      roleTitle = 'Wing Incharge';
      roleColor = const Color(0xFF0D9488);
    } else if (isDesigner) {
      roleTitle = 'Designer';
      roleColor = const Color(0xFFD97706);
    } else if (isVendor) {
      roleTitle = 'Printing Vendor';
      roleColor = const Color(0xFF059669);
    } else {
      roleTitle = _userProfile?.role ?? 'User';
      roleColor = const Color(0xFF64748B);
    }

    final String displayName = (_userProfile?.name != null &&
            _userProfile!.name.trim().isNotEmpty)
        ? _userProfile!.name.trim()
        : (isSuperAdmin ? 'Super Admin' : roleTitle);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        toolbarHeight: 64,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
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
                      color: Color(0xFF0F172A),
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
                            color: Color(0xFF1E293B),
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.3),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          roleTitle,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                            letterSpacing: 0.2,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Refresh Data',
            onPressed: _refreshCurrentTab,
          ),
          IconButton(
            icon: Badge.count(
              count: _unreadNotificationCount,
              isLabelVisible: _unreadNotificationCount > 0,
              backgroundColor: const Color(0xFFDC2626),
              textColor: Colors.white,
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              child: const Icon(Icons.notifications_outlined, color: Color(0xFF0F172A), size: 24),
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
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFB91C1C)),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Color(0xFFF8FAFC),
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
      body: _buildBody(),
    );
  }
}
