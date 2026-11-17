import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ngekas/const/app_theme_const.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes.map((b) => b.rawValue?.trim() ?? '').where((v) => v.isNotEmpty).firstOrNull;
    if (value == null) return;
    _handled = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Barcode', style: TextStyle(color: Colors.white)),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (state.torchState == TorchState.unavailable) return const SizedBox.shrink();
              final isOn = state.torchState == TorchState.on;
              return IconButton(
                tooltip: isOn ? 'Matikan senter' : 'Nyalakan senter',
                icon: Icon(isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
                onPressed: _controller.toggleTorch,
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
            errorBuilder: (context, error) => _buildError(error),
          ),
          IgnorePointer(child: CustomPaint(painter: _ScanFramePainter())),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              'Arahkan kamera ke barcode di kemasan barang',
              textAlign: TextAlign.center,
              style: AppTextStyle.bodyMd.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(MobileScannerException error) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Izin kamera ditolak. Aktifkan izin kamera untuk aplikasi ini di pengaturan HP, atau ketik barcode secara manual.',
      MobileScannerErrorCode.unsupported => 'Perangkat ini tidak mendukung scan barcode. Ketik barcode secara manual.',
      _ => 'Kamera tidak bisa dibuka. Coba lagi atau ketik barcode secara manual.',
    };

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyle.bodyMd.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width * 0.8;
    const height = 180.0;
    final frame = Rect.fromCenter(center: size.center(Offset.zero), width: width, height: height);
    final frameRRect = RRect.fromRectAndRadius(frame, const Radius.circular(16));

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(frameRRect),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );
    canvas.drawRRect(
      frameRRect,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
