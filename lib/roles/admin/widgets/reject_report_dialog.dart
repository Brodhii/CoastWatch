import 'package:flutter/material.dart';

class RejectReportDialog extends StatefulWidget {
  final String reportId;
  final Future<void> Function(String reason) onConfirmReject;

  const RejectReportDialog({
    super.key,
    required this.reportId,
    required this.onConfirmReject,
  });

  static Future<void> show(
    BuildContext context, {
    required String reportId,
    required Future<void> Function(String reason) onConfirmReject,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RejectReportDialog(
        reportId: reportId,
        onConfirmReject: onConfirmReject,
      ),
    );
  }

  @override
  State<RejectReportDialog> createState() => _RejectReportDialogState();
}

class _RejectReportDialogState extends State<RejectReportDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  final List<String> _quickReasons = [
    'Objek sampah tidak fokus & metadata tidak konsisten',
    'Lokasi berada di luar cakupan pesisir/pantai',
    'Foto bukan merupakan bukti masalah lingkungan pesisir',
    'Foto kabur atau terindikasi tangkapan layar tanpa EXIF valid',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _reasonController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorText = 'Alasan penolakan wajib diisi secara jelas & transparan.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.onConfirmReject(text);
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
        'Tolak Laporan #${widget.reportId}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Keputusan penolakan wajib disertai alasan transparan yang dapat dilihat oleh pelapor pada riwayat tiket.',
              style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 14),

            const Text(
              'Pilih Alasan Standar:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickReasons.map((reason) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _reasonController.text = reason;
                      _errorText = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      reason,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),
            const Text(
              'Uraian Alasan Penolakan (Wajib):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan penolakan secara jelas dan edukatif...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                errorText: _errorText,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
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
            backgroundColor: const Color(0xFFDC2626),
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
              : const Text('Konfirmasi Penolakan', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
