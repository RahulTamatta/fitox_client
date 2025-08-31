import 'package:fit_talk/screens/account/provider/profile_provider.dart';
import 'package:fit_talk/screens/account/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../themes/app_theme.dart';
import '../auth/login_screen.dart'; // Adjust import based on your project

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch profile data when the screen loads using userId from SharedPreferences
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final userId =
          prefs.getString('user_id') ??
          '6818873648f2288bd818501f'; // Fallback userId
      Provider.of<ProfileProvider>(
        context,
        listen: false,
      ).getProfileInfo(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          final state = provider.getState;
          final error = provider.getErrorMessage;
          final profile = provider.getUserProfile;

          if (state == ResponseState.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state == ResponseState.error && error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final userId =
                          prefs.getString('user_id') ??
                          '6818873648f2288bd818501f';
                      Provider.of<ProfileProvider>(
                        context,
                        listen: false,
                      ).getProfileInfo(userId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state == ResponseState.success && profile != null) {
            return _buildAccountContent(context, profile);
          } else {
            return const Center(child: Text('No profile data available'));
          }
        },
      ),
    );
  }

  // Main content with profile data
  Widget _buildAccountContent(
    BuildContext context,
    Map<String, dynamic> profile,
  ) {
    final isTrainer = profile['role'] == 'trainer';

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(
              context,
              profile,
            ).animate().fadeIn(duration: 600.ms),
            SizedBox(height: 24.h),
            _buildProgressCard(
              profile,
            ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms),
            SizedBox(height: 24.h),
            _buildSectionHeader("Account Settings"),
            SizedBox(height: 16.h),
            _buildSettingsList(
              context,
              isTrainer,
            ).animate().fadeIn(duration: 600.ms),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  // Profile Header with Avatar and User Info
  Widget _buildProfileHeader(
    BuildContext context,
    Map<String, dynamic> profile,
  ) {
    final isTrainer = profile['role'] == 'trainer';
    final name = profile['name'] ?? 'Unknown';
    final bio =
        profile['bio'] ??
        (isTrainer ? 'Fitness Trainer' : 'Fitness Enthusiast');
    final profileImage =
        profile['profileImage'].isNotEmpty
            ? profile['profileImage']
            : 'https://picsum.photos/200'; // Fallback to picsum.photos

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CachedNetworkImage(
                imageUrl: profileImage,
                imageBuilder:
                    (context, imageProvider) => CircleAvatar(
                      radius: 40.r,
                      backgroundImage: imageProvider,
                    ),
                placeholder:
                    (context, url) => CircleAvatar(
                      radius: 40.r,
                      child: CircularProgressIndicator(strokeWidth: 2.w),
                    ),
                errorWidget:
                    (context, url, error) => CircleAvatar(
                      radius: 40.r,
                      backgroundImage: const AssetImage(
                        'assets/images/default_profile.png',
                      ),
                    ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      bio,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    if (isTrainer && profile['tagline'] != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        profile['tagline'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  // Navigate to edit profile screen
                },
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Icon(
                    Symbols.edit_rounded,
                    color: Colors.white,
                    size: 20.sp,
                    weight: 700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProfileStat("Workouts", "${profile['workouts'] ?? 0}"),
              _buildProfileStat("Followers", "${profile['followers'] ?? 0}"),
              _buildProfileStat("Goals", "${profile['goals'] ?? '0/0'}"),
            ],
          ),
          if (isTrainer) ...[
            SizedBox(height: 16.h),
            _buildTrainerInfo(profile),
          ],
        ],
      ),
    );
  }

  // Trainer-specific info (experience, occupation, timings)
  Widget _buildTrainerInfo(Map<String, dynamic> profile) {
    final experience = profile['experience'] ?? 0;
    final currentOccupation = profile['currentOccupation'] ?? 'N/A';
    final availableTimings =
        (profile['availableTimings'] as List<dynamic>?)?.join(', ') ?? 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Trainer Details",
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          "Experience: $experience years",
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        Text(
          "Occupation: $currentOccupation",
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        Text(
          "Available: $availableTimings",
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  // Profile Stat Widget
  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // Progress Card for Fitness Goals
  Widget _buildProgressCard(Map<String, dynamic> profile) {
    final goals = profile['goals']?.split('/') ?? ['0', '0'];
    final completed = int.tryParse(goals[0]) ?? 0;
    final total = int.tryParse(goals[1]) ?? 1;
    final progress = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90.w,
                  height: 90.h,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10.w,
                    color: AppTheme.accentColor,
                    backgroundColor: Colors.grey.shade100,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  "${(progress * 100).toStringAsFixed(0)}%",
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ).animate().scale(duration: 800.ms),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Fitness Goal Progress",
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "You're ${(progress * 100).toStringAsFixed(0)}% closer to your goal! Keep pushing!",
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "View Details",
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Settings List
  Widget _buildSettingsList(BuildContext context, bool isTrainer) {
    final settings = [
      {
        "icon": Symbols.person_rounded,
        "title": "Personal Information",
        "action": () {},
      },
      {
        "icon": Symbols.notifications_rounded,
        "title": "Notifications",
        "action": () {},
      },
      {
        "icon": Symbols.lock_rounded,
        "title": "Privacy & Security",
        "action": () {},
      },
      {
        "icon": Symbols.credit_card_rounded,
        "title": "Payment Methods",
        "action": () {},
      },
      if (isTrainer) ...[
        {
          "icon": Symbols.work_rounded,
          "title": "Trainer Settings",
          "action": () {},
        },
      ],
      {"icon": Symbols.favorite_rounded, "title": "Favorites", "action": () {}},
      {
        "icon": Symbols.logout_rounded,
        "title": "Log Out",
        "action": () => _showLogoutDialog(context),
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children:
            settings.asMap().entries.map((entry) {
              final index = entry.key;
              final setting = entry.value;
              return InkWell(
                    onTap: setting["action"] as VoidCallback,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.accentColor.withOpacity(0.2),
                                  AppTheme.primaryColor.withOpacity(0.2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              setting["icon"] as IconData,
                              color: AppTheme.primaryColor,
                              size: 24.sp,
                              weight: 700,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Text(
                              setting["title"] as String,
                              style: GoogleFonts.nunito(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Icon(
                            Symbols.arrow_forward_ios_rounded,
                            color: Colors.grey.shade400,
                            size: 16.sp,
                            weight: 700,
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .slideX(
                    begin: 0.2,
                    end: 0,
                    delay: (100 * index).ms,
                    duration: 400.ms,
                  )
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                  );
            }).toList(),
      ),
    );
  }

  // Logout Confirmation Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            backgroundColor: Colors.white,
            title: Text(
              "Log Out",
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            content: Text(
              "Are you sure you want to log out?",
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('auth_token');
                  await prefs.remove('user_id');
                  Provider.of<ProfileProvider>(context, listen: false).reset();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: Text(
                  "Log Out",
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
