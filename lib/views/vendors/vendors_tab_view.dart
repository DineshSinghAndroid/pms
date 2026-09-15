import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/vendor/vendor_bloc.dart';
import '../../bloc/vendor/vendor_event.dart';
import '../../bloc/vendor/vendor_state.dart';
import 'vendor_list_section.dart';

class VendorsTabView extends StatelessWidget {
  const VendorsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF2563EB),
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

