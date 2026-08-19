import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/category/category_bloc.dart';
import '../../bloc/category/category_state.dart';
import '../../bloc/product_type/product_type_bloc.dart';
import '../../bloc/product_type/product_type_state.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../bloc/vendor/vendor_bloc.dart';
import '../../bloc/vendor/vendor_state.dart';
import '../../bloc/wing/wing_bloc.dart';
import '../../bloc/wing/wing_state.dart';
import '../layout/side_menu_drawer.dart';

class DashboardTabView extends StatelessWidget {
  final bool isSuperAdmin;
  final String userPhone;
  final Function(NavMenu)? onNavigate;

  const DashboardTabView({
    super.key,
    required this.isSuperAdmin,
    required this.userPhone,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Welcome Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSuperAdmin
                          ? [const Color(0xFF2563EB), const Color(0xFF4F46E5)]
                          : [const Color(0xFF0D9488), const Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      isSuperAdmin
                          ? Icons.admin_panel_settings_rounded
                          : Icons.print_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSuperAdmin ? 'Super Admin Portal' : 'Printing Vendor Portal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Logged in as $userPhone',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF065F46).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF059669)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                      SizedBox(width: 5),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34D399),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // System Overview Title
          const Row(
            children: [
              Icon(Icons.dashboard_customize_rounded, color: Color(0xFF60A5FA), size: 18),
              SizedBox(width: 8),
              Text(
                'Print Management Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Super Admin Master Metrics Grid
          if (isSuperAdmin) ...[
            // Row 1: Categories & Product Types
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, state) {
                      final count =
                          state is CategoryLoaded ? state.categories.length : 0;
                      return _buildStatCard(
                        title: 'Categories',
                        count: '$count',
                        subtitle: 'Education, Hospital...',
                        icon: Icons.category_rounded,
                        color: const Color(0xFF3B82F6),
                        onTap: () {
                          if (onNavigate != null) onNavigate!(NavMenu.categories);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BlocBuilder<ProductTypeBloc, ProductTypeState>(
                    builder: (context, state) {
                      final count =
                          state is ProductTypeLoaded ? state.productTypes.length : 0;
                      return _buildStatCard(
                        title: 'Product Types',
                        count: '$count',
                        subtitle: '111 Total Codes',
                        icon: Icons.layers_rounded,
                        color: const Color(0xFF10B981),
                        onTap: () {
                          if (onNavigate != null) onNavigate!(NavMenu.productTypes);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Wings & Vendors
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<WingBloc, WingState>(
                    builder: (context, state) {
                      final count =
                          state is WingLoaded ? state.wings.length : 0;
                      return _buildStatCard(
                        title: 'Wings Master',
                        count: '$count',
                        subtitle: 'Campuses & Hospital',
                        icon: Icons.apartment_rounded,
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          if (onNavigate != null) onNavigate!(NavMenu.wings);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BlocBuilder<VendorBloc, VendorState>(
                    builder: (context, state) {
                      final count =
                          state is VendorLoaded ? state.vendors.length : 0;
                      return _buildStatCard(
                        title: 'Printing Vendors',
                        count: '$count',
                        subtitle: 'Authorized Presses',
                        icon: Icons.storefront_rounded,
                        color: const Color(0xFFA855F7),
                        onTap: () {
                          if (onNavigate != null) onNavigate!(NavMenu.vendors);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 3: Users
            BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                final count = state is UserLoaded ? state.users.length : 0;
                return _buildStatCard(
                  title: 'System Users & Roles',
                  count: '$count',
                  subtitle: 'Superadmin, Manager, Designer, Studio, Store Incharge',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    if (onNavigate != null) onNavigate!(NavMenu.users);
                  },
                );
              },
            ),
          ],

          if (!isSuperAdmin) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment_outlined,
                          color: Color(0xFF2DD4BF), size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Vendor Job Orders',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Welcome to your vendor dashboard. Assigned Print Orders (PO) and dispatch instructions will appear in this workspace.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: color.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 18),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        count,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: color.withValues(alpha: 0.7)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
