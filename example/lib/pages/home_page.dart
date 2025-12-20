import 'package:flutter/material.dart';
import 'basic_demo_page.dart';
import 'controller_demo_page.dart';
import 'features_demo_page.dart';
import 'callbacks_demo_page.dart';
import 'custom_builder_demo_page.dart';
import 'utilities_demo_page.dart';
import 'full_feature_demo_page.dart';
import 'edge_cases_performance_demo_page.dart';

/// Home/landing page with navigation to all demo pages.
/// 
/// This page serves as the entry point for exploring all features
/// and APIs of the pdf_stamp_editor package.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Stamp Editor Examples'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Welcome to PDF Stamp Editor Examples',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore all features and APIs of the pdf_stamp_editor package.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildDemoCard(
            context,
            title: 'Basic Demo',
            description: 'Simple example demonstrating basic stamp placement and export functionality.',
            icon: Icons.description,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BasicDemoPage(),
                ),
              );
            },
            available: true,
          ),
          _buildDemoCard(
            context,
            title: 'Controller Demo',
            description: 'Demonstrate PdfStampEditorController API with programmatic stamp manipulation, selection, and state management.',
            icon: Icons.settings,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ControllerDemoPage(),
                ),
              );
            },
            available: true,
          ),
          _buildDemoCard(
            context,
            title: 'Features Demo',
            description: 'Test feature flags: enableDrag, enableResize, enableRotate, enableSelection with interactive toggles.',
            icon: Icons.toggle_on,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeaturesDemoPage(),
                ),
              );
            },
            available: true,
          ),
          _buildDemoCard(
            context,
            title: 'Callbacks Demo',
            description: 'Explore all callback APIs: onStampsChanged, onStampSelected, onStampUpdated, onStampDeleted, onTapDown, onLongPressDown.',
            icon: Icons.notifications,
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CallbacksDemoPage(),
                ),
              );
            },
            available: true,
          ),
          _buildDemoCard(
            context,
            title: 'Custom Builder Demo',
            description: 'Learn how to customize stamp rendering with custom stampBuilder parameter for ImageStamp and TextStamp.',
            icon: Icons.brush,
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomBuilderDemoPage(),
                ),
              );
            },
            available: true,
          ),
          _buildDemoCard(
            context,
            title: 'Utilities Demo',
            description: 'Test coordinate conversion utilities (PdfCoordinateConverter) and matrix calculation (MatrixCalculator).',
            icon: Icons.calculate,
            color: Colors.indigo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UtilitiesDemoPage(),
                ),
              );
            },
            available: true,
          ),
          _buildDemoCard(
            context,
            title: 'Full Feature Demo',
            description: 'Comprehensive demo with all features enabled: controller, all feature flags, all callbacks working together.',
            icon: Icons.star,
            color: Colors.amber,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FullFeatureDemoPage(),
                ),
              );
            },
            available: true,
          ),
          _buildDemoCard(
            context,
            title: 'Edge Cases & Performance',
            description: 'Test edge cases, performance with many stamps, multi-page scenarios, and stress testing.',
            icon: Icons.speed,
            color: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EdgeCasesPerformanceDemoPage(),
                ),
              );
            },
            available: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool available,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: InkWell(
        onTap: available ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!available) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Coming Soon',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (available)
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

}

