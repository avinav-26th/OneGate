import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light/light.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../visitors/presentation/controllers/visitor_providers.dart';
import '../../visitors/presentation/screens/visitor_details_screen.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

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

  bool _isProcessing = false;
  final TextEditingController _manualIdController = TextEditingController();
  StreamSubscription<int>? _lightSubscription;
  bool _autoTorchActive = false;

  @override
  void initState() {
    super.initState();
    _initLightSensor();
  }

  void _initLightSensor() {
    try {
      _lightSubscription = Light().lightSensorStream.listen((lux) {
        if (!mounted) return;
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
    super.dispose();
  }

  Future<void> _handleBarcode(String rawValue) async {
    if (_isProcessing) return;

    final id = rawValue.trim();
    if (id.isEmpty) return;

    setState(() => _isProcessing = true);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visitor with ID "$id" not found in registry'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        _scannerController.start();
      }
    }
  }

  void _showManualLookupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        title: const Text(
          'Manual Pass Lookup',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF142B3B),
            letterSpacing: -0.3,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the visitor pass identifier to verify access details.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualIdController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF142B3B),
              ),
              decoration: InputDecoration(
                labelText: 'Visitor Pass ID',
                hintText: 'e.g. VIS001',
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF142B3B)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFF38DCC0), width: 2),
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
              foregroundColor: const Color(0xFF64748B),
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
              backgroundColor: const Color(0xFF142B3B),
              foregroundColor: Colors.white,
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
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(0xFFF4F7F8),
        title: const Text('Scan Gate Pass'),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _scannerController,
            builder: (context, state, child) {
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: isTorchOn ? const Color(0xFF38DCC0) : const Color(0xFF142B3B),
                ),
                onPressed: () {
                  _autoTorchActive = false;
                  _scannerController.toggleTorch();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Color(0xFF142B3B)),
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
                      const Text(
                        'Camera Access Denied or Unavailable',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please grant camera permissions or use manual pass lookup.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF38DCC0), width: 2.5),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Positioned(
            bottom: 36,
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
                    'Align visitor QR code within the frame',
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
                  icon: const Icon(Icons.keyboard_alt_outlined, size: 18, color: Color(0xFF142B3B)),
                  label: const Text(
                    'Manual Entry',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF142B3B),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF142B3B),
                    elevation: 4,
                    shadowColor: Colors.black38,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
