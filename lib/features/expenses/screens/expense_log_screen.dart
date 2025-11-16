import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_constants.dart';
import '../../../model/expense_model.dart';
import '../../../widgets/date_picker_widget.dart';
import '../../../widgets/expense_detail_bottom_sheet.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';

class ExpenseLogScreen extends StatefulWidget {
  const ExpenseLogScreen({super.key});

  @override
  State<ExpenseLogScreen> createState() => _ExpenseLogScreenState();
}

class _ExpenseLogScreenState extends State<ExpenseLogScreen> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'This Week',
    'This Month',
    'Last Month',
    'Custom Range',
  ];

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpenseBloc()..add(LoadExpenses()),
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Expense Log',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppConstants.textOnPrimary,
            ),
          ),
          backgroundColor: AppConstants.primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppConstants.textOnPrimary),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppConstants.primaryGradient,
              ),
            ),
          ),
        ),
        body: BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildFilterSection(context),
                if (_selectedFilter == 'Custom Range')
                  _buildCustomDateRangeInfo(),
                _buildSummaryCard(state),
                Expanded(child: _buildExpensesList(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      _applyFilter(context, filter);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppConstants.primaryColor
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppConstants.primaryColor
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDateRangeInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, color: AppConstants.primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _customStartDate != null && _customEndDate != null
                  ? '${DateFormat('MMM dd, yyyy').format(_customStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_customEndDate!)}'
                  : 'Select custom date range',
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_customStartDate != null && _customEndDate != null)
            GestureDetector(
              onTap: () {
                setState(() {
                  _customStartDate = null;
                  _customEndDate = null;
                  _selectedFilter = 'All';
                });
                _applyFilter(context, 'All');
              },
              child: Icon(
                Icons.close,
                color: AppConstants.primaryColor,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ExpenseState state) {
    if (state is ExpenseLoaded) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppConstants.primaryGradient,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      color: AppConstants.textOnPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${state.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppConstants.textOnPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppConstants.textOnPrimary.withOpacity(0.3),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transactions',
                    style: TextStyle(
                      color: AppConstants.textOnPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.expenses.length}',
                    style: const TextStyle(
                      color: AppConstants.textOnPrimary,
                      fontSize: 28,
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
    return const SizedBox.shrink();
  }

  Widget _buildExpensesList(ExpenseState state) {
    if (state is ExpenseLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ExpenseLoaded) {
      if (state.expenses.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFilter == 'All'
                    ? 'Start adding expenses to see them here'
                    : 'No transactions found for the selected period',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        );
      }

      // Group expenses by date
      Map<String, List<ExpenseModel>> groupedExpenses = {};
      for (var expense in state.expenses) {
        final dateKey = DateFormat('yyyy-MM-dd').format(expense.date);
        if (!groupedExpenses.containsKey(dateKey)) {
          groupedExpenses[dateKey] = [];
        }
        groupedExpenses[dateKey]!.add(expense);
      }

      final sortedDates = groupedExpenses.keys.toList()
        ..sort((a, b) => b.compareTo(a)); // Sort descending

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final dayExpenses = groupedExpenses[dateKey]!;
          final date = DateTime.parse(dateKey);
          final dayTotal = dayExpenses.fold(
            0.0,
            (sum, expense) => sum + expense.amount,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateHeader(date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          '${dayExpenses.length} transactions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${dayTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              ...dayExpenses.map(
                (expense) => _buildExpenseItem(context, expense),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildExpenseItem(BuildContext context, ExpenseModel expense) {
    final categoryColor =
        AppConstants.categoryColors[expense.category] ?? Colors.grey;
    final categoryIcon =
        AppConstants.categoryIcons[expense.category] ?? Icons.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(categoryIcon, color: categoryColor, size: 24),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF2D3748),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              expense.category,
              style: TextStyle(
                color: categoryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (expense.description != null &&
                expense.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                expense.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat.jm().format(expense.date),
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        onTap: () {
          _showExpenseDetails(context, expense);
        },
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) {
      return 'Today';
    } else if (expenseDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  void _applyFilter(BuildContext context, String filter) async {
    final now = DateTime.now();

    switch (filter) {
      case 'All':
        // Load all expenses without date filtering
        context.read<ExpenseBloc>().add(LoadExpenses());
        break;

      case 'This Week':
        // Calculate start of week (Monday)
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

        context.read<ExpenseBloc>().add(
          LoadExpensesByDateRange(startDate: startDate, endDate: endDate),
        );
        break;

      case 'This Month':
        // Current month from 1st to today
        final startDate = DateTime(now.year, now.month, 1);
        final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

        context.read<ExpenseBloc>().add(
          LoadExpensesByDateRange(startDate: startDate, endDate: endDate),
        );
        break;

      case 'Last Month':
        // Previous month
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final startDate = lastMonth;
        final endDate = DateTime(now.year, now.month, 0, 23, 59, 59);

        context.read<ExpenseBloc>().add(
          LoadExpensesByDateRange(startDate: startDate, endDate: endDate),
        );
        break;

      case 'Custom Range':
        await _showCustomDateRangePicker(context);
        break;
    }
  }

  Future<void> _showCustomDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => DateRangePickerWidget(
        initialStartDate: _customStartDate,
        initialEndDate: _customEndDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });

      // Load expenses for the selected date range
      context.read<ExpenseBloc>().add(
        LoadExpensesByDateRange(
          startDate: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          endDate: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          ),
        ),
      );
    } else {
      // If user cancels, revert to 'All'
      setState(() {
        _selectedFilter = 'All';
      });
      context.read<ExpenseBloc>().add(LoadExpenses());
    }
  }

  void _showExpenseDetails(BuildContext context, ExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseDetailBottomSheet(expense: expense),
    );
  }

  void _showDeleteDialog(BuildContext context, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Expense',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              context.read<ExpenseBloc>().add(DeleteExpense(expense.id!));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
