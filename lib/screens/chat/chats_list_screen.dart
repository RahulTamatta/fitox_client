import '../../providers/chat_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _userId;

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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );
    _animationController.forward();

    // Fetch userId and chats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserIdAndChats();
    });
  }

  Future<void> _fetchUserIdAndChats() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.isAuthenticated && authProvider.user != null) {
        _userId = authProvider.user!['_id'] ?? authProvider.user!['id'];
        if (kDebugMode) {
          debugPrint('Retrieved userId from AuthProvider: $_userId');
        }

        if (_userId != null && _userId!.isNotEmpty) {
          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
          await chatProvider.loadUserChats(_userId!);
          if (kDebugMode) {
            debugPrint('User Chats loaded');
          }
        }
      } else {
        debugPrint('Error: User not authenticated or user data not available');
      }
    } catch (e) {
      debugPrint('Error fetching userId or chats: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return Column(
                children: [
                  _buildAppBar(),
                  if (chatProvider.isLoading) const LinearProgressIndicator(),
                  if (chatProvider.errorMessage != null)
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        chatProvider.errorMessage!,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                  if (_userId == null)
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        'User ID not found. Please log in again.',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                  Expanded(child: _buildChatList(chatProvider)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(width: 10.w),
                Text(
                  'Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(ChatProvider chatProvider) {
    if (kDebugMode) {
      debugPrint('📋 [ChatListScreen] Building chat list with ${chatProvider.chatSummaries.length} summaries');
      debugPrint('📋 [ChatListScreen] Chat summaries: ${chatProvider.chatSummaries}');
    }
    
    final chats = chatProvider.chatSummaries.map((summary) {
      return {
        'name': summary['otherUserName'] ?? 'Unknown User',
        'lastMessage': summary['lastMessage'] ?? 'No messages yet',
        'time': _formatTimestamp(summary['lastMessageTime']),
        'unreadCount': summary['unreadCount'] ?? 0,
        'avatarIcon': Icons.fitness_center_rounded,
        'isOnline': false,
        'isTrainer': true,
        'chatId': summary['chatId'],
        'otherUserId': summary['otherUserId'],
        'otherUserImage': summary['otherUserImage'],
      };
    }).toList();

    return SlideTransition(
      position: _slideAnimation,
      child:
          chats.isEmpty
              ? Center(
                child: Text(
                  'No chats available',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
              : ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                itemCount: chats.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return _buildChatItem(
                    name: chat['name'],
                    lastMessage: chat['lastMessage'],
                    time: chat['time'],
                    unreadCount: chat['unreadCount'],
                    avatarIcon: chat['avatarIcon'],
                    isOnline: chat['isOnline'],
                    isTrainer: chat['isTrainer'],
                    chatId: chat['chatId'],
                    chat: chat,
                  );
                },
              ),
    );
  }

  Widget _buildChatItem({
    required String name,
    required String lastMessage,
    required String time,
    required int unreadCount,
    required IconData avatarIcon,
    required bool isOnline,
    required bool isTrainer,
    required String chatId,
    required Map<String, dynamic> chat,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => ChatScreen(
                  chatId: chatId,
                  userId: chat['otherUserId'] ?? '',
                  userName: chat['name'],
                  userImage: chat['otherUserImage'],
                ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28.w,
                  backgroundImage: chat['otherUserImage'] != null && chat['otherUserImage'].isNotEmpty
                      ? NetworkImage(chat['otherUserImage'])
                      : null,
                  backgroundColor: isTrainer
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  child: chat['otherUserImage'] == null || chat['otherUserImage'].isEmpty
                      ? Icon(
                          avatarIcon,
                          size: 28.sp,
                          color: isTrainer
                              ? AppTheme.primaryColor
                              : Colors.grey.shade700,
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14.w,
                      height: 14.w,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.w),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
      final displayHour = hour == 0 ? 12 : hour;
      return '$displayHour:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][timestamp.weekday - 1];
    } else {
      return 'Last week';
    }
  }
}
