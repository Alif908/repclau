import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:money_target/view/completed_details_page.dart';
import 'package:money_target/view/container_ui/container_ui.dart';

class CompletedTargetsPage extends StatelessWidget {
  final DocumentReference userDoc;
  const CompletedTargetsPage({required this.userDoc});

  static const _bg = Color(0xFF0A0A0A);
  static const _white = Color(0xFFEEEEEE);
  static const _grey = Color(0xFF757575);
  static const _gold = Color(0xFFFFC107);
  static const _green = Color(0xFF4CAF50);
  static const _red = Color(0xFFD32F2F);

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.10)),
                ),
              ),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: _white),
        title: const Text(
          "Completed Targets",
          style: TextStyle(
            color: _white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: userDoc
            .collection('completedTargets')
            .orderBy('completedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _red));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LiquidGlass(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    tint: _gold.withOpacity(0.07),
                    borderColor: _gold.withOpacity(0.20),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: _grey,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No completed targets yet",
                    style: TextStyle(color: _grey, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Complete your first target to see it here!",
                    style: TextStyle(color: _grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final target = (d['target'] as num?)?.toDouble() ?? 0;
              final paid = (d['paid'] as num?)?.toDouble() ?? 0;
              final planType = d['planType'] as String? ?? 'Monthly';
              final ts = d['completedAt'] as Timestamp?;
              final dateStr = ts != null ? _formatDate(ts.toDate()) : '';
              final completedDocId = docs[i].id;

              return GoldGlass(
                margin: const EdgeInsets.only(bottom: 14),
                borderRadius: 20,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _gold.withOpacity(0.12),
                            _gold.withOpacity(0.04),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          LiquidGlass(
                            borderRadius: 12,
                            padding: const EdgeInsets.all(10),
                            tint: _gold.withOpacity(0.20),
                            borderColor: _gold.withOpacity(0.4),
                            blur: 8,
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: _gold,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "₹${target.toStringAsFixed(0)} Target",
                                  style: const TextStyle(
                                    color: _white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  "$planType Plan  ·  Completed $dateStr",
                                  style: const TextStyle(
                                    color: _grey,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          LiquidGlass(
                            borderRadius: 8,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            tint: _green.withOpacity(0.15),
                            borderColor: _green.withOpacity(0.35),
                            blur: 6,
                            child: const Text(
                              "✓ Done",
                              style: TextStyle(
                                color: _green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stats row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          _statBox("Target", "₹${target.toStringAsFixed(0)}"),
                          const SizedBox(width: 10),
                          _statBox("Total Paid", "₹${paid.toStringAsFixed(0)}"),
                          const SizedBox(width: 10),
                          _statBox("Status", "100%", valueColor: _green),
                        ],
                      ),
                    ),

                    // View All button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CompletedTargetDetailPage(
                              userDoc: userDoc,
                              completedDocId: completedDocId,
                              targetAmount: target,
                              planType: planType,
                              completedDate: dateStr,
                            ),
                          ),
                        ),
                        child: LiquidGlass(
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          tint: _gold.withOpacity(0.10),
                          borderColor: _gold.withOpacity(0.35),
                          blur: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.history_rounded,
                                size: 16,
                                color: _gold,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "View All Transactions",
                                style: TextStyle(
                                  color: _gold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statBox(
    String label,
    String value, {
    Color valueColor = const Color(0xFFEEEEEE),
  }) {
    return Expanded(
      child: LiquidGlass(
        borderRadius: 10,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        blur: 6,
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: _grey, fontSize: 10),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
