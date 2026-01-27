import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_constants.dart';
import '../bloc/shared_bloc.dart';
import '../bloc/shared_event.dart';
import '../bloc/shared_state.dart';
import 'add_shared_expense_screen.dart';
import 'shared_expense_detail_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    // Only load if we don't already have this group's details
    final currentState = context.read<SharedBloc>().state;
    if (currentState is! GroupDetailsLoaded ||
        currentState.group.id != widget.groupId) {
      context.read<SharedBloc>().add(LoadGroupDetails(widget.groupId));
      _hasLoadedOnce = true;
    } else {
      _hasLoadedOnce = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Group Details',
          style: TextStyle(color: AppConstants.textOnPrimary),
        ),
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: AppConstants.textOnPrimary),
      ),
      body: BlocBuilder<SharedBloc, SharedState>(
        buildWhen: (previous, current) {
          // Only rebuild when:
          // 1. Current state is for this specific group
          // 2. Loading state (initial load)
          // 3. Error state
          if (current is GroupDetailsLoaded) {
            return current.group.id == widget.groupId;
          }
          if (current is SharedLoading) {
            return !_hasLoadedOnce;
          }
          return current is SharedError;
        },
        builder: (context, state) {
          if (state is SharedLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SharedError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SharedBloc>().add(
                        LoadGroupDetails(widget.groupId),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is GroupDetailsLoaded && state.group.id == widget.groupId) {
            return Column(
              children: [
                _buildBalanceSummary(state),
                Expanded(
                  child: state.expenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No expenses yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add your first expense!',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: state.expenses.length,
                          itemBuilder: (context, index) {
                            final expense = state.expenses[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      (AppConstants.categoryColors[expense
                                                  .category] ??
                                              Colors.blue)
                                          .withOpacity(0.1),
                                  child: Icon(
                                    AppConstants.categoryIcons[expense
                                            .category] ??
                                        Icons.receipt_long,
                                    color:
                                        AppConstants.categoryColors[expense
                                            .category] ??
                                        Colors.blue,
                                  ),
                                ),
                                title: Text(
                                  expense.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Paid by ${expense.paidBy.substring(0, 4)}... \n${DateFormat.yMMMd().format(expense.date)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Text(
                                  '\$${expense.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<SharedBloc>(),
                                        child: SharedExpenseDetailScreen(
                                          expenseId: expense.id,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          // Fallback for any other state (like initial transition)
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<SharedBloc>(),
                child: AddSharedExpenseScreen(groupId: widget.groupId),
              ),
            ),
          );
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBalanceSummary(GroupDetailsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.group.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                  '${state.members.length} Members',
                  style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Spending',
                  '\$${state.expenses.fold<double>(0, (sum, e) => sum + e.amount).toStringAsFixed(2)}',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Expenses',
                  '${state.expenses.length}',
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
