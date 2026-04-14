import 'dart:async';
import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/shift/presentation/bloc/shift_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OpenShiftPage extends StatefulWidget {
  const OpenShiftPage({super.key});

  @override
  State<OpenShiftPage> createState() => _OpenShiftPageState();
}

class _OpenShiftPageState extends State<OpenShiftPage> {
  String _startingCashStr = '0';
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'delete') {
        if (_startingCashStr.length > 1) {
          _startingCashStr = _startingCashStr.substring(0, _startingCashStr.length - 1);
        } else {
          _startingCashStr = '0';
        }
      } else if (key == '000') {
        if (_startingCashStr != '0') {
          _startingCashStr += '000';
        }
      } else {
        if (_startingCashStr == '0') {
          _startingCashStr = key;
        } else {
          _startingCashStr += key;
        }
      }
      
      // Limit to 12 digits (trillions)
      if (_startingCashStr.length > 12) {
        _startingCashStr = _startingCashStr.substring(0, 12);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserBloc>().state;
    if (userState is! UserLoggedIn) return const SizedBox();
    
    final user = userState.user;
    final double startingCash = double.tryParse(_startingCashStr) ?? 0;

    return Scaffold(
      backgroundColor: AppPallete.background,
      body: BlocListener<ShiftBloc, ShiftState>(
        listener: (context, state) {
          if (state is ShiftFailure) {
            showSnackbar(context, state.message);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppPallete.primary.withAlpha(40),
                AppPallete.background,
                AppPallete.background,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(user.name),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          _buildClockSection(),
                          const SizedBox(height: 48),
                          _buildBalanceDisplay(startingCash),
                          const SizedBox(height: 48),
                          _buildTouchpad(),
                          const SizedBox(height: 120), // Space for floating buttons
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildActionButtons(user.id, user.name, startingCash),
    );
  }

  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppPallete.primary,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $name',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppPallete.textPrimary,
                  ),
                ),
                Text(
                  'Siap melayani hari ini?',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppPallete.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline_rounded, color: AppPallete.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildClockSection() {
    final timeStr = DateFormat('HH:mm').format(_now); // Seconds hidden
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_now);

    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppPallete.primary, AppPallete.primary.withAlpha(180)],
          ).createShader(bounds),
          child: Text(
            timeStr,
            style: GoogleFonts.outfit(
              fontSize: 84,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppPallete.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            dateStr.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppPallete.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'MODAL AWAL KASIR',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppPallete.textSecondary.withAlpha(150),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Rp ',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textSecondary,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  NumberFormat.decimalPattern('id').format(amount),
                  style: GoogleFonts.outfit(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: AppPallete.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPallete.success.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppPallete.success),
                const SizedBox(width: 8),
                Text(
                  'Pastikan jumlah uang fisik sesuai',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppPallete.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchpad() {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        _buildRow(['4', '5', '6']),
        _buildRow(['7', '8', '9']),
        _buildRow(['000', '0', 'delete']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: keys.map((key) => _buildKey(key)).toList(),
      ),
    );
  }

  Widget _buildKey(String label) {
    final isDelete = label == 'delete';
    final isSpecial = label == '000';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: isSpecial ? AppPallete.secondary.withAlpha(15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => _onKeyPress(label),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSpecial ? AppPallete.secondary.withAlpha(50) : AppPallete.divider,
                  width: 1,
                ),
              ),
              child: isDelete
                  ? const Icon(Icons.backspace_rounded, color: AppPallete.error, size: 28)
                  : Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: isSpecial ? AppPallete.secondary : AppPallete.textPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(String cashierId, String cashierName, double amount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                context.read<ShiftBloc>().add(SkipShiftEvent(cashierId: cashierId));
              },
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'Lewati',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.primary.withAlpha(60),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  context.read<ShiftBloc>().add(OpenShiftEvent(
                    cashierId: cashierId,
                    cashierName: cashierName,
                    openingBalance: amount,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  backgroundColor: AppPallete.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  'Buka Shift',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
