import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../themes/app_theme.dart';
import 'dart:math';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  _ToolsScreenState createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Tool data with calculator types
  final List<Map<String, dynamic>> _tools = [
    {
      'title': 'BMI Calculator',
      'description': 'Calculate your Body Mass Index to assess your health.',
      'icon': Icons.favorite_rounded,
      'image':
          'https://images.unsplash.com/photo-1505751172876-fa1923c5c6a2?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
      'action': 'Calculate BMI',
      'type': 'bmi',
    },
    {
      'title': 'Body Fat Percentage',
      'description': 'Estimate your body fat for fitness tracking.',
      'icon': Icons.accessibility_new_rounded,
      'image':
          'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
      'action': 'Calculate Fat',
      'type': 'body_fat',
    },
    {
      'title': 'Water Intake',
      'description': 'Monitor your daily water consumption for hydration.',
      'icon': Icons.water_drop_rounded,
      'image':
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
      'action': 'Set Water Goal',
      'type': 'water',
    },
    {
      'title': 'Step Counter',
      'description': 'Track your daily steps to stay active.',
      'icon': Icons.directions_walk_rounded,
      'image':
          'https://images.unsplash.com/photo-1512941937669-8bf2abe2ed58?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
      'action': 'Count Steps',
      'type': 'steps',
    },
    {
      'title': 'Sleep Tracker',
      'description': 'Monitor sleep for better recovery.',
      'icon': Icons.bedtime_rounded,
      'image':
          'https://images.unsplash.com/photo-1530224264768-7ff8c3749d17?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
      'action': 'Track Sleep',
      'type': 'sleep',
    },
    {
      'title': 'Workout Planner',
      'description': 'Plan your weekly workouts with ease.',
      'icon': Icons.fitness_center_rounded,
      'image':
          'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
      'action': 'Plan Workout',
      'type': 'workout',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showToolModal(String title, String type) {
    final TextEditingController _weightController = TextEditingController();
    final TextEditingController _heightController = TextEditingController();
    final TextEditingController _ageController = TextEditingController();
    final TextEditingController _waterController = TextEditingController();
    final TextEditingController _stepsController = TextEditingController();
    final TextEditingController _sleepController = TextEditingController();
    final TextEditingController _workoutController = TextEditingController();
    String? _gender;
    String? _activityLevel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 16.h,
              ).copyWith(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.raleway(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // Input fields based on calculator type
                    if (type == 'bmi') ...[
                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Weight (kg)',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          prefixIcon: Icon(
                            Icons.fitness_center_rounded,
                            color: AppTheme.primaryColor,
                            size: 24.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Height (cm)',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          prefixIcon: Icon(
                            Icons.height_rounded,
                            color: AppTheme.primaryColor,
                            size: 24.sp,
                          ),
                        ),
                      ),
                    ] else if (type == 'body_fat') ...[
                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Weight (kg)',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          prefixIcon: Icon(
                            Icons.fitness_center_rounded,
                            color: AppTheme.primaryColor,
                            size: 24.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Height (cm)',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          prefixIcon: Icon(
                            Icons.height_rounded,
                            color: AppTheme.primaryColor,
                            size: 24.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Age',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          prefixIcon: Icon(
                            Icons.cake_rounded,
                            color: AppTheme.primaryColor,
                            size: 24.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        hint: Text(
                          'Select Gender',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        items:
                            ['Male', 'Female'].map((gender) {
                              return DropdownMenuItem(
                                value: gender,
                                child: Text(
                                  gender,
                                  style: GoogleFonts.poppins(fontSize: 14.sp),
                                ),
                              );
                            }).toList(),
                        onChanged:
                            (value) => setModalState(() => _gender = value),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                      ),
                    ] else if (type == 'water') ...[
                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Weight (kg)',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          prefixIcon: Icon(
                            Icons.fitness_center_rounded,
                            color: AppTheme.primaryColor,
                            size: 24.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      DropdownButtonFormField<String>(
                        value: _activityLevel,
                        hint: Text(
                          'Select Activity Level',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        items:
                            ['Low', 'Moderate', 'High'].map((level) {
                              return DropdownMenuItem(
                                value: level,
                                child: Text(
                                  level,
                                  style: GoogleFonts.poppins(fontSize: 14.sp),
                                ),
                              );
                            }).toList(),
                        onChanged:
                            (value) =>
                                setModalState(() => _activityLevel = value),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                      ),
                    ] else if (type == 'steps') ...[
                      TextField(
                        controller: _stepsController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Steps per day',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          prefixIcon: Icon(
                            Icons.directions_walk_rounded,
                            color: AppTheme.primaryColor,
                            size: 24.sp,
                          ),
                        ),
                      ),
                    ] else if (type == 'sleep') ...[
                      TextField(
                        controller: _sleepController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Sleep hours per night',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          prefixIcon: Icon(
                            Icons.bedtime_rounded,
                            color: AppTheme.primaryColor,
                            size: 24.sp,
                          ),
                        ),
                      ),
                    ] else if (type == 'workout') ...[
                      TextField(
                        controller: _workoutController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Workouts per week',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          prefixIcon: Icon(
                            Icons.fitness_center_rounded,
                            color: AppTheme.primaryColor,
                            size: 24.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      DropdownButtonFormField<String>(
                        value: _activityLevel,
                        hint: Text(
                          'Select Workout Intensity',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        items:
                            ['Beginner', 'Intermediate', 'Advanced'].map((
                              level,
                            ) {
                              return DropdownMenuItem(
                                value: level,
                                child: Text(
                                  level,
                                  style: GoogleFonts.poppins(fontSize: 14.sp),
                                ),
                              );
                            }).toList(),
                        onChanged:
                            (value) =>
                                setModalState(() => _activityLevel = value),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          String? result;
                          String? details;
                          Color? resultColor;
                          IconData? resultIcon;

                          // Validate inputs and calculate results
                          if (type == 'bmi') {
                            final weight = double.tryParse(
                              _weightController.text,
                            );
                            final height = double.tryParse(
                              _heightController.text,
                            );
                            if (weight == null ||
                                height == null ||
                                weight <= 0 ||
                                height <= 0) {
                              result = 'Invalid Input';
                              details = 'Please enter valid weight and height';
                              resultColor = Colors.red;
                              resultIcon = Icons.error_outline_rounded;
                            } else {
                              final bmi = weight / pow(height / 100, 2);
                              String status;
                              Color statusColor;
                              if (bmi < 18.5) {
                                status = 'Underweight';
                                statusColor = Colors.orange;
                              } else if (bmi < 25) {
                                status = 'Normal';
                                statusColor = Colors.green;
                              } else if (bmi < 30) {
                                status = 'Overweight';
                                statusColor = Colors.orange;
                              } else {
                                status = 'Obese';
                                statusColor = Colors.red;
                              }
                              result = 'Your BMI Result';
                              details = '${bmi.toStringAsFixed(1)} ($status)';
                              resultColor = statusColor;
                              resultIcon = Icons.health_and_safety_rounded;
                            }
                          } else if (type == 'body_fat') {
                            final weight = double.tryParse(
                              _weightController.text,
                            );
                            final height = double.tryParse(
                              _heightController.text,
                            );
                            final age = int.tryParse(_ageController.text);
                            if (weight == null ||
                                height == null ||
                                age == null ||
                                _gender == null ||
                                weight <= 0 ||
                                height <= 0 ||
                                age <= 0) {
                              result = 'Invalid Input';
                              details =
                                  'Please enter valid weight, height, age, and gender';
                              resultColor = Colors.red;
                              resultIcon = Icons.error_outline_rounded;
                            } else {
                              final bmi = weight / pow(height / 100, 2);
                              // Simplified Jackson-Pollock formula for body fat
                              double bodyFat;
                              if (_gender == 'Male') {
                                bodyFat = (1.20 * bmi) + (0.23 * age) - 16.2;
                              } else {
                                bodyFat = (1.20 * bmi) + (0.23 * age) - 5.4;
                              }

                              String status;
                              Color statusColor;
                              if (_gender == 'Male') {
                                if (bodyFat < 6) {
                                  status = 'Essential fat';
                                  statusColor = Colors.blue;
                                } else if (bodyFat < 14) {
                                  status = 'Athletic';
                                  statusColor = Colors.green;
                                } else if (bodyFat < 18) {
                                  status = 'Fitness';
                                  statusColor = Colors.lightGreen;
                                } else if (bodyFat < 25) {
                                  status = 'Average';
                                  statusColor = Colors.orange;
                                } else {
                                  status = 'Obese';
                                  statusColor = Colors.red;
                                }
                              } else {
                                if (bodyFat < 14) {
                                  status = 'Essential fat';
                                  statusColor = Colors.blue;
                                } else if (bodyFat < 21) {
                                  status = 'Athletic';
                                  statusColor = Colors.green;
                                } else if (bodyFat < 25) {
                                  status = 'Fitness';
                                  statusColor = Colors.lightGreen;
                                } else if (bodyFat < 32) {
                                  status = 'Average';
                                  statusColor = Colors.orange;
                                } else {
                                  status = 'Obese';
                                  statusColor = Colors.red;
                                }
                              }

                              result = 'Body Fat Percentage';
                              details =
                                  '${bodyFat.toStringAsFixed(1)}% ($status)';
                              resultColor = statusColor;
                              resultIcon = Icons.pie_chart_rounded;
                            }
                          } else if (type == 'water') {
                            final weight = double.tryParse(
                              _weightController.text,
                            );
                            if (weight == null ||
                                weight <= 0 ||
                                _activityLevel == null) {
                              result = 'Invalid Input';
                              details =
                                  'Please enter valid weight and activity level';
                              resultColor = Colors.red;
                              resultIcon = Icons.error_outline_rounded;
                            } else {
                              double water =
                                  weight * 0.033; // Base: 33ml per kg
                              if (_activityLevel == 'Moderate') water *= 1.2;
                              if (_activityLevel == 'High') water *= 1.5;

                              result = 'Recommended Water Intake';
                              details =
                                  '${(water * 1000).toStringAsFixed(0)} ml per day';
                              resultColor = Colors.blue;
                              resultIcon = Icons.water_drop_rounded;
                            }
                          } else if (type == 'steps') {
                            final steps = int.tryParse(_stepsController.text);
                            if (steps == null || steps < 0) {
                              result = 'Invalid Input';
                              details = 'Please enter valid steps';
                              resultColor = Colors.red;
                              resultIcon = Icons.error_outline_rounded;
                            } else {
                              String status =
                                  steps >= 10000
                                      ? 'Great job!'
                                      : 'Keep moving!';
                              Color statusColor =
                                  steps >= 10000 ? Colors.green : Colors.orange;

                              result = 'Daily Step Goal';
                              details = '$steps steps ($status)';
                              resultColor = statusColor;
                              resultIcon = Icons.directions_walk_rounded;
                            }
                          } else if (type == 'sleep') {
                            final sleep = double.tryParse(
                              _sleepController.text,
                            );
                            if (sleep == null || sleep < 0) {
                              result = 'Invalid Input';
                              details = 'Please enter valid sleep hours';
                              resultColor = Colors.red;
                              resultIcon = Icons.error_outline_rounded;
                            } else {
                              String status =
                                  sleep >= 7 && sleep <= 9
                                      ? 'Optimal'
                                      : 'Needs adjustment';
                              Color statusColor =
                                  sleep >= 7 && sleep <= 9
                                      ? Colors.green
                                      : Colors.orange;

                              result = 'Sleep Duration';
                              details =
                                  '${sleep.toStringAsFixed(1)} hours ($status)';
                              resultColor = statusColor;
                              resultIcon = Icons.bedtime_rounded;
                            }
                          } else if (type == 'workout') {
                            final workouts = int.tryParse(
                              _workoutController.text,
                            );
                            if (workouts == null ||
                                workouts < 0 ||
                                _activityLevel == null) {
                              result = 'Invalid Input';
                              details =
                                  'Please enter valid workouts and intensity';
                              resultColor = Colors.red;
                              resultIcon = Icons.error_outline_rounded;
                            } else {
                              result = 'Workout Plan Created';
                              details =
                                  '$workouts sessions/week ($_activityLevel intensity)';
                              resultColor = AppTheme.primaryColor;
                              resultIcon = Icons.fitness_center_rounded;
                            }
                          }

                          Navigator.pop(context);
                          _showResultPopup(
                            context: context,
                            title: title,
                            result: result!,
                            details: details!,
                            color: resultColor!,
                            icon: resultIcon!,
                          );

                          // Clear controllers
                          _weightController.clear();
                          _heightController.clear();
                          _ageController.clear();
                          _waterController.clear();
                          _stepsController.clear();
                          _sleepController.clear();
                          _workoutController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                          shadowColor: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                        child: Text(
                          'Calculate',
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showResultPopup({
    required BuildContext context,
    required String title,
    required String result,
    required String details,
    required Color color,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 40.sp, color: color),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    result,
                    style: GoogleFonts.raleway(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    details,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Got it!',
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 8.w),
                        Text(
                          'Fitness Tools',
                          style: GoogleFonts.raleway(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Tool List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                itemCount: _tools.length,
                itemBuilder: (context, index) {
                  final tool = _tools[index];
                  return SlideTransition(
                    position: _slideAnimation,
                    child: _buildToolCard(
                      title: tool['title'],
                      description: tool['description'],
                      icon: tool['icon'],
                      image: tool['image'],
                      action: tool['action'],
                      type: tool['type'],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required String description,
    required IconData icon,
    required String image,
    required String action,
    required String type,
  }) {
    bool isTapped = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => isTapped = true),
          onTapUp: (_) {
            setState(() => isTapped = false);
            _showToolModal(title, type);
          },
          onTapCancel: () => setState(() => isTapped = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(isTapped ? 0.98 : 1.0),
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16.r),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: image,
                        height: 140.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.fitness_center_rounded,
                                size: 50.sp,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                      ),
                    ),
                    Container(
                      height: 140.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16.r),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.2),
                            AppTheme.primaryColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        backgroundColor: Colors.grey.shade50,
                        child:
                            Icon(
                              icon,
                              size: 24.sp,
                              color: AppTheme.primaryColor,
                            ).animate(),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.raleway(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              description,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8.h),
                            GestureDetector(
                              onTap: () => _showToolModal(title, type),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: AppTheme.primaryColor,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  action,
                                  style: GoogleFonts.raleway(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
