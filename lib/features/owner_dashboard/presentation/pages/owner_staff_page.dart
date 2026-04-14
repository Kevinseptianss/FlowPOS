import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/staff/domain/entities/staff_profile.dart';
import 'package:flow_pos/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/add_staff_modal.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerStaffPage extends StatefulWidget {
  const OwnerStaffPage({super.key});

  static Route route() => MaterialPageRoute(builder: (_) => const OwnerStaffPage());

  @override
  State<OwnerStaffPage> createState() => _OwnerStaffPageState();
}

class _OwnerStaffPageState extends State<OwnerStaffPage> {
  @override
  void initState() {
    super.initState();
    context.read<StaffBloc>().add(GetStaffEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Manajemen Staff',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppPallete.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppPallete.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<StaffBloc, StaffState>(
        buildWhen: (previous, current) => current is! UsernameChecked,
        listener: (context, state) {
          if (state is StaffFailure) {
            showSnackbar(context, state.message);
          }
          if (state is StaffRoleUpdated) {
            showSnackbar(context, 'Role staff berhasil diperbarui');
          }
          if (state is StaffCreated) {
            showSnackbar(context, 'Staff berhasil ditambahkan');
            Navigator.of(context, rootNavigator: true).pop(); // Close modal
          }
          if (state is StaffDeleted) {
            showSnackbar(context, 'Staff berhasil dihapus');
          }
        },
        builder: (context, state) {
          if (state is StaffLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StaffLoaded) {
            return _buildStaffList(state.staff);
          }
          return const Center(child: Text('Gagal memuat data staff'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffModal(context),
        backgroundColor: AppPallete.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text('Tambah Staff', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildStaffList(List<StaffProfile> staffList) {
    if (staffList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 80, color: AppPallete.primary.withAlpha(40)),
            const SizedBox(height: 16),
            Text('Belum ada staff terdaftar', style: GoogleFonts.outfit(color: AppPallete.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: staffList.length,
      itemBuilder: (context, index) {
        final staff = staffList[index];
        return _buildStaffCard(staff);
      },
    );
  }

  Widget _buildStaffCard(StaffProfile staff) {
    final isOwner = staff.role == 'owner';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppPallete.primary.withAlpha(15),
          child: Text(
            staff.name.substring(0, 1).toUpperCase(),
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppPallete.primary, fontSize: 20),
          ),
        ),
        title: Text(
          staff.name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppPallete.textPrimary, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              staff.username != null && staff.username!.isNotEmpty 
                  ? '@${staff.username}' 
                  : staff.email, 
              style: GoogleFonts.outfit(fontSize: 12, color: AppPallete.textSecondary)
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isOwner ? Colors.purple.withAlpha(20) : Colors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                staff.role.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  color: isOwner ? Colors.purple : Colors.blue
                ),
              ),
            ),
          ],
        ),
        trailing: isOwner 
            ? null 
            : IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => _showStaffActions(context, staff),
              ),
      ),
    );
  }

  void _showStaffActions(BuildContext context, StaffProfile staff) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atur Staff', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            _buildActionItem(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Jadikan Kasir',
              subtitle: 'Akses terbatas ke menu penjualan',
              onTap: () {
                context.read<StaffBloc>().add(UpdateStaffRoleEvent(staff.id, 'cashier'));
                Navigator.pop(context);
              },
            ),
            _buildActionItem(
              icon: Icons.delete_outline_rounded,
              title: 'Hapus Akses',
              subtitle: 'Staff tidak dapat lagi masuk ke aplikasi',
              color: Colors.red,
              onTap: () {
                _showDeleteConfirmation(context, staff);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = AppPallete.primary,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withAlpha(15), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12)),
    );
  }

  void _showDeleteConfirmation(BuildContext context, StaffProfile staff) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Hapus Akses?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Anda yakin ingin menghapus akses untuk ${staff.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('BATAL')),
          TextButton(
            onPressed: () {
              context.read<StaffBloc>().add(DeleteStaffEvent(staff.id));
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close bottom sheet
            },
            child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddStaffModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider.value(
        value: context.read<StaffBloc>(),
        child: const AddStaffModal(),
      ),
    );
  }
}
