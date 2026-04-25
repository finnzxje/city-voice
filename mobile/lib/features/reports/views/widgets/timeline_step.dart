import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const kTimelineGreen = Color(0xFF1B5E44);
const kTimelineBlue = Color(0xFF2563EB);
const kTimelineOrange = Color(0xFFF59E0B);
const kTimelineGrey = Color(0xFFCBD5E1);
const kTimelineGreyLine = Color(0xFFE2E8F0);
const kTimelineGreenLine = Color(0xFF1B5E44);

/// Visual style for a timeline node.
enum TimelineNodeStyle {
  doneGreen,
  currentBlue,
  currentOrange,
  pendingGrey,
  rejected,
}

/// A single step in the report progress timeline.
class TimelineStep extends StatelessWidget {
  final String title;
  final DateTime? date;
  final String? fallbackSubtitle;
  final TimelineNodeStyle nodeStyle;
  final Color lineColor;
  final bool isLast;
  final bool isResolvedNode;
  final bool isCurrent;

  const TimelineStep({
    super.key,
    required this.title,
    this.date,
    this.fallbackSubtitle,
    required this.nodeStyle,
    required this.lineColor,
    required this.isLast,
    required this.isResolvedNode,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final Color nodeBg;
    final Color titleColor;
    final Color subtitleColor;
    final IconData iconData;
    final Color iconColor;

    final double iconSize = isCurrent ? 16.0 : 12.0;

    switch (nodeStyle) {
      case TimelineNodeStyle.doneGreen:
        nodeBg = kTimelineGreen;
        titleColor = const Color(0xFF1E293B);
        subtitleColor = const Color(0xFF94A3B8);
        iconData = isResolvedNode ? Icons.verified_outlined : Icons.check;
        iconColor = Colors.white;
      case TimelineNodeStyle.currentBlue:
        nodeBg = kTimelineBlue;
        titleColor = const Color(0xFF0F172A);
        subtitleColor = const Color(0xFF475569);
        iconData = Icons.check;
        iconColor = Colors.white;
      case TimelineNodeStyle.currentOrange:
        nodeBg = kTimelineOrange;
        titleColor = const Color(0xFF0F172A);
        subtitleColor = const Color(0xFF475569);
        iconData = Icons.handyman;
        iconColor = Colors.white;
      case TimelineNodeStyle.pendingGrey:
        nodeBg = kTimelineGrey;
        titleColor = const Color(0xFF94A3B8);
        subtitleColor = const Color(0xFFCBD5E1);
        iconData = isResolvedNode ? Icons.verified_outlined : Icons.handyman;
        iconColor = Colors.white;
      case TimelineNodeStyle.rejected:
        nodeBg = const Color(0xFFDC2626);
        titleColor = const Color(0xFF0F172A);
        subtitleColor = const Color(0xFF475569);
        iconData = Icons.close;
        iconColor = Colors.white;
    }

    final displaySubtitle = date != null
        ? '${DateFormat('dd/MM/yyyy').format(date!)} • '
            '${DateFormat('HH:mm').format(date!)}'
        : (fallbackSubtitle ?? '');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: circle node + connector ──
          SizedBox(
            width: 40,
            child: Column(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: isCurrent
                        ? Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: nodeBg.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: nodeBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(iconData,
                                    size: iconSize, color: iconColor),
                              ),
                            ),
                          )
                        : Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: nodeBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData,
                                size: iconSize, color: iconColor),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: lineColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Right: title + subtitle ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 28.0, top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  if (displaySubtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      displaySubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
