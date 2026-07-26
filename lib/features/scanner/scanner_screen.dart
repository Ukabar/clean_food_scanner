import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/design_system.dart';
import '../../core/utils/barcode_validator.dart';
import '../../core/widgets/responsive_content.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final _controller = MobileScannerController();
  String? _lastBarcode;
  DateTime? _lastScanAt;
  var _handling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed && mounted) {
      _controller.start();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    _submit(raw);
  }

  Future<void> _submit(String barcode) async {
    final clean = barcode.trim();
    final now = DateTime.now();
    if (!BarcodeValidator.isValid(clean)) {
      _showMessage('Invalid barcode.');
      return;
    }
    if (_handling) return;
    if (_lastBarcode == clean &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < AppConstants.scanDebounce) {
      return;
    }
    _handling = true;
    if (mounted) setState(() {});
    _lastBarcode = clean;
    _lastScanAt = now;
    await _controller.stop();
    if (mounted) {
      context.push('/product/$clean').whenComplete(() {
        _handling = false;
        if (mounted) {
          setState(() {});
          _controller.start();
        }
      });
    }
  }

  Future<void> _openManualEntry() async {
    await _controller.stop();
    if (!mounted) return;
    await context.push('/manual-barcode');
    if (mounted) await _controller.start();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;
    final guideWidth = (shortestSide * 0.72).clamp(240.0, 360.0);
    final guideHeight = guideWidth * 0.64;
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.20),
                ),
                child: Center(
                  child: Container(
                    width: guideWidth,
                    height: guideHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  IconButton.filled(
                    tooltip: 'Close',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                  ),
                  const Spacer(),
                  IconButton.filled(
                    tooltip: 'Flash',
                    onPressed: _controller.toggleTorch,
                    icon: const Icon(Icons.flash_on_outlined),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    tooltip: 'Enter barcode manually',
                    onPressed: _openManualEntry,
                    icon: const Icon(Icons.keyboard_outlined),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 24,
            child: ResponsiveContent(
              maxWidth: 520,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _handling
                        ? 'Looking up product...'
                        : 'Align the barcode inside the frame.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
          if (_handling)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.18),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
