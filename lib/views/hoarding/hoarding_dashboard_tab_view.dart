import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../bloc/hoarding/hoarding_bloc.dart';
import '../../bloc/hoarding/hoarding_event.dart';
import '../../bloc/hoarding/hoarding_state.dart';
import '../../models/hoarding_city_model.dart';
import '../../models/hoarding_vendor_model.dart';
import '../../models/hoarding_site_model.dart';
import '../../models/hoarding_site_log_model.dart';
import '../../models/user_model.dart';
import '../../theme/pms_theme.dart';
import 'hoarding_map_picker_dialog.dart';

class HoardingDashboardTabView extends StatefulWidget {
  final UserModel? currentUser;

  const HoardingDashboardTabView({super.key, this.currentUser});

  @override
  State<HoardingDashboardTabView> createState() => _HoardingDashboardTabViewState();
}

class _HoardingDashboardTabViewState extends State<HoardingDashboardTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Map Filter State
  int? _mapFilterCityId;
  int? _mapFilterVendorId;
  String? _mapFilterType;
  String? _mapFilterStatus;
  bool _isMapFullscreen = false;
  GoogleMapController? _dashboardMapController;
  HoardingSiteModel? _selectedMapSite;

  bool get isHoardingVendor => widget.currentUser?.isHoardingVendor ?? false;
  bool get canManage => (widget.currentUser?.isSuperAdmin ?? false) || (widget.currentUser?.isManager ?? false);

  @override
  void initState() {
    super.initState();
    final tabCount = canManage ? 3 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
    context.read<HoardingBloc>().add(const FetchHoardingDataEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<HoardingSiteModel> _getFilteredMapSites(List<HoardingSiteModel> allSites) {
    return allSites.where((s) {
      if (_mapFilterCityId != null && s.cityId != _mapFilterCityId) return false;
      if (_mapFilterVendorId != null && s.vendorId != _mapFilterVendorId) return false;
      if (_mapFilterType != null && s.type.toLowerCase() != _mapFilterType!.toLowerCase()) return false;
      if (_mapFilterStatus != null && s.status.toLowerCase() != _mapFilterStatus!.toLowerCase()) return false;
      return true;
    }).toList();
  }

  Set<Marker> _createMarkers(List<HoardingSiteModel> sites) {
    final markers = <Marker>{};
    for (final site in sites) {
      if (site.latitude != null && site.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('site_${site.id}'),
            position: LatLng(site.latitude!, site.longitude!),
            infoWindow: InfoWindow(
              title: site.name,
              snippet: '${site.siteCode} · ${site.type} · ₹${site.monthlyRent.toInt()}/mo',
              onTap: () => _showSiteDetailsSheet(context, site),
            ),
            icon: site.status == 'Active'
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            onTap: () {
              setState(() {
                _selectedMapSite = site;
              });
              _dashboardMapController?.showMarkerInfoWindow(MarkerId('site_${site.id}'));
            },
          ),
        );
      }
    }
    return markers;
  }

  void _fitMapToBounds(List<HoardingSiteModel> sites) {
    if (_dashboardMapController == null || sites.isEmpty) return;
    final validSites = sites.where((s) => s.latitude != null && s.longitude != null).toList();
    if (validSites.isEmpty) return;
    if (validSites.length == 1) {
      _dashboardMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(validSites.first.latitude!, validSites.first.longitude!),
          14,
        ),
      );
    } else {
      double minLat = validSites.first.latitude!;
      double maxLat = validSites.first.latitude!;
      double minLng = validSites.first.longitude!;
      double maxLng = validSites.first.longitude!;
      for (final s in validSites) {
        if (s.latitude! < minLat) minLat = s.latitude!;
        if (s.latitude! > maxLat) maxLat = s.latitude!;
        if (s.longitude! < minLng) minLng = s.longitude!;
        if (s.longitude! > maxLng) maxLng = s.longitude!;
      }
      _dashboardMapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          48,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HoardingBloc, HoardingState>(
      listener: (context, state) {
        if (state is HoardingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: _isMapFullscreen
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: PmsTheme.primary,
                      labelColor: PmsTheme.primary,
                      unselectedLabelColor: Colors.blueGrey.shade500,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: [
                        const Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'Map & Stats'),
                        const Tab(icon: Icon(Icons.view_carousel_rounded, size: 18), text: 'Sites'),
                        if (canManage)
                          const Tab(icon: Icon(Icons.location_city_rounded, size: 18), text: 'Cities & Vendors'),
                      ],
                    ),
                  ),
                ),
          floatingActionButton: (_isMapFullscreen || !canManage)
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _openSiteForm(context),
                  backgroundColor: PmsTheme.primary,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text('Add Site', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
          body: state is HoardingLoading
              ? const Center(child: CircularProgressIndicator())
              : state is HoardingLoaded
                  ? _isMapFullscreen
                      ? _buildFullscreenMap(context, state)
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMapAndStatsTab(context, state),
                            _buildSitesTab(context, state),
                            if (canManage) _buildCitiesAndVendorsTab(context, state),
                          ],
                        )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.blueGrey),
                          const SizedBox(height: 12),
                          const Text('Failed to load hoarding data'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.read<HoardingBloc>().add(const RefreshHoardingDataEvent()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  TAB 1: MAP & STATS (BOXED & INTERACTIVE WITH FILTERS)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildMapAndStatsTab(BuildContext context, HoardingLoaded state) {
    final filteredSites = _getFilteredMapSites(state.sites);
    final markers = _createMarkers(filteredSites);

    final initialTarget = markers.isNotEmpty
        ? markers.first.position
        : const LatLng(27.6094, 75.1398);

    return RefreshIndicator(
      onRefresh: () async => context.read<HoardingBloc>().add(const RefreshHoardingDataEvent()),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                _buildStatTile('Total Sites', '${state.totalSites}', Colors.indigo),
                _buildStatTile('Active', '${state.activeSites}', Colors.green),
                _buildStatTile('Maintenance', '${state.maintenanceSites}', Colors.orange),
                _buildStatTile('Monthly Rent', currencyFormat.format(state.totalMonthlyRent), Colors.blue),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filters Bar
          _buildFilterBar(context, state, filteredSites),

          // Boxed Map Card
          Container(
            height: 330,
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.blueGrey.shade100, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialTarget,
                      zoom: markers.isNotEmpty ? 11 : 6,
                    ),
                    onMapCreated: (ctrl) {
                      _dashboardMapController = ctrl;
                      _fitMapToBounds(filteredSites);
                    },
                    markers: markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),

                  // Top Overlay Bar inside Boxed Map
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Pin Legend + Count badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                              const SizedBox(width: 3),
                              const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                              const SizedBox(width: 3),
                              const Text('Maint', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('· ${filteredSites.length} sites', style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),

                        // Full Screen Toggle Button
                        Material(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _isMapFullscreen = true;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fullscreen_rounded, size: 16, color: Colors.indigo),
                                  SizedBox(width: 3),
                                  Text(
                                    'Full Screen',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Selected Site Preview inside Boxed Map
                  if (_selectedMapSite != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: _buildSelectedSiteMiniCard(_selectedMapSite!),
                    ),
                ],
              ),
            ),
          ),

          // "Sites on Map" Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sites on Map (${filteredSites.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Tap to locate on map',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500),
                ),
              ],
            ),
          ),

          // Sites list matching map pins
          if (filteredSites.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.location_off_rounded, size: 40, color: Colors.blueGrey.shade300),
                  const SizedBox(height: 8),
                  Text('No sites match the selected filters', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _mapFilterCityId = null;
                        _mapFilterVendorId = null;
                        _mapFilterType = null;
                        _mapFilterStatus = null;
                        _selectedMapSite = null;
                      });
                      _fitMapToBounds(state.sites);
                    },
                    child: const Text('Reset Filters'),
                  ),
                ],
              ),
            )
          else
            ...filteredSites.map((site) => _buildMapSiteListTile(site)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  FULLSCREEN MAP VIEW
  // ─────────────────────────────────────────────────────────────────
  Widget _buildFullscreenMap(BuildContext context, HoardingLoaded state) {
    final filteredSites = _getFilteredMapSites(state.sites);
    final markers = _createMarkers(filteredSites);

    final initialTarget = markers.isNotEmpty
        ? markers.first.position
        : const LatLng(27.6094, 75.1398);

    return SafeArea(
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: markers.isNotEmpty ? 11 : 6,
            ),
            onMapCreated: (ctrl) {
              _dashboardMapController = ctrl;
              _fitMapToBounds(filteredSites);
            },
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Floating Top App-Bar for Fullscreen
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _isMapFullscreen = false;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.fullscreen_exit_rounded, size: 22, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Map Dashboard (Fullscreen)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Showing ${filteredSites.length} of ${state.sites.length} sites',
                          style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade600),
                        ),
                      ],
                    ),
                  ),
                  // Filter trigger button
                  Material(
                    color: (_mapFilterCityId != null || _mapFilterVendorId != null || _mapFilterType != null || _mapFilterStatus != null)
                        ? Colors.amber.shade100
                        : Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _openFilterModal(context, state),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: (_mapFilterCityId != null || _mapFilterVendorId != null || _mapFilterType != null || _mapFilterStatus != null)
                                  ? Colors.amber.shade900
                                  : Colors.black87,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Filter',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: (_mapFilterCityId != null || _mapFilterVendorId != null || _mapFilterType != null || _mapFilterStatus != null)
                                    ? Colors.amber.shade900
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Selected Site Preview inside Fullscreen
          if (_selectedMapSite != null)
            Positioned(
              bottom: 16,
              left: 14,
              right: 14,
              child: _buildSelectedSiteMiniCard(_selectedMapSite!),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  MAP FILTER BAR & DIALOGS
  // ─────────────────────────────────────────────────────────────────
  Widget _buildFilterBar(BuildContext context, HoardingLoaded state, List<HoardingSiteModel> filteredSites) {
    final hasActiveFilter = _mapFilterCityId != null ||
        _mapFilterVendorId != null ||
        _mapFilterType != null ||
        _mapFilterStatus != null;

    final selectedCity = _mapFilterCityId != null
        ? state.cities.cast<HoardingCityModel?>().firstWhere((c) => c?.id == _mapFilterCityId, orElse: () => null)
        : null;

    final selectedVendor = _mapFilterVendorId != null
        ? state.vendors.cast<HoardingVendorModel?>().firstWhere((v) => v?.id == _mapFilterVendorId, orElse: () => null)
        : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Row(
              children: [
                Icon(Icons.filter_list_rounded, size: 16, color: Colors.blueGrey.shade600),
                const SizedBox(width: 4),
                Text('Filters:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
                const SizedBox(width: 8),
              ],
            ),

            // City Filter Chip
            ActionChip(
              avatar: const Icon(Icons.location_city_rounded, size: 14),
              label: Text(selectedCity?.name ?? 'City: All'),
              backgroundColor: _mapFilterCityId != null ? Colors.amber.shade100 : Colors.blueGrey.shade50,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: _mapFilterCityId != null ? FontWeight.bold : FontWeight.normal,
                color: _mapFilterCityId != null ? Colors.amber.shade900 : Colors.blueGrey.shade800,
              ),
              onPressed: () => _openCityFilterSheet(context, state),
            ),
            const SizedBox(width: 6),

            // Vendor Filter Chip
            ActionChip(
              avatar: const Icon(Icons.business_rounded, size: 14),
              label: Text(selectedVendor?.name ?? 'Vendor: All'),
              backgroundColor: _mapFilterVendorId != null ? Colors.amber.shade100 : Colors.blueGrey.shade50,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: _mapFilterVendorId != null ? FontWeight.bold : FontWeight.normal,
                color: _mapFilterVendorId != null ? Colors.amber.shade900 : Colors.blueGrey.shade800,
              ),
              onPressed: () => _openVendorFilterSheet(context, state),
            ),
            const SizedBox(width: 6),

            // Type Filter Chip
            ActionChip(
              avatar: const Icon(Icons.category_rounded, size: 14),
              label: Text(_mapFilterType != null ? 'Type: $_mapFilterType' : 'Type: All'),
              backgroundColor: _mapFilterType != null ? Colors.amber.shade100 : Colors.blueGrey.shade50,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: _mapFilterType != null ? FontWeight.bold : FontWeight.normal,
                color: _mapFilterType != null ? Colors.amber.shade900 : Colors.blueGrey.shade800,
              ),
              onPressed: () => _openTypeFilterSheet(context),
            ),
            const SizedBox(width: 6),

            // Status Filter Chip
            ActionChip(
              avatar: const Icon(Icons.info_outline_rounded, size: 14),
              label: Text(_mapFilterStatus != null ? 'Status: $_mapFilterStatus' : 'Status: All'),
              backgroundColor: _mapFilterStatus != null ? Colors.amber.shade100 : Colors.blueGrey.shade50,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: _mapFilterStatus != null ? FontWeight.bold : FontWeight.normal,
                color: _mapFilterStatus != null ? Colors.amber.shade900 : Colors.blueGrey.shade800,
              ),
              onPressed: () => _openStatusFilterSheet(context),
            ),

            // Reset Clear Filter
            if (hasActiveFilter) ...[
              const SizedBox(width: 6),
              ActionChip(
                avatar: const Icon(Icons.close_rounded, size: 14, color: Colors.red),
                label: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.red.shade50,
                onPressed: () {
                  setState(() {
                    _mapFilterCityId = null;
                    _mapFilterVendorId = null;
                    _mapFilterType = null;
                    _mapFilterStatus = null;
                    _selectedMapSite = null;
                  });
                  _fitMapToBounds(state.sites);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openCityFilterSheet(BuildContext context, HoardingLoaded state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Filter by City', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)),
            ),
            const Divider(height: 1),
            RadioListTile<int?>(
              title: const Text('All Cities'),
              value: null,
              groupValue: _mapFilterCityId,
              onChanged: (v) {
                Navigator.pop(ctx);
                setState(() => _mapFilterCityId = v);
                _fitMapToBounds(_getFilteredMapSites(state.sites));
              },
            ),
            ...state.cities.map(
              (c) => RadioListTile<int?>(
                title: Text(c.name),
                subtitle: c.state != null ? Text(c.state!, style: const TextStyle(fontSize: 11)) : null,
                value: c.id,
                groupValue: _mapFilterCityId,
                onChanged: (v) {
                  Navigator.pop(ctx);
                  setState(() => _mapFilterCityId = v);
                  _fitMapToBounds(_getFilteredMapSites(state.sites));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVendorFilterSheet(BuildContext context, HoardingLoaded state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Filter by Vendor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)),
            ),
            const Divider(height: 1),
            RadioListTile<int?>(
              title: const Text('All Vendors'),
              value: null,
              groupValue: _mapFilterVendorId,
              onChanged: (v) {
                Navigator.pop(ctx);
                setState(() => _mapFilterVendorId = v);
                _fitMapToBounds(_getFilteredMapSites(state.sites));
              },
            ),
            ...state.vendors.map(
              (ven) => RadioListTile<int?>(
                title: Text(ven.name),
                subtitle: ven.phone != null ? Text(ven.phone!, style: const TextStyle(fontSize: 11)) : null,
                value: ven.id,
                groupValue: _mapFilterVendorId,
                onChanged: (v) {
                  Navigator.pop(ctx);
                  setState(() => _mapFilterVendorId = v);
                  _fitMapToBounds(_getFilteredMapSites(state.sites));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTypeFilterSheet(BuildContext context) {
    final types = ['Hoarding', 'Unipole', 'Flex'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Filter by Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)),
            ),
            const Divider(height: 1),
            RadioListTile<String?>(
              title: const Text('All Types'),
              value: null,
              groupValue: _mapFilterType,
              onChanged: (v) {
                Navigator.pop(ctx);
                setState(() => _mapFilterType = v);
              },
            ),
            ...types.map(
              (t) => RadioListTile<String?>(
                title: Text(t),
                value: t,
                groupValue: _mapFilterType,
                onChanged: (v) {
                  Navigator.pop(ctx);
                  setState(() => _mapFilterType = v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStatusFilterSheet(BuildContext context) {
    final statuses = ['Active', 'Maintenance'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Filter by Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)),
            ),
            const Divider(height: 1),
            RadioListTile<String?>(
              title: const Text('All Statuses'),
              value: null,
              groupValue: _mapFilterStatus,
              onChanged: (v) {
                Navigator.pop(ctx);
                setState(() => _mapFilterStatus = v);
              },
            ),
            ...statuses.map(
              (s) => RadioListTile<String?>(
                title: Text(s),
                value: s,
                groupValue: _mapFilterStatus,
                onChanged: (v) {
                  Navigator.pop(ctx);
                  setState(() => _mapFilterStatus = v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterModal(BuildContext context, HoardingLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Map Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setLocalState(() {
                        _mapFilterCityId = null;
                        _mapFilterVendorId = null;
                        _mapFilterType = null;
                        _mapFilterStatus = null;
                      });
                      setState(() {});
                      _fitMapToBounds(state.sites);
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // City
              DropdownButtonFormField<int?>(
                initialValue: _mapFilterCityId,
                decoration: const InputDecoration(labelText: 'City', isDense: true),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Cities')),
                  ...state.cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) {
                  setLocalState(() => _mapFilterCityId = v);
                  setState(() {});
                  _fitMapToBounds(_getFilteredMapSites(state.sites));
                },
              ),
              const SizedBox(height: 12),
              // Vendor
              DropdownButtonFormField<int?>(
                initialValue: _mapFilterVendorId,
                decoration: const InputDecoration(labelText: 'Vendor', isDense: true),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Vendors')),
                  ...state.vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))),
                ],
                onChanged: (v) {
                  setLocalState(() => _mapFilterVendorId = v);
                  setState(() {});
                  _fitMapToBounds(_getFilteredMapSites(state.sites));
                },
              ),
              const SizedBox(height: 12),
              // Type & Status
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _mapFilterType,
                      decoration: const InputDecoration(labelText: 'Type', isDense: true),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Types')),
                        ...['Hoarding', 'Unipole', 'Flex'].map((t) => DropdownMenuItem(value: t, child: Text(t))),
                      ],
                      onChanged: (v) {
                        setLocalState(() => _mapFilterType = v);
                        setState(() {});
                        _fitMapToBounds(_getFilteredMapSites(state.sites));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _mapFilterStatus,
                      decoration: const InputDecoration(labelText: 'Status', isDense: true),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Statuses')),
                        ...['Active', 'Maintenance'].map((s) => DropdownMenuItem(value: s, child: Text(s))),
                      ],
                      onChanged: (v) {
                        setLocalState(() => _mapFilterStatus = v);
                        setState(() {});
                        _fitMapToBounds(_getFilteredMapSites(state.sites));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: PmsTheme.primary, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedSiteMiniCard(HoardingSiteModel site) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showSiteDetailsSheet(context, site),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: site.photoUrl != null
                      ? Image.network(
                          site.photoUrl!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 52,
                            height: 52,
                            color: Colors.blueGrey.shade100,
                            child: const Icon(Icons.broken_image_rounded, size: 20, color: Colors.blueGrey),
                          ),
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          color: Colors.blueGrey.shade100,
                          child: const Icon(Icons.image_not_supported_rounded, size: 20, color: Colors.blueGrey),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            site.siteCode,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: site.status == 'Active' ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              site.status,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: site.status == 'Active' ? Colors.green.shade800 : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        site.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${site.city?.name ?? '—'} · ₹${site.monthlyRent.toInt()}/mo',
                        style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.indigo),
                  onPressed: () => _showSiteDetailsSheet(context, site),
                  tooltip: 'View Details',
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.blueGrey),
                  onPressed: () {
                    setState(() {
                      _selectedMapSite = null;
                    });
                  },
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapSiteListTile(HoardingSiteModel site) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: site.photoUrl != null
              ? Image.network(
                  site.photoUrl!,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(width: 46, height: 46, color: Colors.blueGrey.shade100, child: const Icon(Icons.broken_image_rounded, size: 18, color: Colors.blueGrey)),
                )
              : Container(width: 46, height: 46, color: Colors.blueGrey.shade100, child: const Icon(Icons.image_not_supported_rounded, size: 18, color: Colors.blueGrey)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                site.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: site.status == 'Active' ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                site.status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: site.status == 'Active' ? Colors.green.shade800 : Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${site.siteCode} · ${site.type} (${site.side}) · ${site.city?.name ?? '—'}',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              'Rent: ${currencyFormat.format(site.monthlyRent)}/mo',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.blueGrey),
        onTap: () {
          if (site.latitude != null && site.longitude != null) {
            _dashboardMapController?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(site.latitude!, site.longitude!), 15),
            );
            setState(() {
              _selectedMapSite = site;
            });
          } else {
            _showSiteDetailsSheet(context, site);
          }
        },
      ),
    );
  }

  Widget _buildStatTile(String label, String value, MaterialColor color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.shade200),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: color.shade900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  TAB 2: SITES LIST
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSitesTab(BuildContext context, HoardingLoaded state) {
    final query = _searchController.text.trim().toLowerCase();
    final sites = state.sites.where((s) {
      if (query.isEmpty) return true;
      return s.name.toLowerCase().contains(query) ||
          s.siteCode.toLowerCase().contains(query) ||
          (s.city?.name.toLowerCase().contains(query) ?? false) ||
          (s.vendor?.name.toLowerCase().contains(query) ?? false);
    }).toList();

    return Column(
      children: [
        // Search & Filter
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search site code, name, city...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => context.read<HoardingBloc>().add(const RefreshHoardingDataEvent()),
            child: sites.isEmpty
                ? const Center(
                    child: Text('No hoarding sites found', style: TextStyle(color: Colors.blueGrey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: sites.length,
                    itemBuilder: (context, i) {
                      final site = sites[i];
                      return _buildSiteCard(context, site);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSiteCard(BuildContext context, HoardingSiteModel site) {
    final isActive = site.status == 'Active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showSiteDetailsSheet(context, site),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: site.photoUrl != null && site.photoUrl!.isNotEmpty
                        ? Image.network(
                            site.photoUrl!,
                            width: 70,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, obj, stack) => _photoPlaceholder(),
                          )
                        : _photoPlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              site.siteCode,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isActive ? Colors.green.shade300 : Colors.orange.shade300,
                                ),
                              ),
                              child: Text(
                                site.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.green.shade800 : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          site.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 12, color: Colors.blueGrey.shade500),
                            const SizedBox(width: 2),
                            Text(
                              site.city?.name ?? 'No city',
                              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.storefront_rounded, size: 12, color: Colors.blueGrey.shade500),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                site.vendor?.name ?? 'No vendor',
                                style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
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
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${site.type} · ${site.side}${site.width != null ? ' · ${site.width}×${site.height} ft' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
                  ),
                  Text(
                    '${currencyFormat.format(site.monthlyRent)}/mo',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: PmsTheme.primary),
                  ),
                ],
              ),
              if (canManage) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => _openSiteForm(context, site: site),
                      icon: const Icon(Icons.edit_rounded, size: 14),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () => _confirmDeleteSite(context, site),
                      icon: const Icon(Icons.delete_outline_rounded, size: 14),
                      label: const Text('Delete', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 70,
      height: 60,
      color: Colors.blueGrey.shade100,
      child: Icon(Icons.image_outlined, size: 28, color: Colors.blueGrey.shade400),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  TAB 3: CITIES & VENDORS
  // ─────────────────────────────────────────────────────────────────
  Widget _buildCitiesAndVendorsTab(BuildContext context, HoardingLoaded state) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.blueGrey.shade100,
            child: const TabBar(
              labelColor: PmsTheme.primary,
              unselectedLabelColor: Colors.blueGrey,
              indicatorColor: PmsTheme.primary,
              tabs: [
                Tab(text: 'Cities'),
                Tab(text: 'Hoarding Vendors'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCitiesSubTab(context, state),
                _buildVendorsSubTab(context, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitiesSubTab(BuildContext context, HoardingLoaded state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${state.cities.length} Cities', style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _openCityForm(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add City', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: PmsTheme.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: state.cities.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final city = state.cities[i];
              return Card(
                child: ListTile(
                  title: Text(city.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(city.state ?? 'No state specified'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        onPressed: () => _openCityForm(context, city: city),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        onPressed: () => _confirmDeleteCity(context, city),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVendorsSubTab(BuildContext context, HoardingLoaded state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${state.vendors.length} Vendors', style: const TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _openVendorForm(context, state.cities),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Vendor', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: PmsTheme.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: state.vendors.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final v = state.vendors[i];
              final cityNames = state.cities
                  .where((c) => v.operatingCityIds.contains(c.id))
                  .map((c) => c.name)
                  .join(', ');

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                onPressed: () => _openVendorForm(context, state.cities, vendor: v),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                onPressed: () => _confirmDeleteVendor(context, v),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (v.phone != null && v.phone!.isNotEmpty)
                        Text('Phone: ${v.phone}', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
                      if (cityNames.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Cities: $cityNames', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600)),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  SITE DETAIL BOTTOM SHEET WITH LOGS
  // ─────────────────────────────────────────────────────────────────
  void _showSiteDetailsSheet(BuildContext context, HoardingSiteModel site) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return FutureBuilder<List<HoardingSiteLogModel>>(
              future: context.read<HoardingBloc>().repository.getSiteLogs(site.id),
              builder: (context, snapshot) {
                final logs = snapshot.data ?? [];

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(18),
                  children: [
                    Center(
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.blueGrey.shade300, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 14),

                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(site.siteCode, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.blueGrey.shade600)),
                              const SizedBox(height: 2),
                              Text(site.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: site.status == 'Active' ? Colors.green.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: site.status == 'Active' ? Colors.green.shade300 : Colors.orange.shade300),
                          ),
                          child: Text(
                            site.status,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: site.status == 'Active' ? Colors.green.shade800 : Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Photo if exists
                    if (site.photoUrl != null && site.photoUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          site.photoUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, obj, stack) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Info Grid
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          _buildDetailRow('Type', site.type),
                          _buildDetailRow('Side', site.side),
                          _buildDetailRow('Dimensions', '${site.width ?? '?'} × ${site.height ?? '?'} ft'),
                          _buildDetailRow('Monthly Rent', currencyFormat.format(site.monthlyRent)),
                          _buildDetailRow('City', site.city?.name ?? '—'),
                          _buildDetailRow('Vendor', site.vendor?.name ?? '—'),
                          if (site.latitude != null && site.longitude != null)
                            _buildDetailRow('Coordinates', '${site.latitude!.toStringAsFixed(5)}, ${site.longitude!.toStringAsFixed(5)}'),
                        ],
                      ),
                    ),
                    if (site.remarks != null && site.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Remarks: ${site.remarks}', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600, fontStyle: FontStyle.italic)),
                    ],

                    const SizedBox(height: 20),
                    const Text('Activity Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),

                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                    else if (logs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('No activity logs recorded yet.', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      )
                    else
                      ...logs.map((log) => _buildLogItem(log)),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  Widget _buildLogItem(HoardingSiteLogModel log) {
    final String dateStr;
    if (log.createdAtIst != null && log.createdAtIst!.trim().isNotEmpty) {
      dateStr = log.createdAtIst!.contains('IST') ? log.createdAtIst! : '${log.createdAtIst!} IST';
    } else if (log.createdAt != null) {
      dateStr = '${DateFormat('dd MMM yyyy, hh:mm a').format(log.createdAt!.toLocal())} IST';
    } else {
      dateStr = 'Recently';
    }

    final isCreated = log.event == 'created';
    final isPhoto = log.event == 'photo_changed';

    final Color themeColor = isCreated
        ? PmsTheme.success
        : (isPhoto ? Colors.purple : PmsTheme.primary);

    final Color bgTint = isCreated
        ? const Color(0xFFECFDF5)
        : (isPhoto ? Colors.purple.shade50 : const Color(0xFFF1F5F9));

    final Color borderColor = isCreated
        ? const Color(0xFFA7F3D0)
        : (isPhoto ? Colors.purple.shade200 : const Color(0xFFE2E8F0));

    final oldData = log.oldData ?? {};
    final newData = log.newData ?? {};
    final allKeys = {...oldData.keys, ...newData.keys}.toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event badge + Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bgTint,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  log.event.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: themeColor,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 12, color: Colors.blueGrey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Done by Whom Row
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: themeColor.withValues(alpha: 0.15),
                child: Text(
                  (log.userName != null && log.userName!.isNotEmpty)
                      ? log.userName![0].toUpperCase()
                      : 'U',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeColor),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    children: [
                      const TextSpan(text: 'By: ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal)),
                      TextSpan(
                        text: log.userName ?? 'System',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (log.userRole != null && log.userRole!.isNotEmpty) ...[
                        const TextSpan(text: ' '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              log.userRole!,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (log.description != null && log.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              log.description!,
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800),
            ),
          ],

          // Detailed Diff / Initial values
          if (isCreated && newData.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INITIAL VALUES',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: newData.entries.map((entry) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${entry.key}: ', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          Text('${entry.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ] else if (allKeys.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHANGES DETAIL',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 6),
                  ...allKeys.map((key) {
                    final fromVal = oldData[key]?.toString() ?? '—';
                    final toVal = newData[key]?.toString() ?? '—';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 85,
                            child: Text(
                              key,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Text(
                                      fromVal,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red.shade700,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.blueGrey),
                                ),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: Text(
                                      toVal,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF065F46),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  ADD / EDIT SITE MODAL
  // ─────────────────────────────────────────────────────────────────
  void _openSiteForm(BuildContext context, {HoardingSiteModel? site}) {
    final state = context.read<HoardingBloc>().state;
    if (state is! HoardingLoaded) return;

    final nameCtrl = TextEditingController(text: site?.name ?? '');
    final widthCtrl = TextEditingController(text: site?.width?.toString() ?? '');
    final heightCtrl = TextEditingController(text: site?.height?.toString() ?? '');
    final rentCtrl = TextEditingController(text: site?.monthlyRent.toString() ?? '');
    final remarksCtrl = TextEditingController(text: site?.remarks ?? '');

    int? selectedCityId = site?.cityId ?? (state.cities.isNotEmpty ? state.cities.first.id : null);
    int? selectedVendorId = site?.hoardingVendorId ?? (state.vendors.isNotEmpty ? state.vendors.first.id : null);
    String selectedType = site?.type ?? 'Hoarding';
    String selectedSide = site?.side ?? 'Single Side';
    String selectedStatus = site?.status ?? 'Active';
    double? selectedLat = site?.latitude;
    double? selectedLng = site?.longitude;
    String? pickedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site != null ? 'Edit Hoarding Site' : 'Add New Hoarding Site',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Site Name *', isDense: true),
                    ),
                    const SizedBox(height: 10),

                    // City & Vendor Dropdowns
                    Column(
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: selectedCityId,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'City *', isDense: true),
                          items: state.cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (v) => setModalState(() => selectedCityId = v),
                        ),
                        const SizedBox(width: 10),
                        DropdownButtonFormField<int>(
                          initialValue: selectedVendorId,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'Vendor *', isDense: true),
                          items: state.vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList(),
                          onChanged: (v) => setModalState(() => selectedVendorId = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Type & Side
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            isDense: true,
                            decoration: const InputDecoration(labelText: 'Type *', isDense: true),
                            items: ['Unipole', 'Hoarding', 'Flex'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) => setModalState(() => selectedType = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedSide,
                            isDense: true,
                            decoration: const InputDecoration(labelText: 'Side *', isDense: true),
                            items: ['Single Side', 'Double Side'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setModalState(() => selectedSide = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Dimensions & Rent
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widthCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Width (ft)', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: heightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Height (ft)', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: rentCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Rent (₹) *', isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Status
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      isDense: true,
                      decoration: const InputDecoration(labelText: 'Status', isDense: true),
                      items: ['Active', 'Maintenance'].map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                      onChanged: (v) => setModalState(() => selectedStatus = v!),
                    ),
                    const SizedBox(height: 14),

                    // Map Location Picker Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final LatLng? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HoardingMapPickerDialog(
                              initialLat: selectedLat,
                              initialLng: selectedLng,
                            ),
                          ),
                        );
                        if (result != null) {
                          setModalState(() {
                            selectedLat = result.latitude;
                            selectedLng = result.longitude;
                          });
                        }
                      },
                      icon: const Icon(Icons.map_rounded, color: PmsTheme.primary),
                      label: Text(
                        selectedLat != null
                            ? 'Location: ${selectedLat!.toStringAsFixed(5)}, ${selectedLng!.toStringAsFixed(5)} (Tap to Change)'
                            : '📍 Pick Location on Map',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Photo Picker
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (image != null) {
                          setModalState(() {
                            pickedImagePath = image.path;
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt_rounded, color: PmsTheme.primary),
                      label: Text(
                        pickedImagePath != null ? 'Photo Selected (Tap to change)' : 'Select Site Photo',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: remarksCtrl,
                      decoration: const InputDecoration(labelText: 'Remarks', isDense: true),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 18),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PmsTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty || selectedCityId == null || selectedVendorId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all required fields')),
                            );
                            return;
                          }

                          final payload = {
                            'name': nameCtrl.text.trim(),
                            'city_id': selectedCityId,
                            'hoarding_vendor_id': selectedVendorId,
                            'type': selectedType,
                            'side': selectedSide,
                            'width': double.tryParse(widthCtrl.text.trim()),
                            'height': double.tryParse(heightCtrl.text.trim()),
                            'monthly_rent': double.tryParse(rentCtrl.text.trim()) ?? 0.0,
                            'status': selectedStatus,
                            'latitude': selectedLat,
                            'longitude': selectedLng,
                            'remarks': remarksCtrl.text.trim(),
                          };

                          if (site != null) {
                            context.read<HoardingBloc>().add(
                                  UpdateSiteEvent(site.id, payload, photoPath: pickedImagePath),
                                );
                          } else {
                            context.read<HoardingBloc>().add(
                                  CreateSiteEvent(payload, photoPath: pickedImagePath),
                                );
                          }
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          site != null ? 'Save Changes' : 'Create Site',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  CITY & VENDOR MODALS
  // ─────────────────────────────────────────────────────────────────
  void _openCityForm(BuildContext context, {HoardingCityModel? city}) {
    final nameCtrl = TextEditingController(text: city?.name ?? '');
    final stateCtrl = TextEditingController(text: city?.state ?? '');
    bool isActive = city?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text(city != null ? 'Edit City' : 'Add City'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'City Name *')),
                  const SizedBox(height: 8),
                  TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State')),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setDlgState(() => isActive = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final payload = {
                      'name': nameCtrl.text.trim(),
                      'state': stateCtrl.text.trim(),
                      'is_active': isActive,
                    };
                    if (city != null) {
                      context.read<HoardingBloc>().add(UpdateCityEvent(city.id, payload));
                    } else {
                      context.read<HoardingBloc>().add(CreateCityEvent(payload));
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openVendorForm(BuildContext context, List<HoardingCityModel> cities, {HoardingVendorModel? vendor}) {
    final nameCtrl = TextEditingController(text: vendor?.name ?? '');
    final phoneCtrl = TextEditingController(text: vendor?.phone ?? '');
    final emailCtrl = TextEditingController(text: vendor?.email ?? '');
    final addressCtrl = TextEditingController(text: vendor?.address ?? '');
    List<int> selectedCities = List.from(vendor?.operatingCityIds ?? []);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text(vendor != null ? 'Edit Vendor' : 'Add Hoarding Vendor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Vendor Name *')),
                    const SizedBox(height: 8),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                    const SizedBox(height: 8),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 8),
                    TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
                    const SizedBox(height: 12),
                    const Text('Operating Cities:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: cities.map((c) {
                        final isSel = selectedCities.contains(c.id);
                        return FilterChip(
                          label: Text(c.name, style: const TextStyle(fontSize: 11)),
                          selected: isSel,
                          onSelected: (selected) {
                            setDlgState(() {
                              if (selected) {
                                selectedCities.add(c.id);
                              } else {
                                selectedCities.remove(c.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final payload = {
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'address': addressCtrl.text.trim(),
                      'operating_city_ids': selectedCities,
                      'is_active': true,
                    };
                    if (vendor != null) {
                      context.read<HoardingBloc>().add(UpdateHoardingVendorEvent(vendor.id, payload));
                    } else {
                      context.read<HoardingBloc>().add(CreateHoardingVendorEvent(payload));
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSite(BuildContext context, HoardingSiteModel site) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete ${site.name} (${site.siteCode})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<HoardingBloc>().add(DeleteSiteEvent(site.id));
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCity(BuildContext context, HoardingCityModel city) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete City'),
        content: Text('Are you sure you want to delete ${city.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<HoardingBloc>().add(DeleteCityEvent(city.id));
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVendor(BuildContext context, HoardingVendorModel vendor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vendor'),
        content: Text('Are you sure you want to delete ${vendor.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<HoardingBloc>().add(DeleteHoardingVendorEvent(vendor.id));
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
