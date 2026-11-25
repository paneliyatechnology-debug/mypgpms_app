import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/complaints_remote_data_source.dart';
import '../../data/models/complaint_category_model.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  String _selectedCategory = 'Cleaning';
  bool _isLoading = false;
  String? _errorMessage;
  List<ComplaintCategoryModel> _categoryModels = [];

  // Fallback categories if network is unavailable
  final List<Map<String, dynamic>> _fallbackCategories = [
    {'title': 'Cleaning', 'key': 'cleaning', 'icon': Icons.cleaning_services_outlined},
    {'title': 'AC', 'key': 'ac', 'icon': Icons.ac_unit_rounded},
    {'title': 'WiFi', 'key': 'wifi', 'icon': Icons.wifi_rounded},
    {'title': 'Water', 'key': 'water', 'icon': Icons.water_drop_outlined},
    {'title': 'Food', 'key': 'food', 'icon': Icons.restaurant_outlined},
    {'title': 'Electricity', 'key': 'electricity', 'icon': Icons.bolt_rounded},
    {'title': 'Furniture', 'key': 'furniture', 'icon': Icons.weekend_outlined},
    {'title': 'Plumbing', 'key': 'plumbing', 'icon': Icons.plumbing_rounded},
    {'title': 'Appliances', 'key': 'appliances', 'icon': Icons.kitchen_outlined},
    {'title': 'Washing Machine', 'key': 'washing_machine', 'icon': Icons.local_laundry_service_outlined},
    {'title': 'Other', 'key': 'other', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedCategories();
    _fetchCategories();
  }

  void _loadCachedCategories() {
    try {
      final prefService = di.sl<PreferencesService>();
      final cached = prefService.getSavedComplaintCategories();
      if (cached != null && cached.isNotEmpty) {
        final list = cached.map((e) => ComplaintCategoryModel.fromJson(e)).toList();
        setState(() {
          _categoryModels = list;
          if (_categoryModels.isNotEmpty && !_categoryModels.any((c) => c.name == _selectedCategory)) {
            _selectedCategory = _categoryModels.first.name;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchCategories() async {
    if (_categoryModels.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dataSource = di.sl<ComplaintsRemoteDataSource>();
      final remoteList = await dataSource.getComplaintCategories();
      if (mounted) {
        setState(() {
          _categoryModels = remoteList;
          _isLoading = false;
          _errorMessage = null;
          if (_categoryModels.isNotEmpty && !_categoryModels.any((c) => c.name == _selectedCategory)) {
            _selectedCategory = _categoryModels.first.name;
          }
        });

        final prefService = di.sl<PreferencesService>();
        await prefService.saveComplaintCategories(remoteList.map((e) => e.toJson()).toList());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_categoryModels.isEmpty) {
            _errorMessage = e.toString();
          }
        });
      }
    }
  }

  IconData _resolveIcon(String? iconKey, String? name) {
    final n = (name ?? '').toLowerCase().trim();
    final k = (iconKey ?? '').toLowerCase().trim();
    final combined = '$n $k';

    // 1. Cleaning
    if (n.contains('clean') ||
        combined.contains('clean') ||
        combined.contains('sparkle') ||
        combined.contains('housekeep') ||
        combined.contains('broom') ||
        combined.contains('mop')) {
      return Icons.cleaning_services_outlined;
    }

    // 2. AC (Air Conditioner)
    if (n == 'ac' ||
        n.contains('ac ') ||
        n.startsWith('ac') ||
        n.endsWith('ac') ||
        combined.contains('air') ||
        combined.contains('cool') ||
        combined.contains('hvac') ||
        (combined.contains('ac') && !n.contains('wash'))) {
      return Icons.ac_unit_rounded;
    }

    // 3. Food
    if (n.contains('food') ||
        combined.contains('food') ||
        combined.contains('meal') ||
        combined.contains('dining') ||
        combined.contains('mess') ||
        combined.contains('kitchen') ||
        combined.contains('cook') ||
        combined.contains('restaurant')) {
      return Icons.restaurant_outlined;
    }

    // 4. Furniture
    if (n.contains('furniture') ||
        combined.contains('furniture') ||
        combined.contains('bed') ||
        combined.contains('chair') ||
        combined.contains('table') ||
        combined.contains('sofa') ||
        combined.contains('couch') ||
        combined.contains('wardrobe') ||
        combined.contains('wood') ||
        combined.contains('desk') ||
        combined.contains('almirah')) {
      return Icons.weekend_outlined;
    }

    // 5. WiFi
    if (n.contains('wifi') ||
        combined.contains('wifi') ||
        combined.contains('internet') ||
        combined.contains('network') ||
        combined.contains('router')) {
      return Icons.wifi_rounded;
    }

    // 6. Water
    if (n.contains('water') ||
        combined.contains('water') ||
        combined.contains('drop') ||
        combined.contains('filter') ||
        combined.contains('ro')) {
      return Icons.water_drop_outlined;
    }

    // 7. Electricity
    if (n.contains('electr') ||
        combined.contains('electric') ||
        combined.contains('bolt') ||
        combined.contains('lightning') ||
        combined.contains('power') ||
        combined.contains('light')) {
      return Icons.bolt_rounded;
    }

    // 8. Plumbing
    if (n.contains('plumb') ||
        combined.contains('plumb') ||
        combined.contains('pipe') ||
        combined.contains('tap') ||
        combined.contains('leak') ||
        combined.contains('drain')) {
      return Icons.plumbing_rounded;
    }

    // 9. Appliances
    if (n.contains('appliance') ||
        combined.contains('appliance') ||
        combined.contains('fridge') ||
        combined.contains('refrigerator') ||
        combined.contains('oven') ||
        combined.contains('microwave') ||
        combined.contains('geyser') ||
        combined.contains('heater')) {
      return Icons.kitchen_outlined;
    }

    // 10. Washing Machine
    if (n.contains('wash') || combined.contains('wash') || combined.contains('laundry')) {
      return Icons.local_laundry_service_outlined;
    }

    return Icons.more_horiz_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Complain',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchCategories,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10.0),
                  children: [
                    Text(
                      'Select the category for your complaint',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    if (_isLoading && _categoryModels.isEmpty) ...[
                      const SizedBox(height: 60.0),
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                      ),
                      const SizedBox(height: 60.0),
                    ] else if (_errorMessage != null && _categoryModels.isEmpty) ...[
                      _buildErrorState(),
                    ] else ...[
                      // Dynamic Categories 3-column Grid
                      _buildCategoriesGrid(screenWidth),
                    ],

                    const SizedBox(height: 20.0),

                    // Need urgent help? Notice
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3ED).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32.0,
                            height: 32.0,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.help_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 18.0,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need urgent help?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 1.0),
                                Text(
                                  'Call security or use the emergency button.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
            ),

            // Next Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
              child: InkWell(
                onTap: () async {
                  final nav = Navigator.of(context);
                  final result = await nav.pushNamed(
                    AppRoutes.createComplaint,
                    arguments: _selectedCategory,
                  );
                  if (result == true && mounted) {
                    nav.pop();
                  }
                },
                borderRadius: BorderRadius.circular(999.0),
                child: Container(
                  width: double.infinity,
                  height: 48.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                  child: Text(
                    'Next',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(double screenWidth) {
    final itemWidth = (screenWidth > 600 ? 460 - 20 : screenWidth - 32 - 20) / 3;

    final List<Map<String, dynamic>> displayItems = [];
    if (_categoryModels.isNotEmpty) {
      for (final cat in _categoryModels) {
        if (cat.name.toLowerCase() == 'other') continue;
        displayItems.add({
          'title': cat.name,
          'icon': _resolveIcon(cat.icon ?? cat.key, cat.name),
        });
      }
      // Add Washing Machine if not already in categoryModels
      if (!displayItems.any((c) =>
          c['title'].toString().toLowerCase().contains('wash') ||
          c['title'].toString().toLowerCase().contains('laundry'))) {
        displayItems.add({
          'title': 'Washing Machine',
          'icon': Icons.local_laundry_service_outlined,
        });
      }
      // Always put Other at the end
      displayItems.add({
        'title': 'Other',
        'icon': Icons.more_horiz_rounded,
      });
    } else {
      displayItems.addAll(_fallbackCategories);
    }

    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: displayItems.map((cat) {
        final title = cat['title'] as String;
        final icon = cat['icon'] as IconData;
        final isSelected = _selectedCategory == title;

        return SizedBox(
          width: itemWidth,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = title;
              });
            },
            borderRadius: BorderRadius.circular(14.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 6.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                  width: isSelected ? 1.6 : 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFD1FAE5) : const Color(0xFFE8F3ED),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? AppColors.primary : const Color(0xFF165A42),
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.0,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFF9CA3AF), size: 36.0),
          const SizedBox(height: 8.0),
          Text(
            'Unable to load categories',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999.0)),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            ),
            onPressed: _fetchCategories,
            child: Text(
              'Retry',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.0),
            ),
          ),
        ],
      ),
    );
  }
}
