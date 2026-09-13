import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../domain/entities/expense.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddExpenseDialog extends StatefulWidget {
  final Expense? expense;

  const AddExpenseDialog({super.key, this.expense});

  static void show(BuildContext context, [Expense? expense]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddExpenseDialog(expense: expense),
    );
  }

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _notesCtrl;
  String _selectedCategory = 'Raw Materials';
  String _selectedPaymentMode = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(text: e != null ? e.amount.toString() : '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _selectedCategory = e?.category ?? 'Raw Materials';
    _selectedPaymentMode = e?.paymentMode ?? 'Cash';
    _selectedDate = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final expense = Expense(
      id: widget.expense?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      category: _selectedCategory,
      amount: double.tryParse(_amountCtrl.text) ?? 0.0,
      paymentMode: _selectedPaymentMode,
      date: _selectedDate,
      notes: _notesCtrl.text.trim(),
    );

    final res = await context.read<ExpenseProvider>().saveExpense(expense);

    setState(() => _isSaving = false);

    if (mounted) {
      if (res.isSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.expense != null ? 'Expense updated!' : 'Expense recorded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.failure?.message ?? 'Failed to save expense'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final categories = expProv.categories.isNotEmpty
        ? expProv.categories
        : ['Raw Materials', 'Rent', 'Utilities', 'Staff Salary', 'Maintenance', 'Other'];

    final isEditing = widget.expense != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLarge)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Expense' : 'Add Operating Expense',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accentNavy),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Expense Title / Description *',
                hintText: 'e.g. Milk & Dairy Supply, Chef Salary',
                controller: _titleCtrl,
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Amount (₹) *',
                      hintText: 'e.g. 1500',
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Valid amount required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentNavy)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 13)),
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryBlue),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentNavy)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentNavy)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedPaymentMode,
                          items: ['Cash', 'UPI', 'Bank Transfer', 'Card', 'Cheque'].map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPaymentMode = val);
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Notes / Vendor Info (Optional)',
                hintText: 'e.g. Paid to Indiranagar Dairy Agency',
                controller: _notesCtrl,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: isEditing ? 'UPDATE EXPENSE' : 'SAVE EXPENSE',
                icon: Icons.check,
                isLoading: _isSaving,
                onPressed: _saveExpense,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
