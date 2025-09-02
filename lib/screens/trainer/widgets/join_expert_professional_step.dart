import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../themes/app_theme.dart';
import '../provider/join_expert_provider.dart';

class JoinExpertProfessionalStep extends StatelessWidget {
  const JoinExpertProfessionalStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JoinExpertProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.work_rounded,
                    size: 28.sp,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Professional Information",
                    style: GoogleFonts.raleway(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Specializations
              Text(
                "Select your specializations",
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: provider.availableSpecializations.map((spec) {
                  final selected = provider.selectedSpecializations.contains(spec);
                  return ChoiceChip(
                    label: Text(spec),
                    selected: selected,
                    onSelected: (_) => provider.toggleSpecialization(spec),
                    selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                    labelStyle: GoogleFonts.raleway(
                      color: selected ? AppTheme.primaryColor : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 16.h),

              // Years of experience
              TextField(
                decoration: InputDecoration(
                  labelText: "Years of Experience",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null) provider.updateYearsOfExperience(n);
                },
              ),
              SizedBox(height: 12.h),

              // Fee per hour
              TextField(
                decoration: InputDecoration(
                  labelText: "Fee per hour (₹)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  final d = double.tryParse(v);
                  if (d != null) provider.updateFeePerHour(d);
                },
              ),

              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => provider.previousStep(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primaryColor),
                        foregroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        "Back",
                        style: GoogleFonts.raleway(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final error = provider.validateProfessionalInfo();
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                          return;
                        }
                        provider.nextStep();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        "Continue",
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
