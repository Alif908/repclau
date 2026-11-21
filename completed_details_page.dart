import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:money_target/view/container_ui/container_ui.dart';

class CompletedTargetDetailPage extends StatelessWidget {
  final DocumentReference userDoc;
  final String completedDocId;
  final double targetAmount;
  final String planType;
  final String completedDate;

  const CompletedTargetDetailPage({
    required this.userDoc,
    required this.completedDocId,
    required this.targetAmount,
    required this.planType,
    required this.completedDate,
  });

  static const _bg = Color(0xFF0A0A0A);
  static const _white = Color(0xFFEEEEEE);
  static const _grey = Color(0xFF757575);
  static const _gold = Color(0xFFFFC107);
  static const _green = Color(0xFF4CAF50);
  static const _red = Color(0xFFD32F2F);
  static const _redLight = Color(0xFFEF5350);

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Transaction History",
              style: TextStyle(
                color: _white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "₹${targetAmount.toStringAsFixed(0)} · $planType",
              style: const TextStyle(color: _grey, fontSize: 11),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: userDoc
            .collection('completedTargets')
            .doc(completedDocId)
            .collection('transactions')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _red));
          }
          final docs = snap.data?.docs ?? [];

          return Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              ),

              // ── Summary banner ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GoldGlass(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      LiquidGlass(
                        borderRadius: 12,
                        padding: const EdgeInsets.all(8),
                        tint: _gold.withOpacity(0.18),
                        borderColor: _gold.withOpacity(0.4),
                        blur: 8,
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: _gold,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "₹${targetAmount.toStringAsFixed(0)} Target Completed!",
                              style: const TextStyle(
                                color: _white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              "Completed on $completedDate  ·  $planType Plan",
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
                          horizontal: 10,
                          vertical: 6,
                        ),
                        tint: _green.withOpacity(0.15),
                        borderColor: _green.withOpacity(0.35),
                        blur: 6,
                        child: Text(
                          "${docs.length} txn${docs.length != 1 ? 's' : ''}",
                          style: const TextStyle(
                            color: _green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Transaction list ────────────────────────────────
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Text(
                          "No transactions recorded",
                          style: TextStyle(color: _grey, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: docs.length,
                        itemBuilder: (ctx, i) {
                          final d = docs[i].data() as Map<String, dynamic>;
                          final amount = (d['amount'] as num?)?.toDouble() ?? 0;
                          final note = d['note'] as String? ?? 'Payment';
                          final ts = d['date'] as Timestamp?;
                          final dateStr = ts != null
                              ? _formatDate(ts.toDate())
                              : '';
                          final runningTotal = (d['runningTotal'] as num?)
                              ?.toDouble();
                          final percent =
                              (targetAmount > 0 && runningTotal != null)
                              ? ((runningTotal / targetAmount) * 100).clamp(
                                  0.0,
                                  100.0,
                                )
                              : null;

                          return LiquidGlass(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            borderRadius: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    LiquidGlass(
                                      borderRadius: 10,
                                      padding: const EdgeInsets.all(9),
                                      tint: _red.withOpacity(0.18),
                                      borderColor: _redLight.withOpacity(0.35),
                                      blur: 8,
                                      child: const Icon(
                                        Icons.currency_rupee,
                                        color: _redLight,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "₹${amount.toStringAsFixed(0)} added",
                                            style: const TextStyle(
                                              color: _white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            note,
                                            style: const TextStyle(
                                              color: _grey,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        color: _grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                if (runningTotal != null) ...[
                                  const SizedBox(height: 10),
                                  LiquidGlass(
                                    borderRadius: 8,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    tint: _green.withOpacity(0.07),
                                    borderColor: _green.withOpacity(0.20),
                                    blur: 6,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons
                                                  .account_balance_wallet_outlined,
                                              color: _green,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 5),
                                            const Text(
                                              "Total paid so far",
                                              style: TextStyle(
                                                color: _grey,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "₹${runningTotal.toStringAsFixed(0)}",
                                              style: const TextStyle(
                                                color: _green,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (percent != null) ...[
                                              const SizedBox(width: 6),
                                              LiquidGlass(
                                                borderRadius: 6,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                tint: _green.withOpacity(0.12),
                                                borderColor: _green.withOpacity(
                                                  0.3,
                                                ),
                                                blur: 4,
                                                child: Text(
                                                  "${percent.toStringAsFixed(0)}%",
                                                  style: const TextStyle(
                                                    color: _green,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
