import 'package:flutter/material.dart';

/// Reusable widget for feature flag toggles.
/// 
/// Provides switches for:
/// - enableDrag: Enable/disable dragging stamps
/// - enableResize: Enable/disable resizing stamps
/// - enableRotate: Enable/disable rotating stamps
/// - enableSelection: Enable/disable selecting stamps
class FeatureTogglePanel extends StatelessWidget {
  final bool enableDrag;
  final bool enableResize;
  final bool enableRotate;
  final bool enableSelection;
  final ValueChanged<bool>? onDragChanged;
  final ValueChanged<bool>? onResizeChanged;
  final ValueChanged<bool>? onRotateChanged;
  final ValueChanged<bool>? onSelectionChanged;

  const FeatureTogglePanel({
    super.key,
    required this.enableDrag,
    required this.enableResize,
    required this.enableRotate,
    required this.enableSelection,
    this.onDragChanged,
    this.onResizeChanged,
    this.onRotateChanged,
    this.onSelectionChanged,
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
              'Feature Flags',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildToggle(
              label: 'Enable Drag',
              value: enableDrag,
              onChanged: onDragChanged,
              icon: Icons.drag_handle,
            ),
            _buildToggle(
              label: 'Enable Resize',
              value: enableResize,
              onChanged: onResizeChanged,
              icon: Icons.aspect_ratio,
            ),
            _buildToggle(
              label: 'Enable Rotate',
              value: enableRotate,
              onChanged: onRotateChanged,
              icon: Icons.rotate_right,
            ),
            _buildToggle(
              label: 'Enable Selection',
              value: enableSelection,
              onChanged: onSelectionChanged,
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

