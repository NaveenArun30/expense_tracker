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
  Set<String> _includedMembers = {};
  Map<String, double> _splitAmounts = {};
  Map<String, double> _splitPercentages = {};
  String _splitType = 'equal'; // equal, exact, percentage

  // Controllers for text fields to maintain state when switching
  final Map<String, TextEditingController> _exactControllers = {};
  final Map<String, TextEditingController> _percentControllers = {};

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // We will initialize in build to guarantee latest state
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    for (var c in _exactControllers.values) { c.dispose(); }
    for (var c in _percentControllers.values) { c.dispose(); }
    super.dispose();
  }

  void _initializeMembersIfNeeded(SharedState state) {
    if (!_initialized && state is GroupDetailsLoaded && state.group.id == widget.groupId) {
      _members = state.members;
      _includedMembers = _members.map((m) => m.userId).toSet();
      for (var member in _members) {
        _exactControllers[member.userId] = TextEditingController();
        _percentControllers[member.userId] = TextEditingController();
      }
      _initialized = true;
    }
  }

  void _calculateSplits(double totalAmount) {
    if (_splitType == 'equal') {
      final newSplits = <String, double>{};
      if (_includedMembers.isNotEmpty) {
        final split = totalAmount / _includedMembers.length;
        for (var member in _members) {
          if (_includedMembers.contains(member.userId)) {
            newSplits[member.userId] = split;
          } else {
            newSplits[member.userId] = 0;
          }
        }
      } else {
        for (var member in _members) {
          newSplits[member.userId] = 0;
        }
      }
      setState(() {
        _splitAmounts = newSplits;
      });
    } else if (_splitType == 'percentage') {
      final newSplits = <String, double>{};
      for (var member in _members) {
        if (_includedMembers.contains(member.userId)) {
          final pct = _splitPercentages[member.userId] ?? 0;
          newSplits[member.userId] = (pct / 100) * totalAmount;
        } else {
          newSplits[member.userId] = 0;
        }
      }
      setState(() {
        _splitAmounts = newSplits;
      });
    }
    // For 'exact', _splitAmounts is updated directly via TextField onChanged,
    // but we need to zero out excluded members.
    else if (_splitType == 'exact') {
      setState(() {
         for (var member in _members) {
           if (!_includedMembers.contains(member.userId)) {
             _splitAmounts[member.userId] = 0;
             _exactControllers[member.userId]?.text = '';
           }
         }
      });
    }
  }

  void _toggleMember(String userId, bool? isChecked) {
    setState(() {
      if (isChecked == true) {
        _includedMembers.add(userId);
      } else {
        _includedMembers.remove(userId);
      }
      final amount = double.tryParse(_amountController.text) ?? 0;
      _calculateSplits(amount);
    });
  }

  void _submit() {
    final description = _descriptionController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (description.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid description and amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _calculateSplits(amount); // Ensure splits are up to date

    // Validation
    double totalSplit = _splitAmounts.values.fold(0, (sum, val) => sum + val);
    
    // Check if total matches with small float tolerance
    if ((totalSplit - amount).abs() > 0.05) {
      String errorMsg = 'Splits do not add up to the total amount!';
      if (_splitType == 'percentage') {
        double totalPct = 0;
        _splitPercentages.forEach((userId, pct) {
           if (_includedMembers.contains(userId)) totalPct += pct;
        });
        errorMsg = 'Percentages add up to ${totalPct.toStringAsFixed(1)}%, they must equal 100%.';
      } else if (_splitType == 'exact') {
        errorMsg = 'Exact amounts add up to \$${totalSplit.toStringAsFixed(2)}, but total is \$${amount.toStringAsFixed(2)}.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Filter out zero splits from being sent to backend
    Map<String, double> finalSplits = {};
    _splitAmounts.forEach((userId, splitAmount) {
      if (splitAmount > 0) {
        finalSplits[userId] = splitAmount;
      }
    });

    if (finalSplits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one member must be included in the split.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<SharedBloc>().add(
      AddSharedExpense(
        groupId: widget.groupId,
        description: description,
        amount: amount,
        category: _categoryController.text,
        splits: finalSplits,
      ),
    );
  }

  // Helper widget to display footer
  Widget _buildSummaryFooter(double totalAmount) {
    if (_splitType == 'equal') return const SizedBox.shrink();

    double currentTotal = 0;
    double maxTarget = 0;
    String symbol = '';
    
    if (_splitType == 'percentage') {
      _splitPercentages.forEach((userId, pct) {
         if (_includedMembers.contains(userId)) currentTotal += pct;
      });
      maxTarget = 100;
      symbol = '%';
    } else if (_splitType == 'exact') {
      _splitAmounts.forEach((userId, amt) {
         if (_includedMembers.contains(userId)) currentTotal += amt;
      });
      maxTarget = totalAmount;
      symbol = '\$';
    }

    double diff = currentTotal - maxTarget;
    bool isOver = diff > 0.05;
    bool isUnder = diff < -0.05;
    
    String mainText = _splitType == 'percentage'
        ? '${currentTotal.toStringAsFixed(0)}% of 100%'
        : '\$${currentTotal.toStringAsFixed(2)} of \$${maxTarget.toStringAsFixed(2)}';
    
    String subText = '';
    if (isOver) {
      subText = _splitType == 'percentage' 
          ? '${diff.toStringAsFixed(0)}% over' 
          : '\$${diff.toStringAsFixed(2)} over';
    } else if (isUnder) {
      subText = _splitType == 'percentage' 
          ? '${diff.abs().toStringAsFixed(0)}% left' 
          : '\$${diff.abs().toStringAsFixed(2)} left';
    } else {
      subText = 'Perfectly split!';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: isOver ? Colors.red.withOpacity(0.1) : AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOver ? Colors.red : Colors.transparent),
      ),
      child: Column(
        children: [
          Text(
            mainText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              color: isOver ? Colors.red : (isUnder ? AppConstants.textSecondary : AppConstants.successColor),
            ),
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
          'Add Expense',
          style: TextStyle(color: AppConstants.textOnPrimary),
        ),
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: AppConstants.textOnPrimary),
        elevation: 0,
      ),
      body: BlocConsumer<SharedBloc, SharedState>(
        listener: (context, state) {
          if (state is SharedOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppConstants.successColor,
              ),
            );
            Navigator.pop(context); // Pop on success!
          } else if (state is SharedError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppConstants.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          // Guarantee state initialization using the active Bloc state
          _initializeMembersIfNeeded(state);
          
          final totalAmount = double.tryParse(_amountController.text) ?? 0;

          return Stack(
            children: [
              SingleChildScrollView(
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
                              DropdownMenuItem(
                                value: 'percentage',
                                child: Text('By Percentage'),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _splitType = val!;
                                // Clear data when switching modes
                                if (_splitType != 'equal') {
                                  _splitAmounts.clear();
                                  _splitPercentages.clear();
                                  for (var c in _exactControllers.values) { c.clear(); }
                                  for (var c in _percentControllers.values) { c.clear(); }
                                }
                                final amount = double.tryParse(_amountController.text) ?? 0;
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
                          final isMe = userId == Supabase.instance.client.auth.currentUser?.id;
                          final isIncluded = _includedMembers.contains(userId);
                          final splitAmount = _splitAmounts[userId] ?? 0;

                          // Dynamic subtitle for percentage mode
                          Widget? subtitleWidget;
                          if (_splitType == 'percentage' && isIncluded) {
                             subtitleWidget = Text(
                               '\$${splitAmount.toStringAsFixed(2)}',
                               style: TextStyle(color: Colors.grey[600], fontSize: 13),
                             );
                          }

                          return Column(
                            children: [
                              ListTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: isIncluded,
                                      onChanged: (val) => _toggleMember(userId, val),
                                      activeColor: AppConstants.primaryColor,
                                    ),
                                    CircleAvatar(
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
                                  ],
                                ),
                                title: Text(
                                  isMe ? 'You' : 'Member ${userId.substring(0, 4)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600, 
                                    decoration: isIncluded ? TextDecoration.none : TextDecoration.lineThrough,
                                    color: isIncluded ? AppConstants.textPrimary : Colors.grey,
                                  ),
                                ),
                                subtitle: subtitleWidget,
                                trailing: SizedBox(
                                  width: 90,
                                  child: _splitType == 'equal' || !isIncluded
                                      ? Container(
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
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isIncluded ? AppConstants.textPrimary : Colors.grey,
                                            ),
                                          ),
                                        )
                                      : _splitType == 'percentage'
                                          ? TextField(
                                              controller: _percentControllers[userId],
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              textAlign: TextAlign.center,
                                              decoration: InputDecoration(
                                                suffixText: '%',
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onChanged: (val) {
                                                _splitPercentages[userId] = double.tryParse(val) ?? 0;
                                                final amount = double.tryParse(_amountController.text) ?? 0;
                                                _calculateSplits(amount);
                                              },
                                            )
                                          : TextField(
                                              controller: _exactControllers[userId],
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              textAlign: TextAlign.center,
                                              decoration: InputDecoration(
                                                prefixText: '\$',
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onChanged: (val) {
                                                setState(() {
                                                  _splitAmounts[userId] = double.tryParse(val) ?? 0;
                                                });
                                              },
                                            ),
                                ),
                              ),
                              if (member != _members.last)
                                const Divider(height: 1, indent: 90),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    
                    _buildSummaryFooter(totalAmount),
                    
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is SharedLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          elevation: 4,
                          shadowColor: AppConstants.primaryColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: state is SharedLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
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
              if (state is SharedLoading)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: const Center(),
                ),
            ],
          );
        },
      ),
    );
  }
}
