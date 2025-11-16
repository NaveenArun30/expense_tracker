import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Upload Expense File")),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                if (kIsWeb) {
                  // Web fallback
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles();
                  if (result != null) {
                    context.read<ReportBloc>().add(
                      UploadFile(result.files.single.name),
                    );
                  }
                  return;
                }

                // Mobile and desktop
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  allowedExtensions: ['csv', 'xlsx', 'pdf'],
                  type: FileType.custom,
                );
                if (result != null) {
                  context.read<ReportBloc>().add(
                    UploadFile(result.files.single.path!),
                  );
                }
              },

              child: const Text("Upload File"),
            ),

            Expanded(
              child: BlocBuilder<ReportBloc, ReportState>(
                builder: (context, state) {
                  if (state is ReportLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ReportLoaded) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Income: ₹${state.totalIncome}",
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text(
                            "Total Expense: ₹${state.totalExpense}",
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Category Breakdown:",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              children: state.categoryBreakdown.entries
                                  .map(
                                    (e) => ListTile(
                                      title: Text(e.key),
                                      trailing: Text(
                                        "₹${e.value.toStringAsFixed(2)}",
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (state is ReportError) {
                    return Center(child: Text(state.message));
                  }

                  return const Center(
                    child: Text("Upload a file to get stats"),
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
