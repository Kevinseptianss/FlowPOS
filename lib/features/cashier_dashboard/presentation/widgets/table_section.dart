import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TableSection extends StatelessWidget {
  const TableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        border: Border(
          right: BorderSide(color: AppPallete.textPrimary.withAlpha(127)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Table Map', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          BlocBuilder<TableBloc, TableState>(
            builder: (context, state) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(20, (index) {
                  final tableNumber = index + 1;
                  final isSelected = state.selectedTableNumber == tableNumber;

                  return InkWell(
                    onTap: () {
                      context.read<TableBloc>().add(
                        SelectTableEvent(tableNumber),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppPallete.primary
                            : AppPallete.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppPallete.divider),
                      ),
                      child: Text(
                        'T$tableNumber',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: isSelected
                                  ? AppPallete.onPrimary
                                  : AppPallete.textPrimary,
                            ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
