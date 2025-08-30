import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../themes/app_theme.dart';

class TrainerCallManagementScreen extends StatefulWidget {
  const TrainerCallManagementScreen({super.key});

  @override
  State<TrainerCallManagementScreen> createState() =>
      _TrainerCallManagementScreenState();
}

class _TrainerCallManagementScreenState
    extends State<TrainerCallManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mock call history data
  final List<Map<String, dynamic>> audioCalls = [
    {
      'userName': 'John Doe',
      'time': '10:30 AM, Jul 19, 2025',
      'duration': '15 min',
      'userImage': 'https://picsum.photos/200',
    },
    {
      'userName': 'Jane Smith',
      'time': '9:15 AM, Jul 18, 2025',
      'duration': '20 min',
      'userImage': 'https://picsum.photos/201',
    },
  ];

  final List<Map<String, dynamic>> videoCalls = [
    {
      'userName': 'Mike Johnson',
      'time': '2:00 PM, Jul 19, 2025',
      'duration': '30 min',
      'userImage': 'https://picsum.photos/202',
    },
    {
      'userName': 'Sarah Wilson',
      'time': '11:45 AM, Jul 18, 2025',
      'duration': '25 min',
      'userImage': 'https://picsum.photos/203',
    },
  ];

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
          "Call Management",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
          tabs: const [Tab(text: "Audio Calls"), Tab(text: "Video Calls")],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCallList(audioCalls, "No audio calls yet"),
            _buildCallList(videoCalls, "No video calls yet"),
          ],
        ),
      ),
    );
  }

  Widget _buildCallList(List<Map<String, dynamic>> calls, String emptyMessage) {
    if (calls.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CachedNetworkImage(
                imageUrl: call['userImage'],
                imageBuilder:
                    (context, imageProvider) => CircleAvatar(
                      radius: 24.r,
                      backgroundImage: imageProvider,
                    ),
                placeholder:
                    (context, url) => CircleAvatar(
                      radius: 24.r,
                      child: CircularProgressIndicator(strokeWidth: 2.w),
                    ),
                errorWidget:
                    (context, url, error) => CircleAvatar(
                      radius: 24.r,
                      backgroundImage: const AssetImage(
                        'assets/images/default_profile.png',
                      ),
                    ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call['userName'],
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Duration: ${call['duration']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      call['time'],
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  // Placeholder for re-initiating call
                },
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    "Call Again",
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (100 * index).ms, duration: 400.ms);
      },
    );
  }
}
