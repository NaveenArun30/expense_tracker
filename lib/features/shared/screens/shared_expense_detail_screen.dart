import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_constants.dart';
import '../bloc/shared_bloc.dart';
import '../bloc/shared_event.dart';
import '../bloc/shared_state.dart';
import '../models/shared_expense_model.dart';

class SharedExpenseDetailScreen extends StatefulWidget {
  final String expenseId;

  const SharedExpenseDetailScreen({super.key, required this.expenseId});

  @override
  State<SharedExpenseDetailScreen> createState() =>
      _SharedExpenseDetailScreenState();
}

class _SharedExpenseDetailScreenState extends State<SharedExpenseDetailScreen> {
  final String currentUserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    // Check if we already have this expense's details
    final currentState = context.read<SharedBloc>().state;
    if (currentState is! ExpenseSplitsLoaded ||
        currentState.expense.id != widget.expenseId) {
      // Need to load data
      context.read<SharedBloc>().add(LoadExpenseSplits(widget.expenseId));
    }
  }

  void _showMarkPaidConfirmation(
    BuildContext context,
    ExpenseSplit split,
    bool currentlyPaid,
  ) {
    // final action = currentlyPaid ? 'mark as pending' : 'mark as paid';
    final newStatus = currentlyPaid ? 'pending' : 'paid';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          currentlyPaid ? 'Mark as Pending?' : 'Mark as Paid?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          currentlyPaid
              ? 'Are you sure you want to mark this payment as pending?'
              : 'Confirm that this person has paid their share of \$${split.amount.toStringAsFixed(2)}?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<SharedBloc>().add(
                UpdateSplitStatus(
                  splitId: split.id,
                  expenseId: split.expenseId,
                  status: newStatus,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: currentlyPaid
                  ? AppConstants.warningColor
                  : AppConstants.successColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(currentlyPaid ? 'Mark Pending' : 'Mark Paid'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Expense Details',
          style: TextStyle(
            color: AppConstants.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: AppConstants.textOnPrimary),
        elevation: 0,
      ),
      body: BlocConsumer<SharedBloc, SharedState>(
        listener: (context, state) {
          if (state is SharedError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppConstants.errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SharedLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading expense details...',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ExpenseSplitsLoaded &&
              state.expense.id == widget.expenseId) {
            final expense = state.expense;
            final splits = state.splits;
            final isPayer = expense.paidBy == currentUserId;

            // Calculate totals
            final totalPaid = splits
                .where((s) => s.status == 'paid')
                .fold<double>(0, (sum, s) => sum + s.amount);
            final totalPending = splits
                .where((s) => s.status == 'pending')
                .fold<double>(0, (sum, s) => sum + s.amount);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(expense),
                  const SizedBox(height: 16),
                  _buildSummaryCards(totalPaid, totalPending, expense.amount),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text(
                          'Split Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${splits.length} People',
                            style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (splits.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No splits found for this expense.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ...splits.map(
                    (split) => _buildSplitItem(split, isPayer, context),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Could not load expense details',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<SharedBloc>().add(
                      LoadExpenseSplits(widget.expenseId),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(SharedExpenseModel expense) {
    final isPayer = expense.paidBy == currentUserId;
    final categoryColor =
        AppConstants.categoryColors[expense.category] ??
        AppConstants.primaryColor;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [categoryColor, categoryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppConstants.categoryIcons[expense.category] ??
                      Icons.receipt_long,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.category.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.description,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${expense.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Paid by',
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isPayer ? 'You' : 'Member',
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMM dd, yyyy').format(expense.date),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('hh:mm a').format(expense.date),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    double totalPaid,
    double totalPending,
    double total,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppConstants.successColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.successColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConstants.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: AppConstants.successColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Paid',
                        style: TextStyle(
                          color: AppConstants.successColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${totalPaid.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppConstants.successColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${((totalPaid / total) * 100).toStringAsFixed(0)}% of total',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppConstants.warningColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.warningColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConstants.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.pending,
                          color: AppConstants.warningColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pending',
                        style: TextStyle(
                          color: AppConstants.warningColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${totalPending.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppConstants.warningColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${((totalPending / total) * 100).toStringAsFixed(0)}% of total',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitItem(
    ExpenseSplit split,
    bool isPayer,
    BuildContext context,
  ) {
    final isMe = split.userId == currentUserId;
    final isPaid = split.status == 'paid';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid
              ? AppConstants.successColor.withOpacity(0.3)
              : AppConstants.warningColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isMe
                  ? [AppConstants.primaryColor, AppConstants.primaryLight]
                  : [Colors.grey[300]!, Colors.grey[400]!],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (isMe ? AppConstants.primaryColor : Colors.grey)
                    .withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              isMe ? '👤' : split.userId.substring(0, 2).toUpperCase(),
              style: TextStyle(
                fontSize: isMe ? 24 : 16,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              isMe ? 'You' : 'Member ${split.userId.substring(0, 6)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppConstants.textPrimary,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '\$${split.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: _buildStatusAction(split, isPayer, isMe, isPaid, context),
      ),
    );
  }

  Widget _buildStatusAction(
    ExpenseSplit split,
    bool isPayer,
    bool isMe,
    bool isPaid,
    BuildContext context,
  ) {
    // Only the payer can mark others as paid
    if (isPayer && !isMe) {
      return InkWell(
        onTap: () => _showMarkPaidConfirmation(context, split, isPaid),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isPaid
                ? AppConstants.successColor.withOpacity(0.1)
                : AppConstants.warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPaid
                  ? AppConstants.successColor.withOpacity(0.3)
                  : AppConstants.warningColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isPaid
                    ? AppConstants.successColor
                    : AppConstants.warningColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isPaid ? 'Paid' : 'Mark Paid',
                style: TextStyle(
                  color: isPaid
                      ? AppConstants.successColor
                      : AppConstants.warningColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Status badge for non-payer users
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isPaid
            ? AppConstants.successColor.withOpacity(0.15)
            : AppConstants.warningColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaid
              ? AppConstants.successColor.withOpacity(0.4)
              : AppConstants.warningColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            color: isPaid
                ? AppConstants.successColor
                : AppConstants.warningColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isPaid ? 'PAID' : 'PENDING',
            style: TextStyle(
              color: isPaid
                  ? AppConstants.successColor
                  : AppConstants.warningColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
