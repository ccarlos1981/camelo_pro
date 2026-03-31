import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/products_provider.dart';

/// Tela de scanner de código de barras via câmera.
///
/// Fluxo:
/// 1. Escaneia o barcode
/// 2. Busca no banco do usuário
/// 3. Se achar → abre edição
/// 4. Se não achar → abre cadastro com barcode pré-preenchido
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  String? _lastScannedBarcode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;
    if (barcode == _lastScannedBarcode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedBarcode = barcode;
    });

    // Vibração de feedback
    HapticFeedback.mediumImpact();

    try {
      // Busca no banco
      final existing = await ref.read(productsProvider.notifier).findByBarcode(barcode);

      if (!mounted) return;

      if (existing != null) {
        // Produto encontrado → edição
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produto encontrado: ${existing.name}'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 1),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.pop(); // volta do scanner
          context.push('/products/edit', extra: existing);
        }
      } else {
        // Produto novo → cadastro com barcode
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Novo código! Cadastre o produto.'),
            backgroundColor: Color(0xFFF59E0B),
            duration: Duration(seconds: 1),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.pop(); // volta do scanner
          context.push('/products/add', extra: barcode);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final scanArea = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scanner'),
        actions: [
          // Toggle flash
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: state.torchState == TorchState.on
                      ? const Color(0xFFF59E0B)
                      : Colors.white,
                ),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
          // Switch camera
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay com guia visual
          CustomPaint(
            painter: _ScanOverlayPainter(scanArea: scanArea),
            child: const SizedBox.expand(),
          ),

          // Instrução no topo
          Positioned(
            top: 24,
            left: 32,
            right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isProcessing
                    ? 'Buscando produto...'
                    : 'Aponte a câmera para o código de barras',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}

/// Overlay que desenha um quadrado com cantos arredondados e escurece o resto.
class _ScanOverlayPainter extends CustomPainter {
  final double scanArea;
  _ScanOverlayPainter({required this.scanArea});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(center: center, width: scanArea, height: scanArea);

    // Escurece tudo
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black45,
    );

    // Limpa a área do scan
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      Paint()
        ..blendMode = BlendMode.clear,
    );

    // Desenha bordas estilizadas nos cantos
    final borderPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;
    const radius = 20.0;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerLength)
        ..lineTo(rect.left, rect.top + radius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + radius, rect.top)
        ..lineTo(rect.left + cornerLength, rect.top),
      borderPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.top)
        ..lineTo(rect.right - radius, rect.top)
        ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius)
        ..lineTo(rect.right, rect.top + cornerLength),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cornerLength)
        ..lineTo(rect.left, rect.bottom - radius)
        ..quadraticBezierTo(rect.left, rect.bottom, rect.left + radius, rect.bottom)
        ..lineTo(rect.left + cornerLength, rect.bottom),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.bottom)
        ..lineTo(rect.right - radius, rect.bottom)
        ..quadraticBezierTo(rect.right, rect.bottom, rect.right, rect.bottom - radius)
        ..lineTo(rect.right, rect.bottom - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
