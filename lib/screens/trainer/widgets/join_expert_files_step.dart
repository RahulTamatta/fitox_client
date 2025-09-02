import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../themes/app_theme.dart';
import '../provider/join_expert_provider.dart';

class JoinExpertFilesStep extends StatelessWidget {
  const JoinExpertFilesStep({super.key});

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
                    Icons.upload_file_rounded,
                    size: 28.sp,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Upload Files",
                    style: GoogleFonts.raleway(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Profile images
              _UploadSection(
                title: "Profile Images (up to 5)",
                images: provider.profileImages,
                onAdd: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickMultiImage(imageQuality: 80);
                  if (picked.isNotEmpty) {
                    for (final x in picked) {
                      provider.addProfileImage(File(x.path));
                    }
                  }
                },
                onRemove: provider.removeProfileImage,
              ),

              SizedBox(height: 16.h),

              // Certification images
              _UploadSection(
                title: "Certificates (optional)",
                images: provider.certificationImages,
                onAdd: () async {
                  final picker = ImagePicker();
                  final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (x != null) {
                    provider.addCertificationImage(File(x.path));
                  }
                },
                onRemove: provider.removeCertificationImage,
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
                      onPressed: () async {
                        final error = provider.validateFiles();
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                          return;
                        }
                        final ok = await provider.submitApplication();
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Application Submitted Successfully!"),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        } else if (provider.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.errorMessage!)),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        "Submit Application",
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

class _UploadSection extends StatelessWidget {
  final String title;
  final List<File> images;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _UploadSection({
    required this.title,
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.raleway(fontWeight: FontWeight.w600, fontSize: 14.sp),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.upload_rounded),
              label: const Text("Add"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (images.isEmpty)
          Text(
            "No files added",
            style: GoogleFonts.raleway(color: Colors.grey.shade600),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final file = images[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.file(file, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => onRemove(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
