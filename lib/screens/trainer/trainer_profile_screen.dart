import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:fit_talk/services/auth_service.dart';
import '../../themes/app_theme.dart';
import '../../providers/call_provider.dart';
import '../../providers/subscription_provider.dart';
import '../auth/login_screen.dart';
import '../call/call_screen.dart';
import '../chat/chat_screen.dart';

class TrainerProfileScreen extends StatefulWidget {
  final String? trainerId; // Pass actual trainer ID
  
  const TrainerProfileScreen({super.key, this.trainerId});

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  // Mock profile data - in real app, fetch from backend using widget.trainerId
  final Map<String, dynamic> profile = {
    'id': '507f1f77bcf86cd799439011', // MongoDB ObjectId format
    'uId': 123456, // Numeric uId from backend
    'name': 'Alex Trainer',
    'profileImage':
        'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b',
    'tagline': 'Empowering Fitness Journeys',
    'bio':
        'Certified fitness trainer with 8 years of experience specializing in strength training and nutrition.',
    'experience': '8 years',
    'occupation': 'Head Trainer at FitCore Gym',
    'availableTimings': ['Mon-Fri: 6 AM - 8 PM', 'Sat: 8 AM - 2 PM'],
    'clients': 120,
    'sessions': 350,
    'rating': 4.8,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(context).animate().fadeIn(duration: 600.ms),
              SizedBox(height: 16.h),
              _buildProfileDetails(
                context,
              ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms),
              SizedBox(height: 24.h),
              _buildActionButtons(context).animate().fadeIn(duration: 600.ms),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'trainer_avatar',
            child: CachedNetworkImage(
              imageUrl: profile['profileImage'],
              imageBuilder:
                  (context, imageProvider) => CircleAvatar(
                    radius: 50.r,
                    backgroundImage: imageProvider,
                  ),
              placeholder:
                  (context, url) => CircleAvatar(
                    radius: 50.r,
                    child: CircularProgressIndicator(strokeWidth: 2.w),
                  ),
              errorWidget:
                  (context, url, error) => CircleAvatar(
                    radius: 50.r,
                    backgroundImage: const AssetImage(
                      'assets/images/default_profile.png',
                    ),
                  ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            profile['name'],
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            profile['tagline'],
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat("Clients", "${profile['clients']}"),
              _buildStat("Sessions", "${profile['sessions']}"),
              _buildStat("Rating", "${profile['rating']}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "About Me",
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              profile['bio'],
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Experience",
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              profile['experience'],
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Occupation",
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              profile['occupation'],
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Availability",
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            ...profile['availableTimings']
                .map<Widget>(
                  (timing) => Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      timing,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          // Call buttons row
          Row(
            children: [
              Expanded(
                child: _buildCallButton(
                  context: context,
                  icon: Symbols.call,
                  label: "Audio Call",
                  onTap: () => _initiateCall(context, CallType.audio),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildCallButton(
                  context: context,
                  icon: Symbols.videocam,
                  label: "Video Call",
                  onTap: () => _initiateCall(context, CallType.video),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // Message button
          InkWell(
            onTap: () => _openChat(context),
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.chat, size: 22.sp, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text(
                    "Message",
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          
          // Edit Profile button
          InkWell(
            onTap: () {
              // Placeholder for edit profile
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.edit_rounded, size: 22.sp, color: AppTheme.primaryColor),
                  SizedBox(width: 8.w),
                  Text(
                    "Edit Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          
          // Logout button
          InkWell(
            onTap: () {
              _showLogoutDialog(context);
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.logout_rounded, size: 22.sp, color: Colors.red),
                  SizedBox(width: 8.w),
                  Text(
                    "Log Out",
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 24.sp, color: Colors.white),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateCall(BuildContext context, CallType callType) async {
    try {
      final auth = AuthService();
      final user = await auth.getCurrentUser();
      final currentUserId = (user?['_id'] ?? user?['id'])?.toString();
      
      if (currentUserId == null) {
        _showErrorSnackBar(context, 'Please log in to make calls');
        return;
      }

      // Check subscription
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.checkSubscription(currentUserId);
      
      if (!subscriptionProvider.isActive) {
        _showSubscriptionDialog(context);
        return;
      }

      // Navigate to call screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            calleeId: profile['id'], // Use actual trainer ID
            calleeName: profile['name'],
            callType: callType,
            calleeImage: profile['profileImage'],
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to initiate call: $e');
    }
  }

  Future<void> _openChat(BuildContext context) async {
    try {
      final auth = AuthService();
      final user = await auth.getCurrentUser();
      final currentUserId = (user?['_id'] ?? user?['id'])?.toString();
      
      if (currentUserId == null) {
        _showErrorSnackBar(context, 'Please log in to chat');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: 'chat_${currentUserId}_${profile['id']}',
            userId: profile['id'], // Use actual trainer ID
            userName: profile['name'],
            userImage: profile['profileImage'],
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to open chat: $e');
    }
  }

  void _showSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        backgroundColor: Colors.white,
        title: Text(
          "Subscription Required",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Text(
          "You need an active subscription to make calls. Please subscribe to continue.",
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription screen
            },
            child: Text(
              "Subscribe",
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            backgroundColor: Colors.white,
            title: Text(
              "Log Out",
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            content: Text(
              "Are you sure you want to log out?",
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
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
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
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
