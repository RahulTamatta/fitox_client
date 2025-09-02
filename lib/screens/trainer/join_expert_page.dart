import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../themes/app_theme.dart';
import 'provider/join_expert_provider.dart';
import 'widgets/join_expert_about_step.dart';
import 'widgets/join_expert_personal_step.dart';
import 'widgets/join_expert_professional_step.dart';
import 'widgets/join_expert_files_step.dart';

class JoinExpertPage extends StatefulWidget {
  const JoinExpertPage({super.key});

  @override
  State<JoinExpertPage> createState() => _JoinExpertPageState();
}

class _JoinExpertPageState extends State<JoinExpertPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JoinExpertProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStepper(),
              Expanded(
                child: _buildStepContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 24.sp,
                color: Colors.grey.shade700,
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: AppTheme.primaryColor,
                    size: 28.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "FitTalk",
                    style: GoogleFonts.raleway(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 48.w), // Balance the back button
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Consumer<JoinExpertProvider>(
      builder: (context, provider, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              children: [
                Text(
                  "Join FitTalk as an Expert",
                  style: GoogleFonts.raleway(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  "Share your expertise and connect with clients",
                  style: GoogleFonts.raleway(
                    color: Colors.grey.shade600,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                _buildStepIndicator(provider.currentStep),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    final steps = ["About", "Personal", "Professional", "Files"];
    
    return Row(
      children: List.generate(steps.length, (index) {
        final stepNumber = index + 1;
        final isActive = stepNumber <= currentStep;
        final isCurrent = stepNumber == currentStep;
        
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        border: isCurrent 
                            ? Border.all(color: AppTheme.primaryColor, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: isActive
                            ? Icon(
                                stepNumber < currentStep ? Icons.check : Icons.circle,
                                color: Colors.white,
                                size: 16.sp,
                              )
                            : Text(
                                stepNumber.toString(),
                                style: GoogleFonts.raleway(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      steps[index],
                      style: GoogleFonts.raleway(
                        fontSize: 12.sp,
                        color: isActive ? AppTheme.primaryColor : Colors.grey.shade500,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Container(
                  height: 1.h,
                  width: 20.w,
                  color: Colors.grey.shade300,
                  margin: EdgeInsets.only(bottom: 20.h),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    return Consumer<JoinExpertProvider>(
      builder: (context, provider, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: IndexedStack(
            index: provider.currentStep - 1,
            children: const [
              JoinExpertAboutStep(),
              JoinExpertPersonalStep(),
              JoinExpertProfessionalStep(),
              JoinExpertFilesStep(),
            ],
          ),
        );
      },
    );
  }
}
