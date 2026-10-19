import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ngekas/bloc/auth/auth_cubit.dart';
import 'package:ngekas/bloc/cashier/cashier_cubit.dart';
import 'package:ngekas/const/app_date_const.dart';
import 'package:ngekas/screen/cashier/cashier_screen.dart';
import 'package:ngekas/screen/cashier/product_picker_sheet.dart';
import 'package:ngekas/screen/home/home_tab.dart';
import 'package:ngekas/screen/home_screen.dart';
import 'package:ngekas/screen/product/product_screen.dart';
import 'package:ngekas/services/database_service.dart';
import 'package:ngekas/services/navigation_services.dart';

// Smoke test: render layar-layar utama di ukuran HP untuk menangkap error
// layout (overflow, dsb) untuk kedua role.

void main() {
  Future<AuthCubit> pumpHome(WidgetTester tester, String username) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    DatabaseService.instance.reset();
    final cubit = AuthCubit();
    await tester.runAsync(() => cubit.login(username: username, password: 'admin123'));
    expect(cubit.state.status, AuthStatus.loginSuccess);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider(create: (_) => CashierCubit()),
        ],
        child: MaterialApp(navigatorKey: NavigationService.get().navigatorKey, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  for (final username in ['admin', 'kasir']) {
    testWidgets('semua tab & kasir tampil tanpa error ($username)', (tester) async {
      await pumpHome(tester, username);

      // Beranda: total penjualan hari ini + barang paling laku (data awal:
      // hari ini terjual Oli Mesin Matic x3 & Busi Motor Standar x2).
      expect(find.text('Total Penjualan · ${AppDate.format(DateTime.now())}'), findsOneWidget);
      expect(find.text('Barang Paling Laku'), findsOneWidget);
      expect(find.text('3 terjual'), findsOneWidget);

      // Toggle ke Bulanan.
      await tester.tap(find.text('Bulanan'));
      await tester.pumpAndSettle();
      expect(find.text('Total Penjualan · ${AppDate.monthYear(DateTime.now())}'), findsOneWidget);

      // Tombol "Gudang" di Beranda pindah ke tab Gudang.
      await tester.tap(find.descendant(of: find.byType(HomeTab), matching: find.text('Gudang')));
      await tester.pumpAndSettle();
      expect(find.text('8997011930011'), findsOneWidget);

      // Barang tanpa barcode ditandai "Tanpa barcode".
      await tester.enterText(find.byType(TextField).first, 'Ban Dalam');
      await tester.pumpAndSettle();
      expect(find.text('Tanpa barcode'), findsOneWidget);

      // Cari pakai barcode -> hanya barang itu yang tampil.
      await tester.enterText(find.byType(TextField).first, '8997011930011');
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(ProductScreen), matching: find.text('Oli Mesin Matic 0.8L')), findsOneWidget);
      expect(find.text('Busi Motor Standar'), findsNothing);
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();

      for (final tab in ['Laporan', 'Profil', 'Beranda']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byTooltip('Kasir'));
      await tester.pumpAndSettle();
      expect(find.byType(CashierScreen), findsOneWidget);

      // Pilih Manual -> pilih barang -> isi jumlah -> masuk keranjang.
      await tester.tap(find.text('Pilih Manual'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(ProductPickerSheet), matching: find.text('Oli Mesin Matic 0.8L')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Masukkan ke Keranjang'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.payments_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Pembayaran'), findsOneWidget);
    });
  }
}
