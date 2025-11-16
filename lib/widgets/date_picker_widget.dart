import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class DateRangePickerWidget extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String title;
  final String confirmButtonText;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateRangePickerWidget({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.title = 'Select Date Range',
    this.confirmButtonText = 'Apply',
    this.firstDate,
    this.lastDate,
  });

  @override
  State<DateRangePickerWidget> createState() => _DateRangePickerWidgetState();
}

class _DateRangePickerWidgetState extends State<DateRangePickerWidget> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _firstDate;
  late DateTime _lastDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    
    // Set default date range (last 5 years to 1 year in future)
    final now = DateTime.now();
    _firstDate = widget.firstDate ?? DateTime(now.year - 5, 1, 1);
    _lastDate = widget.lastDate ?? DateTime(now.year + 1, 12, 31);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildDateSelection(),
            _buildQuickSelectionButtons(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppConstants.primaryGradient,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Start Date',
                  _startDate,
                  (date) => _selectStartDate(date),
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  'End Date',
                  _endDate,
                  (date) => _selectEndDate(date),
                  Icons.event,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_startDate != null && _endDate != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppConstants.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_calculateDaysDifference()} days selected',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? selectedDate,
    Function(DateTime) onDateSelected,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showDatePicker(onDateSelected),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(icon, color: AppConstants.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? DateFormat('MMM dd, yyyy').format(selectedDate)
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedDate != null 
                          ? const Color(0xFF2D3748)
                          : Colors.grey[600],
                      fontWeight: selectedDate != null 
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSelectionButtons() {
    final quickOptions = [
      {'label': 'Last 7 days', 'days': 7},
      {'label': 'Last 30 days', 'days': 30},
      {'label': 'Last 90 days', 'days': 90},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Selection',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickOptions.map((option) {
              return GestureDetector(
                onTap: () => _selectQuickOption(option['days'] as int),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    option['label'] as String,
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool isValidRange = _startDate != null && _endDate != null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isValidRange ? _applyDateRange : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                widget.confirmButtonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: _firstDate,
      lastDate: _lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF2D3748),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        onDateSelected(picked);
      });
    }
  }

  void _selectStartDate(DateTime date) {
    _startDate = date;
    // If end date is before start date, reset it
    if (_endDate != null && _endDate!.isBefore(date)) {
      _endDate = null;
    }
  }

  void _selectEndDate(DateTime date) {
    // Only allow end date if start date is selected and end date is after start date
    if (_startDate != null && !date.isBefore(_startDate!)) {
      _endDate = date;
    } else if (_startDate == null) {
      // If no start date, show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start date first'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // If end date is before start date, show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _selectQuickOption(int days) {
    final now = DateTime.now();
    setState(() {
      _endDate = DateTime(now.year, now.month, now.day);
      _startDate = _endDate!.subtract(Duration(days: days - 1));
    });
  }

  int _calculateDaysDifference() {
    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays + 1;
    }
    return 0;
  }

  void _applyDateRange() {
    if (_startDate != null && _endDate != null) {
      Navigator.of(context).pop(
        DateTimeRange(start: _startDate!, end: _endDate!),
      );
    }
  }
}

// Helper class for better type safety
class DateRangeResult {
  final DateTime startDate;
  final DateTime endDate;

  DateRangeResult({
    required this.startDate,
    required this.endDate,
  });

  int get daysDifference => endDate.difference(startDate).inDays + 1;

  @override
  String toString() {
    return 'DateRange(${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)})';
  }
}