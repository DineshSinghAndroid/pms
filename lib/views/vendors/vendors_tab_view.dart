import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/vendor/vendor_bloc.dart';
import '../../bloc/vendor/vendor_event.dart';
import '../../bloc/vendor/vendor_state.dart';
import 'vendor_list_section.dart';
import '../../theme/pms_theme.dart';

class VendorsTabView extends StatefulWidget {
  const VendorsTabView({super.key});

  @override
  State<VendorsTabView> createState() => _VendorsTabViewState();
}

class _VendorsTabViewState extends State<VendorsTabView> {
  @override
  void initState() {
    super.initState();
    // Load vendors when this tab opens (home prefetch was previously missing)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<VendorBloc>().state;
      if (state is! VendorLoaded && state is! VendorLoading) {
        context.read<VendorBloc>().add(const FetchVendorsEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: PmsTheme.primary,
      onRefresh: () async {
        context.read<VendorBloc>().add(const RefreshVendorsEvent());
        await context.read<VendorBloc>().stream.firstWhere(
              (state) => state is VendorLoaded || state is VendorError,
            );
      },
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: VendorListSection(),
      ),
    );
  }
}
