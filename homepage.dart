import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_target/view/completed_target_page.dart';
import 'package:money_target/view/container_ui/container_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _bg = Color(0xFF0A0A0A);
  static const _red = Color(0xFFD32F2F);
  static const _redLight = Color(0xFFEF5350);
  static const _white = Color(0xFFEEEEEE);
  static const _grey = Color(0xFF757575);
  static const _green = Color(0xFF4CAF50);
  static const _gold = Color(0xFFFFC107);

  DocumentReference get _userDoc => FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid);

  Future<void> _addPayment(double amount, String note) async {
    String? completedTargetId;
    double? completedTargetAmount;
    String? completedPlanType;
    double? newPaid;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(_userDoc);
      final currentPaid = (snapshot['paid'] as num).toDouble();
      final target = (snapshot['target'] as num).toDouble();
      newPaid = currentPaid + amount;

      transaction.update(_userDoc, {'paid': newPaid});

      if (newPaid! >= target && target > 0) {
        final data = snapshot.data() as Map<String, dynamic>;
        completedPlanType = data['planType'] as String? ?? 'Monthly';
        completedTargetAmount = target;
        final completedRef = _userDoc.collection('completedTargets').doc();
        completedTargetId = completedRef.id;
        transaction.set(completedRef, {
          'target': target,
          'paid': newPaid,
          'planType': completedPlanType,
          'completedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(_userDoc, {'paid': 0, 'target': 0});
      }
    });

    await _userDoc.collection('history').add({
      'amount': amount,
      'note': note.isNotEmpty ? note : 'Payment added',
      'date': FieldValue.serverTimestamp(),
      'runningTotal': newPaid,
    });

    if (completedTargetId != null) {
      await _copyHistoryToCompleted(completedTargetId!);
      await _clearHistory();
      if (mounted)
        _showCompletionDialog(
          completedTargetAmount!,
          completedPlanType!,
          completedTargetId!,
        );
    }
  }

  void _showCompletionDialog(
    double targetAmount,
    String planType,
    String completedDocId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: LiquidGlass(
            borderRadius: 24,
            padding: const EdgeInsets.all(24),
            tint: const Color(0x22FFC107),
            borderColor: const Color(0x66FFC107),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.emoji_events_rounded, color: _gold, size: 28),
                    SizedBox(width: 10),
                    Text(
                      "Target Complete!",
                      style: TextStyle(
                        color: _white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  "🎉 Congratulations! ₹${targetAmount.toStringAsFixed(0)} target completed!",
                  style: const TextStyle(color: _grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openCompletedTargets();
                        },
                        child: const Text(
                          "View History",
                          style: TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _glassButton(
                        label: "Set New Target",
                        color: _red,
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(context, '/target');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyHistoryToCompleted(String completedDocId) async {
    final historySnap = await _userDoc.collection('history').get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in historySnap.docs) {
      batch.set(
        _userDoc
            .collection('completedTargets')
            .doc(completedDocId)
            .collection('transactions')
            .doc(doc.id),
        doc.data(),
      );
    }
    await batch.commit();
  }

  Future<void> _clearHistory() async {
    final historySnap = await _userDoc.collection('history').get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in historySnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  void _showAddPaymentDialog() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: SingleChildScrollView(
            child: LiquidGlass(
              borderRadius: 24,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Add Payment",
                    style: TextStyle(
                      color: _white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _glassField(
                    controller: amountCtrl,
                    label: "Amount (₹)",
                    keyboard: TextInputType.number,
                    icon: Icons.currency_rupee,
                  ),
                  const SizedBox(height: 12),
                  _glassField(
                    controller: noteCtrl,
                    label: "Note (optional)",
                    icon: Icons.note_outlined,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: _grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _glassButton(
                          label: "Add",
                          color: _red,
                          onTap: () async {
                            final text = amountCtrl.text.trim();
                            if (text.isEmpty) return;
                            final amount = double.tryParse(text);
                            if (amount == null || amount <= 0) return;
                            Navigator.pop(ctx);
                            await _addPayment(amount, noteCtrl.text.trim());
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      style: const TextStyle(color: _white),
      cursorColor: _red,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _grey, fontSize: 13),
        prefixIcon: Icon(icon, color: _grey, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _redLight, width: 1.5),
        ),
      ),
    );
  }

  Widget _glassButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass(
        borderRadius: 10,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        tint: color.withOpacity(0.25),
        borderColor: color.withOpacity(0.5),
        blur: 10,
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: LiquidGlass(
            borderRadius: 24,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Logout",
                  style: TextStyle(
                    color: _white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Are you sure you want to logout?",
                  style: TextStyle(color: _grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: _grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _glassButton(
                        label: "Logout",
                        color: _redLight,
                        onTap: () => Navigator.pop(ctx, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  void _openCompletedTargets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompletedTargetsPage(userDoc: _userDoc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: false,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My Target",
              style: TextStyle(
                color: _white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "Hi, ${user?.displayName ?? user?.email ?? 'User'}",
              style: const TextStyle(color: _grey, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _userDoc
                .collection('completedTargets')
                .limit(1)
                .snapshots(),
            builder: (context, snap) {
              final hasCompleted = (snap.data?.docs.isNotEmpty ?? false);
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: hasCompleted ? _gold : _grey,
                      size: 24,
                    ),
                    if (hasCompleted)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Completed Targets',
                onPressed: _openCompletedTargets,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: _white, size: 22),
            tooltip: 'Set Target',
            onPressed: () => Navigator.pushNamed(context, '/target'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: _redLight, size: 22),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: _userDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator(color: _red));
          if (snapshot.hasError)
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: _redLight),
              ),
            );
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(
              child: Text('No data found.', style: TextStyle(color: _grey)),
            );

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final total = (data['target'] as num?)?.toDouble() ?? 0;
          final paid = (data['paid'] as num?)?.toDouble() ?? 0;
          final planType = data['planType'] as String? ?? 'Monthly';
          final remaining = (total - paid).clamp(0.0, double.infinity);
          final progress = total > 0 ? paid / total : 0.0;

          return Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              ),

              LiquidGlass(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LiquidGlass(
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      tint: _red.withOpacity(0.18),
                      borderColor: _redLight.withOpacity(0.4),
                      blur: 8,
                      child: Text(
                        "$planType Plan",
                        style: const TextStyle(
                          color: _redLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Remaining",
                      style: TextStyle(color: _grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "₹${remaining.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 40,
                          color: _white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total > 0
                          ? "of ₹${total.toStringAsFixed(0)} target"
                          : "No target set",
                      style: const TextStyle(color: _grey, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(_red),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Paid: ₹${paid.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: _redLight,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}% done",
                          style: const TextStyle(color: _grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: total > 0 ? _showAddPaymentDialog : null,
                  child: LiquidGlass(
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    tint: total > 0
                        ? _red.withOpacity(0.22)
                        : Colors.white.withOpacity(0.04),
                    borderColor: total > 0
                        ? _redLight.withOpacity(0.45)
                        : Colors.white.withOpacity(0.10),
                    blur: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: total > 0 ? Colors.white : _grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Add Payment",
                          style: TextStyle(
                            color: total > 0 ? Colors.white : _grey,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Text(
                      "History",
                      style: TextStyle(
                        color: _white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _userDoc
                      .collection('history')
                      .orderBy('date', descending: true)
                      .snapshots(),
                  builder: (context, histSnap) {
                    if (histSnap.connectionState == ConnectionState.waiting)
                      return const Center(
                        child: CircularProgressIndicator(color: _red),
                      );
                    final docs = histSnap.data?.docs ?? [];
                    if (docs.isEmpty)
                      return const Center(
                        child: Text(
                          "No payments yet. Add your first!",
                          style: TextStyle(color: _grey, fontSize: 13),
                        ),
                      );
                    return ListView.builder(
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
                        return _historyTile(
                          amount: amount,
                          note: note,
                          date: dateStr,
                          runningTotal: runningTotal,
                          target: total,
                        );
                      },
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

  Widget _historyTile({
    required double amount,
    required String note,
    required String date,
    double? runningTotal,
    required double target,
  }) {
    final percent = (target > 0 && runningTotal != null)
        ? ((runningTotal / target) * 100).clamp(0.0, 100.0)
        : null;
    return LiquidGlass(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: const TextStyle(color: _grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(date, style: const TextStyle(color: _grey, fontSize: 11)),
            ],
          ),
          if (runningTotal != null) ...[
            const SizedBox(height: 10),
            LiquidGlass(
              borderRadius: 8,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              tint: _green.withOpacity(0.07),
              borderColor: _green.withOpacity(0.20),
              blur: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: _green,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "Total paid so far",
                        style: TextStyle(color: _grey, fontSize: 11),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          tint: _green.withOpacity(0.12),
                          borderColor: _green.withOpacity(0.3),
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
  }
}
