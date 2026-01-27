import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/app_constants.dart';
import '../bloc/shared_bloc.dart';
import '../bloc/shared_event.dart';
import '../bloc/shared_state.dart';
import '../models/group_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddSharedExpenseScreen extends StatefulWidget {
  final String groupId;

  const AddSharedExpenseScreen({super.key, required this.groupId});

  @override
  State<AddSharedExpenseScreen> createState() => _AddSharedExpenseScreenState();
}

class _AddSharedExpenseScreenState extends State<AddSharedExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');

  List<GroupMember> _members = [];
  Map<String, double> _splitAmounts = {};
  String _splitType = 'equal'; // equal, exact

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    final state = context.read<SharedBloc>().state;
    if (state is GroupDetailsLoaded && state.group.id == widget.groupId) {
      setState(() {
        _members = state.members;
      });
    }
  }

  void _calculateSplits(double totalAmount) {
    if (_splitType == 'equal' && _members.isNotEmpty) {
      final split = totalAmount / _members.length;
      final newSplits = <String, double>{};
      for (var member in _members) {
        newSplits[member.userId] = split;
      }
      setState(() {
        _splitAmounts = newSplits;
      });
    }
  }

  void _submit() {
    final description = _descriptionController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (description.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid details')),
      );
      return;
    }

    _calculateSplits(amount); // Ensure splits are up to date

    context.read<SharedBloc>().add(
      AddSharedExpense(
        groupId: widget.groupId,
        description: description,
        amount: amount,
        category: _categoryController.text,
        splits: _splitAmounts,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Add Expense',
          style: TextStyle(color: AppConstants.textOnPrimary),
        ),
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: AppConstants.textOnPrimary),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Enter Amount',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixText: '\$',
                      prefixStyle: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    onChanged: (val) {
                      final amount = double.tryParse(val) ?? 0;
                      _calculateSplits(amount);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details Form
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'What is this for?',
                      prefixIcon: const Icon(
                        Icons.description_outlined,
                        color: AppConstants.primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppConstants.backgroundColor,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'Category (e.g., Food, Travel)',
                      prefixIcon: const Icon(
                        Icons.category_outlined,
                        color: AppConstants.primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppConstants.backgroundColor,
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Split Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Split With',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: DropdownButton<String>(
                    value: _splitType,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppConstants.primaryColor,
                    ),
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'equal',
                        child: Text('Split Equally'),
                      ),
                      DropdownMenuItem(
                        value: 'exact',
                        child: Text('Exact Amount'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _splitType = val!;
                        final amount =
                            double.tryParse(_amountController.text) ?? 0;
                        _calculateSplits(amount);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: _members.map((member) {
                  final userId = member.userId;
                  final isMe =
                      userId == Supabase.instance.client.auth.currentUser?.id;
                  final splitAmount = _splitAmounts[userId] ?? 0;

                  return Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isMe
                              ? AppConstants.primaryColor
                              : Colors.grey[200],
                          foregroundColor: isMe
                              ? Colors.white
                              : Colors.grey[700],
                          child: Text(
                            isMe ? 'You' : userId.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(
                          isMe ? 'You' : 'Member ${userId.substring(0, 4)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '\$${splitAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      if (member != _members.last)
                        const Divider(height: 1, indent: 70),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  elevation: 4,
                  shadowColor: AppConstants.primaryColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Add Expense',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
