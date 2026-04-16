import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';

void showFlowPOSAlert({
  required BuildContext context,
  required String title,
  required String message,
  bool isError = true,
}) {
  showDialog(
    context: context,
    builder: (context) => Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isError ? AppPallete.primary.withAlpha(20) : Colors.green.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  color: isError ? AppPallete.primary : Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppPallete.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Divider(height: 1, color: Colors.grey[100]),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'MENGERTI',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      color: AppPallete.primary,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
