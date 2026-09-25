import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../constants/app_constants.dart';
import '../../../model/expense_model.dart';
import '../../../model/income_model.dart';
import '../../expenses/bloc/expense_bloc.dart';
import '../../expenses/bloc/expense_event.dart';
import '../../income/bloc/income_bloc.dart';
import '../../income/bloc/income_event.dart';
import '../models/extracted_transaction.dart';
import '../services/file_parser_service.dart';

class StatementUploadScreen extends StatefulWidget {
  const StatementUploadScreen({super.key});

  @override
  State<StatementUploadScreen> createState() => _StatementUploadScreenState();
}

class _StatementUploadScreenState extends State<StatementUploadScreen> {
  PlatformFile? _selectedFile;
  bool _isProcessing = false;
  List<ExtractedTransaction> _extractedTransactions = [];
  String _selectedFilter = 'All'; // 'All', 'Credit', 'Debit'
  String? _errorMessage;

  final List<String> _categories = [
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Salary',
    'Investment',
    'Refund',
    'Income',
    'Expense',
    'Other'
  ];

  Future<void> _pickAndParseFile() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'xlsx', 'xls', 'csv'],
          withData: true,
        );
      } catch (_) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          withData: true,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String ext = (file.extension ?? '').toLowerCase();

        if (ext.isNotEmpty && !['pdf', 'xlsx', 'xls', 'csv'].contains(ext)) {
          setState(() {
            _errorMessage =
                'Invalid file format (.$ext). Please select a PDF, XLSX, XLS, or CSV file.';
          });
          return;
        }

        setState(() {
          _selectedFile = file;
          _isProcessing = true;
        });

        List<ExtractedTransaction> parsed =
            await FileParserService.parseStatementFile(file);

        setState(() {
          _extractedTransactions = parsed;
          _isProcessing = false;
          if (parsed.isEmpty) {
            _errorMessage =
                'No transactions could be extracted from this file. Please check file format.';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        if (e.toString().contains('MissingPluginException')) {
          _errorMessage =
              'MissingPluginException: Please fully stop and restart/rebuild the app on your phone so the new native file picker plugin registers.';
        } else {
          _errorMessage = 'Error reading file: $e';
        }
      });
    }
  }

  double get _totalCredit => _extractedTransactions
      .where((t) => t.isSelected && t.isCredit)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalDebit => _extractedTransactions
      .where((t) => t.isSelected && !t.isCredit)
      .fold(0.0, (sum, t) => sum + t.amount);

  int get _selectedCount =>
      _extractedTransactions.where((t) => t.isSelected).length;

  List<ExtractedTransaction> get _filteredTransactions {
    if (_selectedFilter == 'Credit') {
      return _extractedTransactions.where((t) => t.isCredit).toList();
    } else if (_selectedFilter == 'Debit') {
      return _extractedTransactions.where((t) => !t.isCredit).toList();
    }
    return _extractedTransactions;
  }

  void _toggleSelectAll(bool select) {
    setState(() {
      for (var t in _extractedTransactions) {
        t.isSelected = select;
      }
    });
  }

  void _confirmAndImport() async {
    final selectedList =
        _extractedTransactions.where((t) => t.isSelected).toList();
    if (selectedList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one transaction to import.')),
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    int creditCount = 0;
    int debitCount = 0;

    for (var item in selectedList) {
      if (item.isCredit) {
        creditCount++;
        if (userId.isNotEmpty) {
          context.read<IncomeBloc>().add(
                AddIncome(
                  income: IncomeModel(
                    userId: userId,
                    accountName: 'Bank Statement',
                    amount: item.amount,
                    source: item.category,
                    date: item.date,
                    description: item.title,
                  ),
                  accountId: item.accountId ?? '',
                ),
              );
        }
      } else {
        debitCount++;
        if (userId.isNotEmpty) {
          context.read<ExpenseBloc>().add(
                AddExpense(
                  ExpenseModel(
                    title: item.title,
                    amount: item.amount,
                    category: item.category,
                    date: item.date,
                    userId: userId,
                    description: 'Imported from ${item.rawDescription ?? "Statement"}',
                  ),
                ),
              );
        }
      }
    }

    // Refresh Blocs
    if (userId.isNotEmpty) {
      context.read<ExpenseBloc>().add(LoadExpenses());
      context.read<IncomeBloc>().add(LoadIncome());
    }

    _showThankYouDialog(selectedList.length, creditCount, debitCount);
  }

  void _showThankYouDialog(int total, int credits, int debits) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thank You!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Successfully extracted and imported $total transactions.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatBadge('$credits Credits', Colors.green),
                  _buildStatBadge('$debits Debits', Colors.red),
                ],
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to settings screen
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardBg = isDark ? const Color(0xFF161722) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload Statement Files',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. File Upload Dropzone Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_rounded,
                      size: 44,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFile == null
                        ? 'Upload Bank or Credit Card Statement'
                        : _selectedFile!.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Supported formats: PDF, XLSX, XLS, CSV',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickAndParseFile,
                    icon: const Icon(Icons.file_present_rounded),
                    label: Text(
                      _selectedFile == null ? 'Select Statement File' : 'Change File',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_isProcessing) ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppConstants.primaryColor),
                    const SizedBox(height: 16),
                    const Text(
                      'Reading statement & extracting transactions...',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],

            if (!_isProcessing && _extractedTransactions.isNotEmpty) ...[
              const SizedBox(height: 20),

              // 2. Summary Overview Cards (Credits & Debits)
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Income (Credit)',
                      '+ ₹${_totalCredit.toStringAsFixed(2)}',
                      Colors.green,
                      Icons.arrow_downward_rounded,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Expense (Debit)',
                      '- ₹${_totalDebit.toStringAsFixed(2)}',
                      Colors.red,
                      Icons.arrow_upward_rounded,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Filter Bar & Bulk Actions
              Row(
                children: [
                  _buildFilterChip('All', _extractedTransactions.length),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Credit',
                    _extractedTransactions.where((t) => t.isCredit).length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Debit',
                    _extractedTransactions.where((t) => !t.isCredit).length,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      bool allSelected =
                          _extractedTransactions.every((t) => t.isSelected);
                      _toggleSelectAll(!allSelected);
                    },
                    child: Text(
                      _extractedTransactions.every((t) => t.isSelected)
                          ? 'Deselect All'
                          : 'Select All',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Extracted Transaction Cards List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredTransactions.length,
                itemBuilder: (context, index) {
                  final tx = _filteredTransactions[index];
                  return _buildTransactionCard(tx, cardBg, isDark);
                },
              ),

              const SizedBox(height: 80), // Space for bottom button
            ],
          ],
        ),
      ),

      // Bottom Confirm & Import Action Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (!_isProcessing && _extractedTransactions.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _confirmAndImport,
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: Text(
                  'Confirm & Import ($_selectedCount Transactions)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSummaryCard(
    String label,
    String amountStr,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amountStr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterName, int count) {
    bool isSelected = _selectedFilter == filterName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterName;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$filterName ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
      ExtractedTransaction tx, Color cardBg, bool isDark) {
    Color typeColor = tx.isCredit ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tx.isSelected
              ? typeColor.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.2),
          width: tx.isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Row 1: Checkbox, Icon, Payee Title (Expanded), Delete Button
          Row(
            children: [
              Checkbox(
                value: tx.isSelected,
                activeColor: typeColor,
                onChanged: (val) {
                  setState(() {
                    tx.isSelected = val ?? false;
                  });
                },
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tx.isCredit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: typeColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: tx.title,
                  onChanged: (val) => tx.title = val,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _extractedTransactions
                        .removeWhere((item) => item.id == tx.id);
                  });
                },
              ),
            ],
          ),

          const Divider(height: 12, thickness: 0.5),

          // Row 2: Date & Category (Left), Amount & Type Badge (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Date & Category Dropdown
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(tx.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: DropdownButton<String>(
                        value: _categories.contains(tx.category)
                            ? tx.category
                            : (tx.isCredit ? 'Income' : 'Expense'),
                        isDense: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 16),
                        items: _categories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (newCat) {
                          if (newCat != null) {
                            setState(() {
                              tx.category = newCat;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right: Amount Input & Credit/Debit Toggle Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 85,
                    child: TextFormField(
                      initialValue: tx.amount.toStringAsFixed(2),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textAlign: TextAlign.right,
                      onChanged: (val) {
                        tx.amount = double.tryParse(val) ?? tx.amount;
                      },
                      decoration: const InputDecoration(
                        prefixText: '₹',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 2),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: typeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        tx.isCredit = !tx.isCredit;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tx.isCredit ? 'CREDIT' : 'DEBIT',
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
