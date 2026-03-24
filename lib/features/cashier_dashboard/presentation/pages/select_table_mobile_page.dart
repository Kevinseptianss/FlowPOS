import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectTableMobilePage extends StatelessWidget {
  const SelectTableMobilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(title: const Text('Select Table')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<TableBloc, TableState>(
              builder: (context, state) {
                return Text(
                  'Current: T${state.selectedTableNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppPallete.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Expanded(
              child: BlocBuilder<TableBloc, TableState>(
                builder: (context, state) {
                  return GridView.builder(
                    itemCount: 20,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.1,
                        ),
                    itemBuilder: (context, index) {
                      final tableNumber = index + 1;
                      final isSelected =
                          state.selectedTableNumber == tableNumber;

                      return InkWell(
                        onTap: () {
                          context.read<TableBloc>().add(
                            SelectTableEvent(tableNumber),
                          );
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppPallete.primary
                                : AppPallete.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppPallete.primary
                                  : AppPallete.divider,
                            ),
                          ),
                          child: Text(
                            'T$tableNumber',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: isSelected
                                      ? AppPallete.onPrimary
                                      : AppPallete.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
