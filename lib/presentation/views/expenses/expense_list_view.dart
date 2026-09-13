import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/expense.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/custom_card.dart';
import 'add_expense_dialog.dart';

class ExpenseListView extends StatefulWidget {
  const ExpenseListView({super.key});

  @override
  State<ExpenseListView> createState() => _ExpenseListViewState();
}

class _ExpenseListViewState extends State<ExpenseListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().init();
    });
  }

  void _openAddExpense([Expense? expense]) {
    AddExpenseDialog.show(context, expense);
  }

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final expenses = expProv.expenses;
    final categories = expProv.categories;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Operating Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryBlue),
            tooltip: 'Add Expense',
            onPressed: () => _openAddExpense(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip(
                    id: 'all',
                    label: 'All Expenses',
                    isSelected: expProv.selectedCategory == 'all',
                    onTap: () => expProv.selectCategory('all'),
                  ),
                  ...categories.map((c) {
                    return _buildCategoryChip(
                      id: c,
                      label: c,
                      isSelected: expProv.selectedCategory == c,
                      onTap: () => expProv.selectCategory(c),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Total Expense Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.canvas,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${expenses.length} entries recorded',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                ),
                Row(
                  children: [
                    const Text('Total Outflow: ', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                    Text(
                      CurrencyFormatter.format(expProv.totalExpenseAmount),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.danger),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Expense list
          Expanded(
            child: expProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : expenses.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.receipt_long,
                        title: 'No Expenses Recorded',
                        message: 'Log raw material purchases, rent, utilities, and wages for accurate profit calculation.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: expenses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return CustomCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.outbox, size: 20, color: AppColors.danger),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.title,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${expense.category} • ${expense.paymentMode} • ${DateFormatter.formatDate(expense.date)}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                                      ),
                                      if (expense.notes.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          expense.notes,
                                          style: const TextStyle(fontSize: 11, color: AppColors.secondaryText, fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(expense.amount),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accentNavy),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.secondaryText),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _openAddExpense(expense),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _confirmDelete(context, expense),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddExpense(),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String id,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryBlue,
        backgroundColor: AppColors.canvas,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.accentNavy,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        showCheckmark: false,
      ),
    );
  }

  void _confirmDelete(BuildContext context, Expense exp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text('Are you sure you want to delete "${exp.title}" (${CurrencyFormatter.format(exp.amount)})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              context.read<ExpenseProvider>().deleteExpense(exp.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
