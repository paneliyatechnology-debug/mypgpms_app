import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/widgets/common_bottom_nav_bar.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/food_menu_remote_data_source.dart';
import '../../data/models/dashboard_response_model.dart';
import '../../data/models/food_menu_model.dart';

class TodayMenuPage extends StatefulWidget {
  const TodayMenuPage({super.key});

  @override
  State<TodayMenuPage> createState() => _TodayMenuPageState();
}

class _TodayMenuPageState extends State<TodayMenuPage> {
  int _selectedMealTab = 0; // 0: Breakfast, 1: Lunch, 2: Dinner
  bool _isLoading = true;

  final List<String> _mealTabs = ['Breakfast', 'Lunch', 'Dinner'];
  List<FoodMealItemModel> _allFoodMeals = [];
  final Map<int, List<Map<String, dynamic>>> _mealsByTab = {
    0: [],
    1: [],
    2: [],
  };
  final Map<int, int> _currentMealIndexByTab = {
    0: 0,
    1: 0,
    2: 0,
  };
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadMenuFromCache();
    _fetchTodayMenuFromApi();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadMenuFromCache() {
    try {
      final prefService = di.sl<PreferencesService>();
      final cached = prefService.getSavedDashboard();
      if (cached != null) {
        final data = DashboardDataModel.fromJson(cached);
        if (data.todayMenu.isNotEmpty) {
          _populateMealsFromApi(data.todayMenu);
          _allFoodMeals = data.todayMenu.map((m) {
            return FoodMealItemModel(
              id: m.id ?? 1,
              mealType: m.mealType ?? 'Breakfast',
              name: m.foodName ?? m.name ?? m.items ?? 'Food',
              description: m.description,
              imageUrl: m.imageUrl,
              image: m.image,
              startTime: m.startTime,
              endTime: m.endTime,
              includedItems: m.includedItems ?? m.items,
              isActive: m.isActive,
              isFeedbackOpen: true,
            );
          }).toList();
          _isLoading = false;
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchTodayMenuFromApi() async {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final dateKey = '$y-$m-$d';

    try {
      final api = di.sl<FoodMenuRemoteDataSource>();
      final result = await api.getFoodMenu(
        startDate: dateKey,
        endDate: dateKey,
      );

      if (result.isNotEmpty && mounted) {
        final dayMeals = result.first.meals;
        if (dayMeals != null) {
          final List<FoodMealItemModel> collected = [];
          collected.addAll(dayMeals.breakfast);
          collected.addAll(dayMeals.lunch);
          collected.addAll(dayMeals.dinner);

          if (collected.isNotEmpty) {
            setState(() {
              _allFoodMeals = collected;
            });
            _populateFromFoodMealsModel(dayMeals);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching today menu: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _populateFromFoodMealsModel(FoodMealsModel dayMeals) {
    void updateTab(int tabIdx, List<FoodMealItemModel> list, String fallbackTitle) {
      if (list.isNotEmpty) {
        _mealsByTab[tabIdx] = list.map((item) {
          final inclTitle = item.includedItems?.isNotEmpty == true
              ? item.includedItems!
              : (item.description?.isNotEmpty == true ? item.description! : 'Fresh Meal');

          return {
            'id': item.id,
            'meal_type': item.displayTitle.isNotEmpty ? item.displayTitle : fallbackTitle,
            'name': item.name,
            'timing': item.displayTiming,
            'image': item.imageUrl ?? item.image ?? '',
            'isVeg': true,
            'isFeedbackOpen': item.isFeedbackOpen,
            'included': [
              {'icon': Icons.restaurant_menu_outlined, 'title': inclTitle},
              if (item.description?.isNotEmpty == true && item.description != inclTitle)
                {'icon': Icons.info_outline_rounded, 'title': item.description!},
            ],
            'model': item,
          };
        }).toList();
      } else {
        _mealsByTab[tabIdx] = [];
      }
    }

    updateTab(0, dayMeals.breakfast, 'Breakfast');
    updateTab(1, dayMeals.lunch, 'Lunch');
    updateTab(2, dayMeals.dinner, 'Dinner');
    if (mounted) setState(() {});
  }

  void _populateMealsFromApi(List<TodayMenuModel> apiList) {
    _mealsByTab[0] = [];
    _mealsByTab[1] = [];
    _mealsByTab[2] = [];

    for (final item in apiList) {
      final type = (item.rawMealType ?? item.mealType ?? '').toLowerCase();
      int tabIdx = -1;
      if (type.contains('break')) {
        tabIdx = 0;
      } else if (type.contains('lunch')) {
        tabIdx = 1;
      } else if (type.contains('dinner')) {
        tabIdx = 2;
      }

      if (tabIdx >= 0 && tabIdx < _mealTabs.length) {
        final inclTitle = item.includedItems?.isNotEmpty == true
            ? item.includedItems!
            : (item.description?.isNotEmpty == true ? item.description! : 'Fresh Meal');

        _mealsByTab[tabIdx]!.add({
          'id': item.id ?? (tabIdx + 1),
          'meal_type': item.mealType ?? _mealTabs[tabIdx],
          'name': item.foodName ?? item.name ?? item.items ?? '',
          'timing': item.timings ?? (item.startTime != null && item.endTime != null ? '${item.startTime} - ${item.endTime}' : ''),
          'image': item.imageUrl ?? item.image ?? '',
          'isVeg': true,
          'isFeedbackOpen': true,
          'included': [
            {'icon': Icons.restaurant_menu_outlined, 'title': inclTitle},
            if (item.description?.isNotEmpty == true && item.description != inclTitle)
              {'icon': Icons.info_outline_rounded, 'title': item.description!},
          ],
        });
      }
    }
    if (mounted) setState(() {});
  }

  void _navigateToFeedback({String? mealType, FoodMealItemModel? specificMeal}) {
    if (_allFoodMeals.isEmpty && _mealsByTab.values.every((list) => list.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu not available for feedback today.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    List<FoodMealItemModel> mealsToPass = [];
    if (specificMeal != null) {
      mealsToPass = [specificMeal];
    } else {
      mealsToPass = List.from(_allFoodMeals);
      if (mealsToPass.isEmpty) {
        for (final entry in _mealsByTab.entries) {
          for (final m in entry.value) {
            final model = m['model'] as FoodMealItemModel?;
            if (model != null) {
              mealsToPass.add(model);
            }
          }
        }
      }
    }

    Navigator.of(context).pushNamed(
      AppRoutes.menuFeedback,
      arguments: {
        'meals': mealsToPass,
        'selectedMeal': specificMeal,
        if (specificMeal != null) 'selectedMealId': specificMeal.id,
        'dateFormatted': 'Today • ${_getFormattedToday()}',
        if (mealType != null && mealType.isNotEmpty) 'selectedMealType': mealType,
      },
    );
  }

  String _getFormattedToday() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _onTabSelected(int index) {
    if (_selectedMealTab != index) {
      setState(() {
        _selectedMealTab = index;
      });
      final targetPage = _currentMealIndexByTab[index] ?? 0;
      final total = _mealsByTab[index]?.length ?? 0;
      final safePage = total > 0 ? targetPage.clamp(0, total - 1) : 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(safePage);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;
    final mealList = _mealsByTab[_selectedMealTab] ?? [];
    final int currentMealIndex = (_currentMealIndexByTab[_selectedMealTab] ?? 0).clamp(0, (mealList.isEmpty ? 1 : mealList.length) - 1);

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
          "Today's Menu",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6.0),
          children: [
            // Date
            Text(
              _getFormattedToday(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 10.0),

            // Segmented Meal Tabs: Breakfast | Lunch | Dinner
            Container(
              padding: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Row(
                children: List.generate(_mealTabs.length, (index) {
                  final isSelected = _selectedMealTab == index;
                  final count = _mealsByTab[index]?.length ?? 0;
                  final label = count > 1 ? '${_mealTabs[index]} ($count)' : _mealTabs[index];

                  return Expanded(
                    child: InkWell(
                      onTap: () => _onTabSelected(index),
                      borderRadius: BorderRadius.circular(999.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(999.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.0,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14.0),

            // Main Meal Content: Horizontal Carousel or Single / Empty State
            if (_isLoading)
              Container(
                height: 220.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                ),
                child: const CircularProgressIndicator(color: AppColors.primary),
              )
            else if (mealList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 8.0,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60.0,
                      height: 60.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F3ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.restaurant_outlined,
                        color: AppColors.primary,
                        size: 28.0,
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      'Menu not available',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      'Menu data for ${_mealTabs[_selectedMealTab]} is not available.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              )
            else if (mealList.length == 1)
              _buildMealCard(mealList.first, 0, 1)
            else
              // Multiple Items (Horizontal Scroll Carousel with Index below)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 395.0,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: mealList.length,
                      onPageChanged: (pageIdx) {
                        setState(() {
                          _currentMealIndexByTab[_selectedMealTab] = pageIdx;
                        });
                      },
                      itemBuilder: (context, idx) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: _buildMealCard(mealList[idx], idx, mealList.length),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Below Index: Left Arrow + Dot Indicators + Right Arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous Arrow Button
                      InkWell(
                        onTap: currentMealIndex > 0
                            ? () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            : null,
                        borderRadius: BorderRadius.circular(999.0),
                        child: Container(
                          width: 32.0,
                          height: 32.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentMealIndex > 0 ? const Color(0xFFE8F3ED) : const Color(0xFFF3F4F6),
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 20.0,
                            color: currentMealIndex > 0 ? AppColors.primary : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),

                      // Dots Indicator
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(mealList.length, (dotIdx) {
                          final isCurrent = dotIdx == currentMealIndex;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                dotIdx,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              width: isCurrent ? 22.0 : 8.0,
                              height: 8.0,
                              decoration: BoxDecoration(
                                color: isCurrent ? AppColors.primary : const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 12.0),

                      // Next Arrow Button
                      InkWell(
                        onTap: currentMealIndex < mealList.length - 1
                            ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            : null,
                        borderRadius: BorderRadius.circular(999.0),
                        child: Container(
                          width: 32.0,
                          height: 32.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentMealIndex < mealList.length - 1
                                ? const Color(0xFFE8F3ED)
                                : const Color(0xFFF3F4F6),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 20.0,
                            color: currentMealIndex < mealList.length - 1
                                ? AppColors.primary
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),

                  // Below Index Text
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3ED),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      'Item ${currentMealIndex + 1} of ${mealList.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20.0),

            // View Weekly Menu Button
            InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.weeklyMenu);
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
                  'View Weekly Menu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> currentMeal, int itemIndex, int totalItems) {
    final foodImage = currentMeal['image'] as String? ?? '';
    final includedList = (currentMeal['included'] as List<dynamic>?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image with Veg Badge & Index Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                child: (foodImage.startsWith('http'))
                    ? Image.network(
                        foodImage,
                        height: 165.0,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _fallbackMealHeader(),
                      )
                    : (foodImage.isNotEmpty)
                        ? Image.asset(
                            foodImage,
                            height: 165.0,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _fallbackMealHeader(),
                          )
                        : _fallbackMealHeader(),
              ),
              if (totalItems > 1)
                Positioned(
                  left: 12.0,
                  top: 12.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      '${itemIndex + 1} of $totalItems',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 12.0,
                bottom: 12.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5.0),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1F000000), blurRadius: 4.0),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7.0,
                        height: 7.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        'Veg',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Meal Details
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (currentMeal['name'] as String?) ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if ((currentMeal['timing'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 3.0),
                  Text(
                    currentMeal['timing'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.0,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
                const SizedBox(height: 12.0),
                const Divider(color: Color(0xFFF3F4F6), height: 1.0),
                const SizedBox(height: 12.0),

                // Also Included
                if (includedList.isNotEmpty) ...[
                  Text(
                    'Also included',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  Row(
                    children: includedList.map((item) {
                      final mapItem = item as Map<String, dynamic>;
                      return Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 32.0,
                              height: 32.0,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F3ED),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                (mapItem['icon'] as IconData?) ?? Icons.restaurant_menu_outlined,
                                color: AppColors.primary,
                                size: 16.0,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                (mapItem['title'] as String?) ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14.0),
                ],

                // Quick Feedback Button for current meal
                InkWell(
                  onTap: () {
                    FoodMealItemModel? targetMeal = currentMeal['model'] as FoodMealItemModel?;
                    targetMeal ??= FoodMealItemModel(
                      id: (currentMeal['id'] as int?) ?? 1,
                      mealType: (currentMeal['meal_type'] as String?) ?? _mealTabs[_selectedMealTab],
                      name: (currentMeal['name'] as String?) ?? '',
                      description: currentMeal['description'] as String?,
                      includedItems: (currentMeal['included'] is List && (currentMeal['included'] as List).isNotEmpty)
                          ? (currentMeal['included'] as List).first['title'] as String?
                          : null,
                      imageUrl: (currentMeal['image'] is String && (currentMeal['image'] as String).startsWith('http'))
                          ? currentMeal['image'] as String
                          : null,
                      image: (currentMeal['image'] is String) ? currentMeal['image'] as String : null,
                      startTime: currentMeal['timing'] as String?,
                      isFeedbackOpen: true,
                    );
                    _navigateToFeedback(
                      mealType: _mealTabs[_selectedMealTab],
                      specificMeal: targetMeal,
                    );
                  },
                  borderRadius: BorderRadius.circular(10.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3ED),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.primary, size: 18.0),
                        const SizedBox(width: 6.0),
                        Text(
                          'Give Feedback for ${_mealTabs[_selectedMealTab]}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackMealHeader() {
    return Container(
      height: 165.0,
      width: double.infinity,
      color: const Color(0xFFE8F3ED),
      child: const Center(
        child: Icon(Icons.restaurant, color: AppColors.primary, size: 40.0),
      ),
    );
  }
}
