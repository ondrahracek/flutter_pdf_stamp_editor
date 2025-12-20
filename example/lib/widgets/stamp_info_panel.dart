import 'package:flutter/material.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

/// Reusable widget to display stamp information.
/// 
/// Shows:
/// - Total stamp count
/// - Selected indices
/// - Current stamps list (optional)
class StampInfoPanel extends StatelessWidget {
  final List<PdfStamp> stamps;
  final Set<int> selectedIndices;
  final bool showStampsList;

  const StampInfoPanel({
    super.key,
    required this.stamps,
    required this.selectedIndices,
    this.showStampsList = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Stamp Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Total Stamps', stamps.length.toString()),
            _buildInfoRow(
              'Selected',
              selectedIndices.isEmpty
                  ? 'None'
                  : (selectedIndices.toList()..sort()).toString(),
            ),
            if (selectedIndices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Selected indices: ${selectedIndices.toList()..sort()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            if (showStampsList && stamps.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Stamps:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ...stamps.asMap().entries.map((entry) {
                final index = entry.key;
                final stamp = entry.value;
                final isSelected = selectedIndices.contains(index);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        size: 16,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '[$index] ${stamp is ImageStamp ? "Image" : "Text"} - Page ${stamp.pageIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

