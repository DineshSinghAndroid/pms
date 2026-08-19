import 'package:flutter/material.dart';
import 'vendor_list_section.dart';

class VendorsTabView extends StatelessWidget {
  const VendorsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: VendorListSection(),
    );
  }
}
