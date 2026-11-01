import 'package:flutter/material.dart';

class DuplicateReportDialog extends StatefulWidget {
  final String reportId;
  final Future<void> Function(String originalId, String notes) onConfirmDuplicate;

  const DuplicateReportDialog({
    super.key,
    required this.reportId,
    required this.onConfirmDuplicate,
  });

  static Future<void> show(
    BuildContext context, {
    required String reportId,
    required Future<void> Function(String originalId, String notes) onConfirmDuplicate,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DuplicateReportDialog(
        reportId: reportId,
        onConfirmDuplicate: onConfirmDuplicate,
      ),
    );
  }

  @override
  State<DuplicateReportDialog> createState() => _DuplicateReportDialogState();
}

class _DuplicateReportDialogState extends State<DuplicateReportDialog> {
  final TextEditingController _refIdController = TextEditingController(text: 'CW-2026-00115');
  final TextEditingController _notesController = TextEditingController(
    text: 'Radius lokasi identik (< 8 meter) dan waktu kejadian berdekatan.',
  );

  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _refIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    final refId = _refIdController.text.trim();
    if (refId.isEmpty) {
      setState(() {
        _errorText = 'Nomor tiket laporan utama/asli wajib diisi.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.onConfirmDuplicate(refId, _notesController.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorText = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(
        'Tandai Duplikat #${widget.reportId}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laporan yang merujuk pada temuan sampah yang sama akan ditautkan ke tiket utama dan tidak ditampilkan terpisah pada peta publik.',
              style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 16),

            const Text(
              'Nomor Tiket Laporan Utama (Referensi):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _refIdController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Contoh: CW-2026-00115',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                errorText: _errorText,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
            ),

            const SizedBox(height: 14),
            const Text(
              'Catatan Kesamaan Spasial / Bukti:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Radius lokasi < 10m, objek serupa...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            elevation: 0,
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Tandai Duplikat', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
