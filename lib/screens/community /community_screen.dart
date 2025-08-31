import 'package:fit_talk/screens/community%20/services/community_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:provider/provider.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _blogTitleController = TextEditingController(
    text: '',
  );
  final TextEditingController _blogContentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final CommunityService _communityService = CommunityService();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _page = 1;
  String? _userId;
  String? _role;

  final List<String> _categories = [
    'All',
    'Fitness',
    'Nutrition',
    'Yoga',
    'Wellness',
    'Recipes',
  ];
  int _selectedCategoryIndex = 0;
  List<Map<String, dynamic>> _blogs = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _fetchBlogs();
    _loadUserData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoadingMore) {
        _loadMoreBlogs();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userRole = prefs.getString('userRole');
      
      if (kDebugMode) {
        debugPrint('Loading user data - userId: $userId, role: $userRole');
      }
      
      if (userId != null && userId.isNotEmpty) {
        setState(() {
          _userId = userId;
          _role = userRole ?? 'user';
        });
      } else {
        if (kDebugMode) {
          debugPrint('No userId found in SharedPreferences');
        }
        // Handle case where user is not logged in
        setState(() {
          _userId = null;
          _role = 'user';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading user data: $e');
      }
      setState(() {
        _userId = null;
        _role = 'user';
      });
    }
  }

  Future<void> _fetchBlogs({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _blogs.clear();
        _page = 1;
      });
    }
    setState(() => _isLoading = true);
    final category = _categories[_selectedCategoryIndex];
    final response = await _communityService.getBlogs(
      category: category == 'All' ? null : category,
      page: _page,
    );
    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      setState(() {
        _blogs.addAll(
          (response.data as List)
              .map(
                (blog) => {
                  '_id': blog['_id'] ?? '',
                  'title': blog['title'] ?? 'Untitled',
                  'author': blog['author']?['name'] ?? 'Unknown',
                  'authorImage':
                      blog['author']?['profileImage']?.isNotEmpty == true
                          ? blog['author']['profileImage']
                          : 'https://randomuser.me/api/portraits/men/1.jpg',
                  'image':
                      blog['image']?.isNotEmpty == true
                          ? blog['image']
                          : 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438',
                  'likes': blog['likes'] ?? 0,
                  'comments': blog['comments']?.length ?? 0,
                  'time': _formatTime(blog['createdAt']),
                  'category': blog['category'] ?? 'Fitness',
                  'isBookmarked': false,
                  'isLiked': blog['likedBy']?.contains(_userId) ?? false,
                  'content': blog['content'] ?? '',
                },
              )
              .toList(),
        );
      });
    } else {
      _showSnackBar(response.message, isError: true);
    }
  }

  Future<void> _loadMoreBlogs() async {
    setState(() => _isLoadingMore = true);
    _page++;
    final category = _categories[_selectedCategoryIndex];
    final response = await _communityService.getBlogs(
      category: category == 'All' ? null : category,
      page: _page,
    );
    setState(() => _isLoadingMore = false);

    if (response.success && response.data != null) {
      setState(() {
        _blogs.addAll(
          (response.data as List)
              .map(
                (blog) => {
                  '_id': blog['_id'] ?? '',
                  'title': blog['title'] ?? 'Untitled',
                  'author': blog['author']?['name'] ?? 'Unknown',
                  'authorImage':
                      blog['author']?['profileImage']?.isNotEmpty == true
                          ? blog['author']['profileImage']
                          : 'https://randomuser.me/api/portraits/men/1.jpg',
                  'image':
                      blog['image']?.isNotEmpty == true
                          ? blog['image']
                          : 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438',
                  'likes': blog['likes'] ?? 0,
                  'comments': blog['comments']?.length ?? 0,
                  'time': _formatTime(blog['createdAt']),
                  'category': blog['category'] ?? 'Fitness',
                  'isBookmarked': false,
                  'isLiked': blog['likedBy']?.contains(_userId) ?? false,
                  'content': blog['content'] ?? '',
                },
              )
              .toList(),
        );
      });
    } else {
      _showSnackBar(response.message, isError: true);
      _page--;
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return 'Just now';
    final date = DateTime.parse(createdAt).toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? Colors.red : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showCreateBlogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setStateModal) => Padding(
                padding: EdgeInsets.only(
                  left: 24.w,
                  right: 24.w,
                  top: 16.h,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Create New Post',
                        style: GoogleFonts.raleway(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Title',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: _blogTitleController,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter a catchy title...',
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
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Content',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: _blogContentController,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText:
                              'Share your knowledge with the community...',
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
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Image (Optional)',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: () async {
                          await _pickImage();
                          setStateModal(() {});
                        },
                        child: Container(
                          height: 100.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child:
                              _selectedImage != null
                                  ? Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                  : Center(
                                    child: Text(
                                      'Tap to select image',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.sp,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () async {
                                    if (_blogTitleController.text.isEmpty ||
                                        _blogContentController.text.isEmpty) {
                                      _showSnackBar(
                                        'Please enter title and content',
                                        isError: true,
                                      );
                                      return;
                                    }
                                    if (_userId == null || _role == null) {
                                      _showSnackBar(
                                        'User not authenticated',
                                        isError: true,
                                      );
                                      return;
                                    }
                                    setState(() => _isLoading = true);
                                    print("::: Before ");
                                    final response = await _communityService
                                        .createBlog(
                                          title:
                                              _blogTitleController.text.trim(),
                                          content:
                                              _blogContentController.text
                                                  .trim(),
                                          userId: _userId!,
                                          role: _role!,
                                          image: _selectedImage,
                                        );
                                    setState(() => _isLoading = false);

                                    if (response.success) {
                                      Navigator.pop(context);
                                      _blogTitleController.clear();
                                      _blogContentController.clear();
                                      setState(() => _selectedImage = null);
                                      _fetchBlogs(isRefresh: true);
                                      _showSnackBar(
                                        'Blog posted successfully!',
                                      );
                                    } else {
                                      _showSnackBar(
                                        response.message,
                                        isError: true,
                                      );
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? SizedBox(
                                    width: 20.w,
                                    height: 20.h,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Publish Post',
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
              ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _blogTitleController.dispose();
    _blogContentController.dispose();
    _searchController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    _communityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: Colors.white,
                pinned: true,
                floating: true,
                title: Text(
                  'Community',
                  style: GoogleFonts.raleway(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Iconsax.search_normal,
                      size: 24.sp,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      Iconsax.notification,
                      size: 24.sp,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: () {},
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(100.h),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search posts, topics, people...',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade400,
                                ),
                                prefixIcon: Icon(
                                  Iconsax.search_normal,
                                  color: AppTheme.primaryColor,
                                  size: 20.sp,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14.h,
                                  horizontal: 16.w,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        height: 35.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: _categories.length,
                          itemBuilder:
                              (context, index) => Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(
                                      () => _selectedCategoryIndex = index,
                                    );
                                    _fetchBlogs(isRefresh: true);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 8.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _selectedCategoryIndex == index
                                              ? AppTheme.primaryColor
                                              : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color:
                                            _selectedCategoryIndex == index
                                                ? AppTheme.primaryColor
                                                : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      _categories[index],
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            _selectedCategoryIndex == index
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
        body: RefreshIndicator(
          onRefresh: () => _fetchBlogs(isRefresh: true),
          color: AppTheme.primaryColor,
          child:
              _isLoading && _blogs.isEmpty
                  ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                  : _blogs.isEmpty
                  ? Center(
                    child: Text(
                      'No blogs found',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    itemCount: _blogs.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _blogs.length) {
                        final blog = _blogs[index];
                        return _buildBlogCard(
                          title: blog['title'],
                          author: blog['author'],
                          authorImage: blog['authorImage'],
                          image: blog['image'],
                          likes: blog['likes'],
                          comments: blog['comments'],
                          time: blog['time'],
                          category: blog['category'],
                          isBookmarked: blog['isBookmarked'],
                          isLiked: blog['isLiked'],
                          blogId: blog['_id'],
                          index: index,
                        ).animate().fadeIn(delay: (100 * index).ms);
                      }
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBlogModal,
        backgroundColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Iconsax.edit, size: 24.sp, color: Colors.white),
      ).animate().scale(delay: 600.ms),
    );
  }

  Widget _buildBlogCard({
    required String title,
    required String author,
    required String authorImage,
    required String image,
    required int likes,
    required int comments,
    required String time,
    required String category,
    required bool isBookmarked,
    required bool isLiked,
    required String blogId,
    required int index,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: InkWell(
        onTap: () => _showBlogDetail(blogId, index),
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                child: CachedNetworkImage(
                  imageUrl: image,
                  height: 180.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Iconsax.image,
                          size: 40.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.raleway(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12.r,
                        backgroundImage: CachedNetworkImageProvider(
                          authorImage,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          author,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (_userId == null) {
                                _showSnackBar(
                                  'Please log in to like posts',
                                  isError: true,
                                );
                                return;
                              }
                              setState(() => _isLoading = true);
                              final response = await _communityService
                                  .toggleLikeBlog(
                                    blogId: blogId,
                                    userId: _userId!,
                                    isLiked: isLiked,
                                  );
                              setState(() => _isLoading = false);
                              if (response.success) {
                                setState(() {
                                  _blogs[index]['isLiked'] = !isLiked;
                                  _blogs[index]['likes'] =
                                      isLiked ? likes - 1 : likes + 1;
                                });
                              } else {
                                _showSnackBar(response.message, isError: true);
                              }
                            },
                            child: Row(
                              children: [
                                Icon(
                                  isLiked ? Iconsax.heart5 : Iconsax.heart,
                                  size: 20.sp,
                                  color:
                                      isLiked
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '$likes',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Row(
                            children: [
                              Icon(
                                Iconsax.message,
                                size: 20.sp,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '$comments',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          // Implement share functionality if needed
                          _showSnackBar('Share feature not implemented');
                        },
                        child: Icon(
                          Iconsax.share,
                          size: 20.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
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

  void _showBlogDetail(String blogId, int index) async {
    setState(() => _isLoading = true);
    final response = await _communityService.getBlogDetails(blogId);
    setState(() => _isLoading = false);

    if (!response.success || response.data == null) {
      _showSnackBar(
        'Failed to load blog details: ${response.message}',
        isError: true,
      );
      return;
    }

    final blog = response.data as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20.r,
                              backgroundImage: CachedNetworkImageProvider(
                                blog['author']?['profileImage']?.isNotEmpty ==
                                        true
                                    ? blog['author']['profileImage']
                                    : 'https://randomuser.me/api/portraits/men/1.jpg',
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  blog['author']?['name'] ?? 'Unknown',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _formatTime(blog['createdAt']),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                _blogs[index]['isBookmarked']
                                    ? Iconsax.bookmark_25
                                    : Iconsax.bookmark,
                                size: 24.sp,
                                color:
                                    _blogs[index]['isBookmarked']
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _blogs[index]['isBookmarked'] =
                                      !_blogs[index]['isBookmarked'];
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          blog['title'] ?? 'Untitled',
                          style: GoogleFonts.raleway(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        if (blog['image']?.isNotEmpty == true)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: CachedNetworkImage(
                              imageUrl: blog['image'],
                              width: double.infinity,
                              height: 200.h,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Iconsax.image,
                                      size: 40.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                            ),
                          ),
                        SizedBox(height: 16.h),
                        Text(
                          blog['content'] ?? 'No content available',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (_userId == null) {
                                  _showSnackBar(
                                    'Please log in to like posts',
                                    isError: true,
                                  );
                                  return;
                                }
                                setState(() => _isLoading = true);
                                final response = await _communityService
                                    .toggleLikeBlog(
                                      blogId: blogId,
                                      userId: _userId!,
                                      isLiked: _blogs[index]['isLiked'],
                                    );
                                setState(() => _isLoading = false);
                                if (response.success) {
                                  setState(() {
                                    _blogs[index]['isLiked'] =
                                        !_blogs[index]['isLiked'];
                                    _blogs[index]['likes'] =
                                        _blogs[index]['isLiked']
                                            ? _blogs[index]['likes'] + 1
                                            : _blogs[index]['likes'] - 1;
                                  });
                                } else {
                                  _showSnackBar(
                                    response.message,
                                    isError: true,
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    _blogs[index]['isLiked']
                                        ? Iconsax.heart5
                                        : Iconsax.heart,
                                    size: 24.sp,
                                    color:
                                        _blogs[index]['isLiked']
                                            ? Colors.red
                                            : Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '${_blogs[index]['likes']} Likes',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.message,
                                  size: 24.sp,
                                  color: Colors.grey.shade600,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '${blog['comments']?.length ?? 0} Comments',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Add a Comment',
                          style: GoogleFonts.raleway(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16.r,
                              backgroundImage: CachedNetworkImageProvider(
                                'https://randomuser.me/api/portraits/men/1.jpg', // Replace with user profile image
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: 'Write a comment...',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Iconsax.send_2,
                                size: 24.sp,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: () async {
                                if (_commentController.text.isEmpty ||
                                    _userId == null) {
                                  _showSnackBar(
                                    'Please enter a comment and log in',
                                    isError: true,
                                  );
                                  return;
                                }
                                setState(() => _isLoading = true);
                                final response = await _communityService
                                    .postComment(
                                      blogId: blogId,
                                      userId: _userId!,
                                      commentText:
                                          _commentController.text.trim(),
                                    );
                                setState(() => _isLoading = false);
                                if (response.success) {
                                  _commentController.clear();
                                  _showSnackBar('Comment posted successfully!');
                                  // Refresh blog details
                                  final updatedResponse =
                                      await _communityService.getBlogDetails(
                                        blogId,
                                      );
                                  if (updatedResponse.success &&
                                      updatedResponse.data != null) {
                                    setState(() {
                                      _blogs[index]['comments'] =
                                          updatedResponse
                                              .data['comments']
                                              ?.length ??
                                          0;
                                    });
                                  }
                                } else {
                                  _showSnackBar(
                                    response.message,
                                    isError: true,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Comments',
                          style: GoogleFonts.raleway(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        if (blog['comments']?.isNotEmpty == true)
                          ...blog['comments'].map<Widget>(
                            (comment) => Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16.r,
                                    backgroundImage: CachedNetworkImageProvider(
                                      comment['user']?['profileImage']
                                                  ?.isNotEmpty ==
                                              true
                                          ? comment['user']['profileImage']
                                          : 'https://randomuser.me/api/portraits/men/2.jpg',
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              comment['user']?['name'] ??
                                                  'Anonymous',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              _formatTime(comment['createdAt']),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12.sp,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          comment['text'] ?? '',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14.sp,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Text(
                            'No comments yet',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }
}
