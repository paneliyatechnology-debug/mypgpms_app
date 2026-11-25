import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/food_menu_remote_data_source.dart';
import '../../data/models/dashboard_response_model.dart';
import '../../data/models/food_menu_model.dart';

class FeedbackMealItem {
  final int id;
  final String type;
  final String name;
  final String? image;
  final bool isFeedbackOpen;

  FeedbackMealItem({
    required this.id,
    required this.type,
    required this.name,
    this.image,
    this.isFeedbackOpen = true,
  });
}

class MenuFeedbackPage extends StatefulWidget {
  final List<FoodMealItemModel>? initialMeals;
  final String? dateFormatted;

  const MenuFeedbackPage({
    super.key,
    this.initialMeals,
    this.dateFormatted,
  });

  @override
  State<MenuFeedbackPage> createState() => _MenuFeedbackPageState();
}

class _MenuFeedbackPageState extends State<MenuFeedbackPage> {
  final Map<int, int> _ratings = {};
  final TextEditingController _commentController = TextEditingController();

  List<FeedbackMealItem> _meals = [];
  String _dateLabel = '';
  String _selectedFilter = 'All'; // 'All', 'Breakfast', 'Lunch', 'Dinner'
  int? _selectedMealId;
  bool _isSubmitting = false;

  final List<String> _filterTabs = ['All', 'Breakfast', 'Lunch', 'Dinner'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDynamicMeals();
    });
  }

  void _initDynamicMeals() {
    // 1. Check Route Arguments
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map<String, dynamic>) {
      if (routeArgs['selectedMealId'] is int) {
        _selectedMealId = routeArgs['selectedMealId'] as int;
      }
      if (routeArgs['dateFormatted'] is String) {
        _dateLabel = routeArgs['dateFormatted'] as String;
      }
      if (routeArgs['selectedMealType'] is String) {
        final sel = routeArgs['selectedMealType'] as String;
        if (_filterTabs.any((t) => t.toLowerCase() == sel.toLowerCase())) {
          _selectedFilter = _filterTabs.firstWhere((t) => t.toLowerCase() == sel.toLowerCase());
        }
      }
      if (routeArgs['meals'] is List<FoodMealItemModel>) {
        final list = routeArgs['meals'] as List<FoodMealItemModel>;
        if (list.isNotEmpty) {
          _setMealsFromModelList(list);
          return;
        }
      }
      if (routeArgs['meals'] is List<FeedbackMealItem>) {
        final list = routeArgs['meals'] as List<FeedbackMealItem>;
        if (list.isNotEmpty) {
          setState(() {
            _meals = list;
          });
          return;
        }
      }
    }

    // 2. Check Constructor Parameters
    if (widget.initialMeals != null && widget.initialMeals!.isNotEmpty) {
      _dateLabel = widget.dateFormatted ?? _dateLabel;
      _setMealsFromModelList(widget.initialMeals!);
      return;
    }

    // 3. Fallback: Load from cached dashboard today_menu
    _loadFromDashboardCache();
  }

  List<FeedbackMealItem> get _visibleMeals {
    if (_selectedMealId != null) {
      final specific = _meals.where((m) => m.id == _selectedMealId).toList();
      if (specific.isNotEmpty) return specific;
    }
    if (_selectedFilter == 'All') return _meals;
    final filtered = _meals.where((m) => m.type.toLowerCase() == _selectedFilter.toLowerCase()).toList();
    return filtered.isNotEmpty ? filtered : _meals;
  }

  void _setMealsFromModelList(List<FoodMealItemModel> list) {
    setState(() {
      _meals = list.map((m) {
        return FeedbackMealItem(
          id: m.id,
          type: m.displayTitle,
          name: m.displayItems,
          image: m.imageUrl,
          isFeedbackOpen: m.isFeedbackOpen,
        );
      }).toList();
    });
  }

  void _loadFromDashboardCache() {
    try {
      final prefService = di.sl<PreferencesService>();
      final cached = prefService.getSavedDashboard();
      if (cached != null) {
        final data = DashboardDataModel.fromJson(cached);
        if (data.todayMenu.isNotEmpty) {
          setState(() {
            _meals = data.todayMenu.map((m) {
              return FeedbackMealItem(
                id: m.id ?? 1,
                type: m.mealType ?? 'Meal',
                name: m.items ?? m.foodName ?? 'Food',
                image: m.imageUrl,
                isFeedbackOpen: m.isActive,
              );
            }).toList();
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback if no cache at all
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    setState(() {
      if (_dateLabel.isEmpty) {
        _dateLabel = 'Today • ${now.day} ${months[now.month - 1]} ${now.year}';
      }
      _meals = [];
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitAllFeedback() async {
    if (_ratings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating for at least one meal.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final comment = _commentController.text.trim();
    final dataSource = di.sl<FoodMenuRemoteDataSource>();

    int successCount = 0;
    String? firstError;

    for (final entry in _ratings.entries) {
      final menuId = entry.key;
      final rating = entry.value;

      try {
        await dataSource.submitFeedback(
          menuId: menuId,
          rating: rating,
          comments: comment.isNotEmpty ? comment : null,
        );
        successCount++;
      } catch (e) {
        firstError ??= e.toString().replaceFirst('Exception: ', '');
      }
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your feedback has been submitted successfully.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(firstError ?? 'Failed to submit feedback. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 18.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Feedback',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
          children: [
            // Top Thumbs-up Illustration & Stars
            Center(
              child: Container(
                width: 72.0,
                height: 72.0,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F3ED),
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.thumb_up_alt_rounded,
                      color: AppColors.primary,
                      size: 28.0,
                    ),
                    const SizedBox(height: 3.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => const Icon(
                          Icons.star_rounded,
                          size: 10.0,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12.0),

            // Heading & Subtitle
            Center(
              child: Text(
                'How was the food?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 4.0),
            Center(
              child: Text(
                _dateLabel.isNotEmpty
                    ? _dateLabel
                    : 'Your feedback helps us to improve.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.0,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Meal Filter Tabs: All | Breakfast | Lunch | Dinner
            if (_meals.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 14.0),
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                ),
                child: Row(
                  children: _filterTabs.map((tab) {
                    final isSelected = _selectedFilter == tab;
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFilter = tab;
                            _selectedMealId = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(999.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 7.0),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(999.0),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            tab,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.0,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Meal Rating Cards
            if (_visibleMeals.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20.0),
                padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.restaurant_outlined, size: 36.0, color: AppColors.primary),
                    const SizedBox(height: 12.0),
                    Text(
                      'Menu not available',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'No meals found to review for this day.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.0,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ..._visibleMeals.map((meal) {
              final currentRating = _ratings[meal.id] ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 4.0,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          meal.type,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        _buildMealBadge(meal.type),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: meal.image != null && meal.image!.startsWith('http')
                              ? Image.network(
                                  meal.image!,
                                  width: 64.0,
                                  height: 52.0,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _fallbackMealIcon(meal.type),
                                )
                              : _fallbackMealIcon(meal.type),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  final starValue = starIndex + 1;
                                  final isFilled = starValue <= currentRating;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _ratings[meal.id] = starValue;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6.0),
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 6.0),
                                      child: Icon(
                                        isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                                        size: 32.0,
                                        color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              if (currentRating > 0) ...[
                                const SizedBox(height: 3.0),
                                Text(
                                  _getRatingLabel(currentRating),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8.0),

            // Additional Comments Box
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    maxLength: 300,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Any additional comments',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF9CA3AF),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      counterText: '',
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${_commentController.text.length}/300',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.0,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18.0),

            // Submit Feedback Button
            InkWell(
              onTap: _isSubmitting ? null : _submitAllFeedback,
              borderRadius: BorderRadius.circular(999.0),
              child: Container(
                width: double.infinity,
                height: 48.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999.0),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22.0,
                        height: 22.0,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Text(
                        'Submit Feedback',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12.0),

            // Skip for now Button
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _buildMealBadge(String type) {
    Color bg;
    Color fg;
    final lower = type.toLowerCase();
    if (lower.contains('break')) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
    } else if (lower.contains('lunch')) {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF047857);
    } else {
      bg = const Color(0xFFE0E7FF);
      fg = const Color(0xFF4338CA);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        type,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }

  Widget _fallbackMealIcon(String mealType) {
    IconData icon = Icons.restaurant_outlined;
    final m = mealType.toLowerCase();
    if (m.contains('break')) {
      icon = Icons.free_breakfast_outlined;
    } else if (m.contains('lunch')) {
      icon = Icons.lunch_dining_outlined;
    } else if (m.contains('dinner')) {
      icon = Icons.dinner_dining_outlined;
    }

    return Container(
      width: 60.0,
      height: 44.0,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3ED),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20.0),
    );
  }
}
