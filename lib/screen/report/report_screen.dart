import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/sales_report/sales_report_cubit.dart';
import 'package:ngekas/screen/report/report_view.dart';

// Laporan Penjualan — wiring BlocProvider; isi layarnya di ReportView.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => SalesReportCubit()..watch(), child: const ReportView());
  }
}
