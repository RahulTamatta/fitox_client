import 'package:fit_talk/screens/home/trainer_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../themes/app_theme.dart';
import 'provider/home_provider.dart';
import 'services/home_services.dart';
import '../account/account_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Fallback image URL for empty profileImage (use a reliable host)
  static const String _fallbackImageUrl = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=60';

  bool _isValidImageUrl(String? url) {
    if (url == null) return false;
    final s = url.trim();
    if (s.isEmpty) return false;
    if (s.toLowerCase() == 'null' || s.toLowerCase() == 'undefined')
      return false;
    final uri = Uri.tryParse(s);
    if (uri == null) return false;
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    // Trigger fetchAllProfessionals on initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeProvider>(context, listen: false).fetchAllProfessionals();
    });

    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final state = provider.state;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchAllProfessionals(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Header
                    _buildAppHeader(context),
                    SizedBox(height: 16.h),

                    // Search Trainer Bar
                    _buildSearchBar(),
                    SizedBox(height: 24.h),

                    // Hero Banner
                    // _buildHeroBanner(context),
                    // SizedBox(height: 24.h),

                    // // Workout Categories
                    // _buildSectionHeader("Your Fitness Goals", "View All"),
                    // SizedBox(height: 12.h),
                    // _buildWorkoutCategories(),
                    SizedBox(height: 24.h),

                    // Meet Our Trainers Section
                    _buildSectionHeader("Our Top Trainers", "See All"),
                    SizedBox(height: 12.h),
                    state.isLoading
                        ? _buildTrainerShimmer()
                        : state.error != null
                        ? _buildErrorWidget(state.error!.message, context)
                        : _buildTrainerList(
                          state.data?.fold(
                                (failure) => [],
                                (professionals) =>
                                    professionals[ProfessionalType.trainer] ??
                                    [],
                              ) ??
                              [],
                        ),
                    SizedBox(height: 24.h),

                    // Meet Our Dermatologists
                    _buildSectionHeader("Our Dermatologists", "See All"),
                    SizedBox(height: 12.h),
                    state.isLoading
                        ? _buildDermatologistShimmer()
                        : state.error != null
                        ? _buildErrorWidget(state.error!.message, context)
                        : _buildDermatologistList(
                          state.data?.fold(
                                (failure) => [],
                                (professionals) =>
                                    professionals[ProfessionalType
                                        .dermatologist] ??
                                    [],
                              ) ??
                              [],
                        ),
                    SizedBox(height: 32.h),

                    // Meet Our Dieticians
                    _buildSectionHeader("Our Dieticians", "See All"),
                    SizedBox(height: 12.h),
                    state.isLoading
                        ? _buildDermatologistShimmer()
                        : state.error != null
                        ? _buildErrorWidget(state.error!.message, context)
                        : _buildDieticianList(
                          state.data?.fold(
                                (failure) => [],
                                (professionals) =>
                                    professionals[ProfessionalType.dietician] ??
                                    [],
                              ) ??
                              [],
                        ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // App Header with User Greeting
  Widget _buildAppHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back,",
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                "Fitness Champion!",
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              );
            },
            child: Badge(
              smallSize: 8.sp,
              backgroundColor: Colors.red,
              alignment: Alignment.topRight,
              child: CircleAvatar(
                radius: 20.r,
                backgroundImage: const NetworkImage(
                  "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=880&q=80",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Search Trainer Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
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
            hintText: "Search trainers, specialties...",
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
        ),
      ),
    );
  }

  // // Hero Banner (Workout Motivation)
  // Widget _buildHeroBanner(BuildContext context) {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(horizontal: 16.w),
  //     child: Container(
  //       height: 160.h,
  //       width: double.infinity,
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(12.r),
  //         gradient: LinearGradient(
  //           colors: [
  //             Colors.white.withOpacity(0.95),
  //             AppTheme.primaryColor.withOpacity(0.85),
  //           ],
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //         ),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.1),
  //             blurRadius: 10,
  //             offset: const Offset(0, 4),
  //           ),
  //         ],
  //       ),
  //       child: Stack(
  //         children: [
  //           Positioned(
  //             right: 0.w,
  //             bottom: 0.h,
  //             child: Opacity(
  //               opacity: 0.6,
  //               child: CachedNetworkImage(
  //                 imageUrl:
  //                     "https://m.media-amazon.com/images/I/716C77M+qmL._AC_UF1000,1000_QL80_.jpg",
  //                 height: 140.h,
  //                 fit: BoxFit.contain,
  //               ),
  //             ),
  //           ),
  //           Padding(
  //             padding: EdgeInsets.all(16.w),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Text(
  //                   "Summer Body Challenge",
  //                   style: GoogleFonts.raleway(
  //                     fontSize: 16.sp,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.black87,
  //                   ),
  //                 ),
  //                 SizedBox(height: 6.h),
  //                 Text(
  //                   "Join now and get 30% off on personal training",
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 12.sp,
  //                     color: Colors.black54,
  //                   ),
  //                 ),
  //                 SizedBox(height: 12.h),
  //                 InkWell(
  //                   onTap: () {},
  //                   child: Container(
  //                     padding: EdgeInsets.symmetric(
  //                       horizontal: 14.w,
  //                       vertical: 8.h,
  //                     ),
  //                     decoration: BoxDecoration(
  //                       color: AppTheme.primaryColor,
  //                       borderRadius: BorderRadius.circular(10.r),
  //                       boxShadow: [
  //                         BoxShadow(
  //                           color: Colors.black.withOpacity(0.1),
  //                           blurRadius: 6,
  //                           offset: const Offset(0, 2),
  //                         ),
  //                       ],
  //                     ),
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Text(
  //                           "Join Now",
  //                           style: GoogleFonts.poppins(
  //                             fontSize: 12.sp,
  //                             fontWeight: FontWeight.w600,
  //                             color: Colors.white,
  //                           ),
  //                         ),
  //                         SizedBox(width: 6.w),
  //                         Icon(
  //                           Icons.arrow_forward_rounded,
  //                           size: 14.sp,
  //                           color: Colors.white,
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Workout Categories (Filter by Goals)
  Widget _buildWorkoutCategories() {
    final categories = [
      {
        "icon": Icons.fitness_center,
        "name": "Strength",
        "image":
            "https://images.unsplash.com/photo-1534258936925-c58bed479fcb?ixlib=rb-4.0.3&auto=format&fit=crop&w=1482&q=80",
      },
      {
        "icon": Icons.directions_run,
        "name": "Cardio",
        "image":
            "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1482&q=80",
      },
      {
        "icon": Icons.self_improvement,
        "name": "Yoga",
        "image":
            "https://images.unsplash.com/photo-1545389336-cf090694435e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1482&q=80",
      },
      {
        "icon": Icons.local_dining,
        "name": "Diet",
        "image":
            "https://images.unsplash.com/photo-1490645935967-10de6ba17061?ixlib=rb-4.0.3&auto=format&fit=crop&w=1482&q=80",
      },
    ];

    return SizedBox(
      height: 90.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              width: 70.w,
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                image: DecorationImage(
                  image: NetworkImage(categories[index]["image"] as String),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    categories[index]["icon"] as IconData,
                    size: 24.sp,
                    color: Colors.white,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    categories[index]["name"] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Section Header (Title + See All)
  Widget _buildSectionHeader(String title, String actionText) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.raleway(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(10.r),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Text(
                    actionText,
                    style: GoogleFonts.nunito(
                      fontSize: 13.sp,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13.sp,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Error Widget
  Widget _buildErrorWidget(String message, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40.sp,
            color: Colors.red.shade400,
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          InkWell(
            onTap: () {
              Provider.of<HomeProvider>(
                context,
                listen: false,
              ).fetchAllProfessionals();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                "Retry",
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer for Trainers
  Widget _buildTrainerShimmer() {
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: 16.w),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 140.w,
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12.r),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80.w,
                          height: 12.h,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: 100.w,
                          height: 10.h,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: 60.w,
                          height: 8.h,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Unified professional card (same as trainer card)
  Widget _buildProfessionalCard(BuildContext context, Professional p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrainerDetailsScreen(trainer: p),
          ),
        );
      },
      child: Container(
        width: 140.w,
        margin: EdgeInsets.only(right: 12.w),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl:
                        _isValidImageUrl(p.profileImage)
                            ? p.profileImage
                            : _fallbackImageUrl,
                    height: 100.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            height: 100.h,
                            color: Colors.grey.shade300,
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 100.h,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: Icon(Icons.image_not_supported, color: Colors.grey.shade600),
                        ),
                  ),
                  Positioned(
                    bottom: 6.w,
                    left: 6.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 12.sp,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    p.trainerType,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "${p.followers} followers",
                    style: GoogleFonts.poppins(
                      fontSize: 9.sp,
                      color: Colors.grey.shade500,
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

  // Trainers List
  Widget _buildTrainerList(List<Professional> trainers) {
    return trainers.isEmpty
        ? Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Text(
            "No trainers available at the moment",
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        )
        : SizedBox(
          height: 180.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 16.w),
            itemCount: trainers.length,
            itemBuilder: (context, index) {
              final trainer = trainers[index];
              return _buildProfessionalCard(context, trainer);
            },
          ),
        );
  }

  // Shimmer for Dermatologists and Dieticians
  Widget _buildDermatologistShimmer() {
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: 16.w),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 140.w,
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12.r),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80.w,
                          height: 12.h,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: 100.w,
                          height: 10.h,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: 60.w,
                          height: 8.h,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Dermatologists List
  Widget _buildDermatologistList(List<Professional> dermatologists) {
    return dermatologists.isEmpty
        ? Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Text(
            "No dermatologists available at the moment",
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        )
        : SizedBox(
          height: 180.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 16.w),
            itemCount: dermatologists.length,
            itemBuilder: (context, index) {
              final p = dermatologists[index];
              return _buildProfessionalCard(context, p);
            },
          ),
        );
  }

  // Dieticians List
  Widget _buildDieticianList(List<Professional> dieticians) {
    return dieticians.isEmpty
        ? Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Text(
            "No dieticians available at the moment",
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        )
        : SizedBox(
          height: 180.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 16.w),
            itemCount: dieticians.length,
            itemBuilder: (context, index) {
              final p = dieticians[index];
              return _buildProfessionalCard(context, p);
            },
          ),
        );
  }
}
