import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/design_system.dart';
import '../../core/utils/barcode_validator.dart';
import '../../core/widgets/responsive_content.dart';
import '../../data/providers.dart';

class ManualBarcodeEntryScreen extends ConsumerStatefulWidget {
  const ManualBarcodeEntryScreen({super.key});

  @override
  ConsumerState<ManualBarcodeEntryScreen> createState() =>
      _ManualBarcodeEntryScreenState();
}

class _ManualBarcodeEntryScreenState
    extends ConsumerState<ManualBarcodeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  var _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookUpProduct() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_loading) return;

    final barcode = _cleanBarcode(_controller.text);
    setState(() => _loading = true);
    try {
      await ref.read(productRepositoryProvider).getProduct(barcode);
      if (!mounted) return;
      context.push('/product/$barcode');
    } on AppException catch (error) {
      if (!mounted) return;
      switch (error.type) {
        case AppErrorType.productNotFound:
          context.push('/not-found/$barcode');
        case AppErrorType.noInternet:
          setState(() => _errorMessage = 'No internet connection.');
        case AppErrorType.timeout:
          setState(() => _errorMessage = 'Request timed out. Try again.');
        case AppErrorType.invalidBarcode:
          setState(() => _errorMessage = 'Enter a valid numeric barcode.');
        case AppErrorType.invalidApiResponse:
        case AppErrorType.unknown:
        case AppErrorType.cameraPermissionDenied:
        case AppErrorType.cameraUnavailable:
        case AppErrorType.productDataIncomplete:
          setState(
            () => _errorMessage =
                'Product information is temporarily unavailable.',
          );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateBarcode(String? value) {
    final clean = _cleanBarcode(value ?? '');
    if (clean.isEmpty) return 'Enter a barcode.';
    if (!RegExp(r'^[0-9]+$').hasMatch(clean)) {
      return 'Use numbers only.';
    }
    if (!BarcodeValidator.isValid(clean)) {
      return 'Enter 8 to 14 digits.';
    }
    return null;
  }

  String _cleanBarcode(String value) => value.replaceAll(RegExp(r'\s+'), '');

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpacing.xl;
    final horizontalPadding = ResponsiveInsets.horizontal(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Enter barcode')),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 650,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              bottom,
            ),
            children: [
              Form(
                key: _formKey,
                child: TextFormField(
                  key: const ValueKey('manual_barcode_field'),
                  controller: _controller,
                  autofocus: true,
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.search,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    hintText: 'Example: 0123456789012',
                  ),
                  validator: _validateBarcode,
                  onFieldSubmitted: (_) => _lookUpProduct(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                key: const ValueKey('manual_lookup_action'),
                onPressed: _loading ? null : _lookUpProduct,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: const Text('Look up product'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                key: const ValueKey('manual_scan_with_camera_action'),
                onPressed: _loading ? null : () => context.go('/scanner'),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan with camera'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(_errorMessage!)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
