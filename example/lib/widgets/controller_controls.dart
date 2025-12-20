import 'package:flutter/material.dart';
import 'package:pdf_stamp_editor/pdf_stamp_editor.dart';

/// Reusable widget with buttons for controller operations.
/// 
/// Provides buttons for:
/// - addStamp: Add a new stamp
/// - updateStamp: Update an existing stamp
/// - removeStamp: Remove a stamp by index
/// - clearStamps: Clear all stamps
/// - selectStamp: Select a stamp by index
/// - clearSelection: Clear selection
/// - deleteSelectedStamps: Delete all selected stamps
class ControllerControls extends StatelessWidget {
  final PdfStampEditorController? controller;
  final VoidCallback? onAddStamp;
  final VoidCallback? onUpdateStamp;
  final VoidCallback? onRemoveStamp;
  final VoidCallback? onClearStamps;
  final VoidCallback? onSelectStamp;
  final VoidCallback? onClearSelection;
  final VoidCallback? onDeleteSelected;

  const ControllerControls({
    super.key,
    this.controller,
    this.onAddStamp,
    this.onUpdateStamp,
    this.onRemoveStamp,
    this.onClearStamps,
    this.onSelectStamp,
    this.onClearSelection,
    this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasStamps = controller?.stamps.isNotEmpty ?? false;
    final hasSelection = controller?.selectedIndices.isNotEmpty ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Controller Operations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildButton(
                  label: 'Add Stamp',
                  icon: Icons.add,
                  onPressed: onAddStamp,
                  color: Colors.green,
                ),
                _buildButton(
                  label: 'Update Stamp',
                  icon: Icons.edit,
                  onPressed: hasStamps ? onUpdateStamp : null,
                  color: Colors.blue,
                ),
                _buildButton(
                  label: 'Remove Stamp',
                  icon: Icons.remove,
                  onPressed: hasStamps ? onRemoveStamp : null,
                  color: Colors.orange,
                ),
                _buildButton(
                  label: 'Clear All',
                  icon: Icons.clear_all,
                  onPressed: hasStamps ? onClearStamps : null,
                  color: Colors.red,
                ),
                _buildButton(
                  label: 'Select Stamp',
                  icon: Icons.check_circle,
                  onPressed: hasStamps ? onSelectStamp : null,
                  color: Colors.purple,
                ),
                _buildButton(
                  label: 'Clear Selection',
                  icon: Icons.cancel_outlined,
                  onPressed: hasSelection ? onClearSelection : null,
                  color: Colors.grey,
                ),
                _buildButton(
                  label: 'Delete Selected',
                  icon: Icons.delete,
                  onPressed: hasSelection ? onDeleteSelected : null,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        disabledBackgroundColor: Colors.grey.withOpacity(0.1),
        disabledForegroundColor: Colors.grey,
      ),
    );
  }
}

