import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/selected_modifier.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/modifier_option_row.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item_variant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModifierDialog extends StatefulWidget {
  final String menuId;
  final String itemName;
  final int price;
  final List<MenuItemVariant> variants;

  const ModifierDialog({
    super.key,
    required this.menuId,
    required this.itemName,
    required this.price,
    required this.variants,
  });

  @override
  State<ModifierDialog> createState() => _ModifierDialogState();
}

class _ModifierDialogState extends State<ModifierDialog> {
  int quantity = 1;
  final Map<String, SelectedModifier?> selectedModifierByGroup = {};
  final TextEditingController _noteController = TextEditingController();
  int _currentStep = 0;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int _calculateModifiersPrice() {
    int total = 0;
    for (var group in selectedModifierByGroup.values) {
      if (group != null) {
        final variant = widget.variants.firstWhere((v) => v.id == group.id);
        total += variant.price;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final groupedOptions = <String, List<MenuItemVariant>>{};
    for (final variant in widget.variants) {
      groupedOptions.putIfAbsent(variant.optionName, () => []).add(variant);
    }

    final steps = groupedOptions.entries.toList();
    final totalSteps = steps.length + 1; // +1 for Notes

    final modifiersTotal = _calculateModifiersPrice();
    final totalPrice = (widget.price + modifiersTotal) * quantity;

    return Container(
      decoration: const BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppPallete.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Header with Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.itemName,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppPallete.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatRupiah(widget.price),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppPallete.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Qty Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppPallete.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildQtyBtn(Icons.remove, () {
                            if (quantity > 1) setState(() => quantity--);
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '$quantity',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildQtyBtn(Icons.add, () => setState(() => quantity++)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Step Indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalSteps, (index) {
                    final isActive = index == _currentStep;
                    final isCompleted = index < _currentStep;
                    return Container(
                      width: isActive ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive || isCompleted ? AppPallete.primary : AppPallete.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),

          // Content Area - Step based
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_currentStep),
              padding: const EdgeInsets.all(24),
              child: _buildCurrentStep(steps),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: AppPallete.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  IconButton(
                    onPressed: () => setState(() => _currentStep--),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppPallete.textSecondary,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Harga',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppPallete.textSecondary,
                        ),
                      ),
                      Text(
                        formatRupiah(totalPrice),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppPallete.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < totalSteps - 1) {
                        setState(() => _currentStep++);
                      } else {
                        _finishSelection(totalPrice);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPallete.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentStep < totalSteps - 1 ? 'Lanjut' : 'Tambah Pesanan',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(List<MapEntry<String, List<MenuItemVariant>>> steps) {
    if (_currentStep < steps.length) {
      final step = steps[_currentStep];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            step.key,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPallete.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silahkan pilih salah satu opsi di bawah ini.',
            style: GoogleFonts.outfit(fontSize: 14, color: AppPallete.textSecondary),
          ),
          const SizedBox(height: 20),
          ...step.value.map((variant) {
            final isSelected = selectedModifierByGroup[step.key]?.id == variant.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ModifierOptionRow(
                label: variant.variantName,
                additionalPrice: variant.price,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedModifierByGroup[step.key] = null;
                    } else {
                      selectedModifierByGroup[steps[_currentStep].key] = SelectedModifier(
                        id: variant.id,
                        name: variant.variantName,
                        optionName: variant.optionName,
                      );
                      
                      // AUTO CONTINUE for faster service
                      // Add a tiny delay so the user sees the selection feedback
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted && _currentStep < steps.length) {
                          setState(() => _currentStep++);
                        }
                      });
                    }
                  });
                },
              ),
            );
          }),
        ],
      );
    } else {
      // Notes Step
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Catatan Khusus',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPallete.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan catatan jika ada permintaan khusus.',
            style: GoogleFonts.outfit(fontSize: 14, color: AppPallete.textSecondary),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _noteController,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Contoh: Jangan pedas, tanpa seledri...',
              hintStyle: GoogleFonts.outfit(color: AppPallete.textSecondary, fontSize: 14),
              filled: true,
              fillColor: AppPallete.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.edit_note_rounded, color: AppPallete.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }
  }

  void _finishSelection(int totalPrice) {
    String? primaryVariantId;
    if (selectedModifierByGroup.isNotEmpty) {
      for (var group in selectedModifierByGroup.values) {
        if (group != null) {
          primaryVariantId = group.id;
          break;
        }
      }
    }
    Navigator.pop(context, {
      'totalPrice': totalPrice,
      'selectedModifiers': Map<String, SelectedModifier?>.from(selectedModifierByGroup),
      'quantity': quantity,
      'variantId': primaryVariantId,
      'notes': _noteController.text.trim(),
    });
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPallete.divider),
        ),
        child: Icon(icon, size: 20, color: AppPallete.primary),
      ),
    );
  }
}
