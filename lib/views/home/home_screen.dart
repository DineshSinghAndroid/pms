import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/category/category_bloc.dart';
import '../../bloc/category/category_event.dart';
import '../../bloc/product_type/product_type_bloc.dart';
import '../../bloc/product_type/product_type_event.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_event.dart';
import '../../bloc/vendor/vendor_bloc.dart';
import '../../bloc/vendor/vendor_event.dart';
import '../../bloc/wing/wing_bloc.dart';
import '../../bloc/wing/wing_event.dart';
import '../categories/categories_tab_view.dart';
import '../dashboard/dashboard_tab_view.dart';
import '../layout/side_menu_drawer.dart';
import '../product_types/product_types_tab_view.dart';
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

  bool get isSuperAdmin {
    final phone = widget.user.phoneNumber ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    return cleanPhone.endsWith('7414055310');
  }

  String get _appBarTitle {
    switch (_selectedMenu) {
      case NavMenu.dashboard:
        return 'Dashboard';
      case NavMenu.vendors:
        return 'Vendors';
      case NavMenu.categories:
        return 'Categories';
      case NavMenu.productTypes:
        return 'Product Types';
      case NavMenu.wings:
        return 'Wings Master';
      case NavMenu.users:
        return 'Users & Roles';
      case NavMenu.settings:
        return 'Settings';
    }
  }

  void _onMenuSelected(NavMenu menu) {
    setState(() {
      _selectedMenu = menu;
    });
  }

  void _refreshCurrentTab() {
    if (isSuperAdmin) {
      context.read<CategoryBloc>().add(const RefreshCategoriesEvent());
      context.read<ProductTypeBloc>().add(const RefreshProductTypesEvent());
      context.read<WingBloc>().add(const RefreshWingsEvent());
      context.read<VendorBloc>().add(const RefreshVendorsEvent());
      context.read<UserBloc>().add(const RefreshUsersEvent());
    } else {
      context.read<VendorBloc>().add(const RefreshVendorsEvent());
    }
  }

  Widget _buildBody() {
    switch (_selectedMenu) {
      case NavMenu.dashboard:
        return DashboardTabView(
          isSuperAdmin: isSuperAdmin,
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
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
              );
      case NavMenu.categories:
        return isSuperAdmin
            ? const CategoriesTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
              );
      case NavMenu.productTypes:
        return isSuperAdmin
            ? const ProductTypesTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
              );
      case NavMenu.wings:
        return isSuperAdmin
            ? const WingsTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
              );
      case NavMenu.users:
        return isSuperAdmin
            ? const UsersTabView()
            : DashboardTabView(
                isSuperAdmin: isSuperAdmin,
                userPhone: widget.user.phoneNumber ?? '+91 7414055310',
              );
      case NavMenu.settings:
        return const SettingsTabView();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _appBarTitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF60A5FA),
                ),
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
          isSuperAdmin: isSuperAdmin,
        ),
      ),
      body: _buildBody(),
    );
  }
}
