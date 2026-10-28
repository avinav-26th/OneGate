import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light/light.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../visitors/presentation/controllers/visitor_providers.dart';
import '../../visitors/presentation/screens/visitor_details_screen.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final bool isActive;

  const QrScannerScreen({super.key, this.isActive = true});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with AutomaticKeepAliveClientMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  @override
  bool get wantKeepAlive => true;

  final ValueNotifier<bool> _isProcessing = ValueNotifier<bool>(false);
  final TextEditingController _manualIdController = TextEditingController();
  StreamSubscription<int>? _lightSubscription;
  bool _autoTorchActive = false;

  @override
  void initState() {
    super.initState();
    _initLightSensor();
  }

  @override
  void didUpdateWidget(covariant QrScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _scannerController.start();
      } else {
        _scannerController.stop();
        _turnOffTorch();
      }
    }
  }

  void _turnOffTorch() {
    _autoTorchActive = false;
    if (_scannerController.value.torchState == TorchState.on) {
      _scannerController.toggleTorch();
    }
  }

  void _initLightSensor() {
    try {
      _lightSubscription = Light().lightSensorStream.listen((lux) {
        if (!mounted || !widget.isActive) return;
        if (lux >= 0 && lux < 15 && !_autoTorchActive) {
          if (_scannerController.value.torchState == TorchState.off) {
            _autoTorchActive = true;
            _scannerController.toggleTorch();
          }
        } else if (lux > 45 && _autoTorchActive) {
          if (_scannerController.value.torchState == TorchState.on) {
            _autoTorchActive = false;
            _scannerController.toggleTorch();
          }
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _lightSubscription?.cancel();
    _scannerController.dispose();
    _manualIdController.dispose();
    _isProcessing.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(String rawValue) async {
    if (_isProcessing.value) return;

    final id = rawValue.trim();
    if (id.isEmpty) return;

    _isProcessing.value = true;
    await _scannerController.stop();

    try {
      final repository = ref.read(visitorRepositoryProvider);
      final visitor = await repository.getVisitorById(id);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VisitorDetailsScreen(visitor: visitor),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Visitor with ID "$id" not found in registry');
    } finally {
      if (mounted) {
        _isProcessing.value = false;
        _scannerController.start();
      }
    }
  }

  void _showManualLookupDialog() {
    final isDark = AppColors.isDark(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        title: Text(
          'Manual Pass Lookup',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryOf(context),
            letterSpacing: -0.3,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the visitor pass identifier to verify access details.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryOf(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualIdController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
              decoration: InputDecoration(
                labelText: 'Visitor Pass ID',
                labelStyle: TextStyle(color: AppColors.textSecondaryOf(context)),
                hintText: 'e.g. VIS001',
                hintStyle: TextStyle(color: AppColors.textSecondaryOf(context)),
                prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textPrimaryOf(context)),
                filled: true,
                fillColor: AppColors.chipOf(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.borderOf(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.borderOf(context)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: AppColors.mintTeal, width: 2),
                ),
              ),
              onSubmitted: (_) {
                final id = _manualIdController.text.trim();
                Navigator.of(ctx).pop();
                if (id.isNotEmpty) {
                  _manualIdController.clear();
                  _handleBarcode(id);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondaryOf(context),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final id = _manualIdController.text.trim();
              Navigator.of(ctx).pop();
              if (id.isNotEmpty) {
                _manualIdController.clear();
                _handleBarcode(id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.mintTeal : AppColors.navy,
              foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Find Visitor',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.backgroundOf(context),
        title: Text(
          'Scan Gate Pass',
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _scannerController,
            builder: (context, state, child) {
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: isTorchOn ? AppColors.mintTeal : AppColors.textPrimaryOf(context),
                ),
                onPressed: () {
                  _autoTorchActive = false;
                  _scannerController.toggleTorch();
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.flip_camera_ios_rounded, color: AppColors.textPrimaryOf(context)),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final value = barcodes.first.rawValue;
                if (value != null) {
                  _handleBarcode(value);
                }
              }
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 56, color: Color(0xFFDC2626)),
                      const SizedBox(height: 16),
                      Text(
                        'Camera Access Denied or Unavailable',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimaryOf(context)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please grant camera permissions or use manual pass lookup.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _showManualLookupDialog,
                        icon: const Icon(Icons.keyboard_outlined),
                        label: const Text('Enter Pass ID Manually'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Transform.translate(
            offset: const Offset(0, -65),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.mintTeal, width: 2.8),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    AppStrings.alignQr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _showManualLookupDialog,
                  icon: Icon(Icons.keyboard_alt_outlined, size: 18, color: AppColors.textPrimaryOf(context)),
                  label: Text(
                    AppStrings.manualEntry,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceOf(context),
                    foregroundColor: AppColors.textPrimaryOf(context),
                    elevation: 4,
                    shadowColor: Colors.black38,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isProcessing,
            builder: (context, processing, _) {
              if (!processing) return const SizedBox.shrink();
              return Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
