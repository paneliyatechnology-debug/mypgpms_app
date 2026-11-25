import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/widgets/common_bottom_nav_bar.dart';
import '../../../../core/colors/app_colors.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../injection_container.dart' as di;
import '../../data/datasources/food_menu_remote_data_source.dart';
import '../../data/models/food_menu_model.dart';

class DayTabItem {
  final DateTime date;
  final String dayLabel;
  final String dateNumber;
  final String fullDateFormatted;
  final String shortTag;
  final bool isToday;

  DayTabItem({
    required this.date,
    required this.dayLabel,
    required this.dateNumber,
    required this.fullDateFormatted,
    required this.shortTag,
    required this.isToday,
  });

  String get dateQueryString {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class WeeklyMenuPage extends StatefulWidget {
  const WeeklyMenuPage({super.key});

  @override
  State<WeeklyMenuPage> createState() => _WeeklyMenuPageState();
}

class _WeeklyMenuPageState extends State<WeeklyMenuPage> {
  int _selectedDayIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;

  late final List<DayTabItem> _weekDays;
  final Map<String, FoodMealsModel> _mealsByDate = {};

  @override
  void initState() {
    super.initState();
    _weekDays = _generateWeekDays();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMenuForSelectedDate();
    });
  }

  List<DayTabItem> _generateWeekDays() {
    final now = DateTime.now();
    final List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<String> fullDayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final List<String> fullMonthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    // Generate 7 days: Today (0) and next 6 days (1..6)
    return List.generate(7, (i) {
      final date = now.add(Duration(days: i));
      final dayName = dayNames[date.weekday - 1];
      final fullDay = fullDayNames[date.weekday - 1];
      final fullMonth = fullMonthNames[date.month - 1];
      final isToday = i == 0;

      return DayTabItem(
        date: date,
        dayLabel: dayName,
        dateNumber: date.day.toString().padLeft(2, '0'),
        fullDateFormatted: isToday
            ? 'Today  •  $fullDay, ${date.day} $fullMonth ${date.year}'
            : '$fullDay, ${date.day} $fullMonth ${date.year}',
        shortTag: isToday ? 'Today' : (i == 1 ? 'Tomorrow' : dayName),
        isToday: isToday,
      );
    });
  }

  Future<void> _fetchMenuForSelectedDate({bool forceRefresh = false}) async {
    final currentDay = _weekDays[_selectedDayIndex];
    final dateStr = currentDay.dateQueryString;

    if (!forceRefresh && _mealsByDate.containsKey(dateStr)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    int branchId = 1;
    try {
      final pref = di.sl<PreferencesService>();
      final dash = pref.getSavedDashboard();
      if (dash?['stay']?['branch_id'] != null) {
        branchId = int.tryParse(dash!['stay']['branch_id'].toString()) ?? 1;
      } else if (dash?['meta']?['branch_id'] != null) {
        branchId = int.tryParse(dash!['meta']['branch_id'].toString()) ?? 1;
      }
    } catch (_) {}

    try {
      final dataSource = di.sl<FoodMenuRemoteDataSource>();
      final result = await dataSource.getFoodMenu(
        branchId: branchId,
        startDate: dateStr,
        endDate: dateStr,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
          if (result.isNotEmpty && result.first.meals != null) {
            _mealsByDate[dateStr] = result.first.meals!;
          } else {
            _mealsByDate[dateStr] = FoodMealsModel(breakfast: [], lunch: [], dinner: []);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!_mealsByDate.containsKey(dateStr)) {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? (screenWidth - 460) / 2 : 16.0;

    final currentDay = _weekDays[_selectedDayIndex];
    final dateStr = currentDay.dateQueryString;
    final meals = _mealsByDate[dateStr];

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
          'Weekly Menu',
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
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _fetchMenuForSelectedDate(forceRefresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6.0),
            children: [
              // 1. Day selector horizontal bar (Today + 6 days after)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 6.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(_weekDays.length, (index) {
                    final isSelected = _selectedDayIndex == index;
                    final day = _weekDays[index];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: InkWell(
                          onTap: () {
                            if (_selectedDayIndex != index) {
                              setState(() {
                                _selectedDayIndex = index;
                              });
                              _fetchMenuForSelectedDate();
                            }
                          },
                          borderRadius: BorderRadius.circular(10.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  day.isToday ? 'Today' : day.dayLabel,
                                  maxLines: 1,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 3.0),
                                Text(
                                  day.dateNumber,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14.0),

              // 2. Date indicator header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      currentDay.fullDateFormatted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  if (currentDay.isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3ED),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        'Today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12.0),

              // 3. Dynamic Meals Section
              if (_isLoading && meals == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_errorMessage != null && meals == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36.0),
                      const SizedBox(height: 8.0),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.0,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      ElevatedButton(
                        onPressed: () => _fetchMenuForSelectedDate(forceRefresh: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              else if (meals == null || meals.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 36.0),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52.0,
                        height: 52.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F3ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant_outlined, color: AppColors.primary, size: 26.0),
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        'No Menu Scheduled',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'No meals have been scheduled for this date yet.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.0,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // Breakfast Meals
                if (meals.breakfast.isNotEmpty)
                  ...meals.breakfast.map((m) => _buildMealCard('Breakfast', m))
                else
                  _buildEmptyMealCard('Breakfast'),

                // Lunch Meals
                if (meals.lunch.isNotEmpty)
                  ...meals.lunch.map((m) => _buildMealCard('Lunch', m))
                else
                  _buildEmptyMealCard('Lunch'),

                // Dinner Meals
                if (meals.dinner.isNotEmpty)
                  ...meals.dinner.map((m) => _buildMealCard('Dinner', m))
                else
                  _buildEmptyMealCard('Dinner'),
              ],
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildMealCard(String mealCategory, FoodMealItemModel meal) {
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
          Text(
            mealCategory,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: meal.imageUrl != null && meal.imageUrl!.startsWith('http')
                    ? Image.network(
                        meal.imageUrl!,
                        width: 68.0,
                        height: 50.0,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _fallbackMealIcon(mealCategory),
                      )
                    : _fallbackMealIcon(mealCategory),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.displayItems,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      meal.displayTiming.isNotEmpty ? meal.displayTiming : (meal.description ?? ''),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMealCard(String mealCategory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Row(
        children: [
          _fallbackMealIcon(mealCategory),
          const SizedBox(width: 12.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mealCategory,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                'No menu scheduled',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackMealIcon(String mealCategory) {
    IconData icon = Icons.restaurant_outlined;
    final m = mealCategory.toLowerCase();
    if (m.contains('break')) {
      icon = Icons.free_breakfast_outlined;
    } else if (m.contains('lunch')) {
      icon = Icons.lunch_dining_outlined;
    } else if (m.contains('dinner')) {
      icon = Icons.dinner_dining_outlined;
    }

    return Container(
      width: 68.0,
      height: 50.0,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3ED),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22.0),
    );
  }
}
