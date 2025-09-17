import 'package:flutter_bloc/flutter_bloc.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc() : super(ReportInitial()) {
    on<GenerateReport>((event, emit) {
      emit(ReportLoaded("Report for ${event.month}/${event.year}"));
    });
  }
}
