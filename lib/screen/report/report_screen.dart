import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/transaction/transaction_cubit.dart';
import 'package:ngekas/models/category_model.dart';
import 'package:ngekas/screen/report/report_view.dart';

class ReportScreen extends StatelessWidget {
  final CategoryType type;

  const ReportScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final ownerId = context.read<AuthCubit>().state.user!.ownerId;
    return BlocProvider(
      create: (_) => TransactionCubit(ownerId: ownerId, type: type)..watch(),
      child: ReportView(type: type, ownerId: ownerId),
    );
  }
}
