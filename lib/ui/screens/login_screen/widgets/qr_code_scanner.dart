import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/util/logger.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QRCodeScanner extends ConsumerStatefulWidget {
  const QRCodeScanner({required this.onScan, super.key});

  final void Function(String) onScan;

  @override
  ConsumerState<QRCodeScanner> createState() => _QRCodeScannerState();
}

class _QRCodeScannerState extends ConsumerState<QRCodeScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  static bool torchEnabled = false;
  static CameraFacing cameraFacing = CameraFacing.back;

  QRViewController? cameraController;

  @override
  void reassemble() {
    super.reassemble();
    // Required hot-reload workaround per package docs
    if (Platform.isAndroid) {
      cameraController?.pauseCamera();
    }
    cameraController?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: 300,
        width: 300,

        child: Stack(
          children: [
            QRView(
              key: qrKey,
              onQRViewCreated: (QRViewController p1) {
                cameraController = p1;
                cameraController?.scannedDataStream.listen(
                    (barcode) {
                      if (barcode.code != null) {
                        getLogger().i("Barcode found: ${barcode.code}");
                        widget.onScan(barcode.code!);
                      }
                    }
                );
              },
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                children: [
                  IconButton(
                    color: Colors.white,
                    iconSize: 32.0,
                    icon: torchEnabled
                        ? const Icon(Icons.flash_on, color: Colors.yellow)
                        : const Icon(Icons.flash_off, color: Colors.grey),
                    onPressed: () {
                      cameraController?.toggleFlash();
                      torchEnabled = !torchEnabled;
                    },
                  ),
                  IconButton(
                    color: Colors.white,
                    iconSize: 32.0,
                    icon: cameraFacing == CameraFacing.back
                        ? const Icon(Icons.camera_rear)
                        : const Icon(Icons.camera_front),
                    onPressed: () {
                      cameraController?.flipCamera();
                      cameraFacing = cameraFacing == CameraFacing.back ? CameraFacing.front : CameraFacing.back;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
