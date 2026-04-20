import 'package:flutter/material.dart';

import '../../../reports/models/report.dart';

/// Floating card displaying report title and category.
class MainInfoCard extends StatelessWidget {
  final Report report;

  const MainInfoCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      transform: Matrix4.translationValues(0, -40, 0),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            report.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0033CC),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Category Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.label_important,
                    color: Color(0xFF0033CC), size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      fontFamily: 'Inter',
                    ),
                    children: [
                      const TextSpan(text: 'Phân loại: '),
                      TextSpan(
                        text: report.categoryName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
