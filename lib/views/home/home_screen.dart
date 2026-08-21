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
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';
import '../categories/categories_tab_view.dart';
import '../dashboard/dashboard_tab_view.dart';
import '../delivery_logs/delivery_logs_tab_view.dart';
import '../layout/side_menu_drawer.dart';
import '../post_orders/post_orders_tab_view.dart';
import '../print_orders/print_orders_tab_view.dart';
import '../product_types/product_types_tab_view.dart';
import '../purchase_requests/purchase_requests_tab_view.dart';
import '../settings/settings_tab_view.dart';
import '../users/users_tab_view.dart';
import '../vendors/vendors_tab_view.dart';
import '../wings/wings_tab_view.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NavMenu _selectedMenu = NavMenu.dashboard;
  UserModel? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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

        // Trigger appropriate PR fetch depending on role
        if (isDesigner && _userProfile != null) {
          context.read<PurchaseRequestBloc>().add(
                FetchPurchaseRequestsEvent(
                  designerId: _userProfile!.id,
                  phone: cleanPhone,
                ),
              );
        } else if (isSuperAdmin) {
          context.read<PurchaseRequestBloc>().add(const FetchPurchaseRequestsEvent());
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
    if (_userProfile?.role.toLowerCase() == 'superadmin' ||
        _userProfile?.role == 'Super Admin') {
      return true;
    }
    final phone = widget.user.phoneNumber ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    return cleanPhone.endsWith('7414055310');
  }

  bool get isDesigner {
    return _userProfile?.role == 'Designer';
  }

  bool get isVendor {
    return _userProfile?.role.toLowerCase() == 'vendor';
  }

  void _onMenuSelected(NavMenu menu) {
    setState(() {
      _selectedMenu = menu;
    });
  }

  void _refreshCurrentTab() {
    final phone = widget.user.phoneNumber ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    if (isSuperAdmin) {
      context.read<PurchaseRequestBloc>().add(const FetchPurchaseRequestsEvent());
      context.read<CategoryBloc>().add(const RefreshCategoriesEvent());
      context.read<ProductTypeBloc>().add(const RefreshProductTypesEvent());
      context.read<WingBloc>().add(const RefreshWingsEvent());
      context.read<VendorBloc>().add(const RefreshVendorsEvent());
      context.read<UserBloc>().add(const RefreshUsersEvent());
      context.read<PrintOrderBloc>().add(FetchPrintOrders(phone: cleanPhone));
      context.read<PrintOrderBloc>().add(const FetchDeliveryLogsEvent());
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
        return isSuperAdmin
            ? const VendorsTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
              );
      case NavMenu.purchaseRequests:
        return PurchaseRequestsTabView(
          isSuperAdmin: isSuperAdmin,
          currentUser: _userProfile,
        );
      case NavMenu.printOrders:
        return PrintOrdersTabView(
          isSuperAdmin: isSuperAdmin,
          isDesigner: isDesigner,
          userProfile: _userProfile,
        );
      case NavMenu.deliveryLogs:
        return isSuperAdmin
            ? DeliveryLogsTabView(
                userProfile: _userProfile,
                isSuperAdmin: isSuperAdmin,
              )
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                isDesigner: isDesigner,
                userProfile: _userProfile,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
              );
      case NavMenu.postOrders:
        return PostOrdersTabView(
          isSuperAdmin: isSuperAdmin,
          isDesigner: isDesigner,
          currentUser: _userProfile,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            tooltip: 'Open Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const Text(
              'PMS Admin',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),

          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
            tooltip: 'Refresh Data',
            onPressed: _refreshCurrentTab,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFDA4AF)),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
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
