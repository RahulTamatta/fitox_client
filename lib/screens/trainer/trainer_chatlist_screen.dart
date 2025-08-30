import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../themes/app_theme.dart';
import 'trainer_chat_screen.dart';

class TrainerChatsListScreen extends StatelessWidget {
  TrainerChatsListScreen({super.key});

  // Mock chats data
  final List<Map<String, dynamic>> chats = [
    {
      'userName': 'John Doe',
      'lastMessage': 'Great session today!',
      'time': '10:30 AM',
      'userImage': 'https://picsum.photos/200',
      'chatId': 'chat_001',
      'userId': 'user_001',
    },
    {
      'userName': 'Jane Smith',
      'lastMessage': 'Can we reschedule tomorrow?',
      'time': '9:15 AM',
      'userImage': 'https://picsum.photos/201',
      'chatId': 'chat_002',
      'userId': 'user_002',
    },
    {
      'userName': 'Mike Johnson',
      'lastMessage': 'Need diet advice!',
      'time': 'Yesterday',
      'userImage': 'https://picsum.photos/202',
      'chatId': 'chat_003',
      'userId': 'user_003',
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
          "All Chats",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Column(
            children: [
              // Search Bar
              _buildSearchBar(),
              SizedBox(height: 16.h),
              // Chat List
              Expanded(
                child:
                    chats.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 16.h,
                          ),
                          itemCount: chats.length,
                          itemBuilder: (context, index) {
                            final chat = chats[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => TrainerChatScreen(
                                          chatId: chat['chatId'],
                                          userId: chat['userId'],
                                          userName: chat['userName'],
                                          userImage: chat['userImage'],
                                        ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12.r),
                              child: Container(
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
                                      imageUrl: chat['userImage'],
                                      imageBuilder:
                                          (context, imageProvider) =>
                                              CircleAvatar(
                                                radius: 24.r,
                                                backgroundImage: imageProvider,
                                              ),
                                      placeholder:
                                          (context, url) => CircleAvatar(
                                            radius: 24.r,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.w,
                                            ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chat['userName'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            chat['lastMessage'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.sp,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      chat['time'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.sp,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(
                              delay: (100 * index).ms,
                              duration: 400.ms,
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: "Search chats...",
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 13.sp,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey.shade500,
              size: 22.sp,
            ),
            suffixIcon: Container(
              margin: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.tune_rounded, color: Colors.white, size: 18.sp),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14.h),
          ),
          style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.black87),
          onChanged: (value) {
            // Placeholder for search functionality
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 40.sp,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 8.h),
          Text(
            "No chats available",
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
