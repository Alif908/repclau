import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_target/services/notification_service.dart';
import 'package:money_target/view/container_ui/container_ui.dart';

class TargetSetupPage extends StatefulWidget {
  const TargetSetupPage({super.key});

  @override
  State<TargetSetupPage> createState() => _TargetSetupPageState();
}

class _TargetSetupPageState extends State<TargetSetupPage> {
  final TextEditingController _amountController = TextEditingController();
  String _planType = "Monthly";
  bool _isLoading = false;

  static const _bg = Color(0xFF0A0A0A);
  static const _red = Color(0xFFD32F2F);
  static const _redLight = Color(0xFFEF5350);
  static const _white = Color(0xFFEEEEEE);
  static const _grey = Color(0xFF757575);

  Future<void> _save() async {
    final rawText = _amountController.text.trim();
    if (rawText.isEmpty) {
      _showSnackBar('Please enter a target amount', isError: true);
      return;
    }
    final amount = double.tryParse(rawText);
    if (amount == null || amount <= 0) {
      _showSnackBar('Enter a valid amount', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('User not logged in. Please login again.', isError: true);
        return;
      }

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final now = DateTime.now();

      await docRef.set({
        'target': amount,
        'planType': _planType,
        'paid': 0,
        'targetSetAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await NotificationService.scheduleForPlan(
        planType: _planType,
        targetAmount: amount,
        savedAt: now,
      );

      if (mounted) {
        _showSnackBar('Target saved! 🎯');
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? const Color(0xFF1C1C1C) : _red,
        content: Text(
          message,
          style: TextStyle(color: isError ? _redLight : Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
        title: const Text(
          "Set Target",
          style: TextStyle(
            color: _white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _white),
      ),

      body: Stack(
        children: [
          Positioned(
            top: 80,
            right: -60,
            child: _glowOrb(180, _red.withOpacity(0.12)),
          ),
          Positioned(
            bottom: 100,
            left: -60,
            child: _glowOrb(160, _redLight.withOpacity(0.08)),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height:
                      MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                ),

                // ─── Banner ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LiquidGlass(
                    borderRadius: 24,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _red,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Set Your Goal",
                          style: TextStyle(
                            color: _white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "How much do you want to save?",
                          style: TextStyle(color: _grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Form Card ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LiquidGlass(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Target Amount
                        const Text(
                          "Target Amount",
                          style: TextStyle(
                            color: _white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: _white),
                              cursorColor: _red,
                              decoration: InputDecoration(
                                hintText: "e.g. 10000",
                                hintStyle: const TextStyle(color: _grey),
                                prefixIcon: const Icon(
                                  Icons.currency_rupee,
                                  color: _grey,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.15),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: _red,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Plan Type
                        const Text(
                          "Plan Type",
                          style: TextStyle(
                            color: _white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: ["Daily", "Weekly", "Monthly"].map((plan) {
                            final isSelected = _planType == plan;
                            final index = [
                              "Daily",
                              "Weekly",
                              "Monthly",
                            ].indexOf(plan);
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _planType = plan),
                                child: Container(
                                  margin: EdgeInsets.only(
                                    right: index < 2 ? 8 : 0,
                                  ),
                                  child: LiquidGlass(
                                    borderRadius: 12,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    tint: isSelected
                                        ? _red.withOpacity(0.30)
                                        : Colors.white.withOpacity(0.05),
                                    borderColor: isSelected
                                        ? _redLight.withOpacity(0.6)
                                        : Colors.white.withOpacity(0.12),
                                    blur: 10,
                                    shadows: isSelected
                                        ? [
                                            BoxShadow(
                                              color: _red.withOpacity(0.3),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                    child: Center(
                                      child: Text(
                                        plan,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : _grey,
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        // Save Button
                        GestureDetector(
                          onTap: _isLoading ? null : _save,
                          child: LiquidGlass(
                            borderRadius: 14,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            tint: _red.withOpacity(0.28),
                            borderColor: _redLight.withOpacity(0.5),
                            blur: 12,
                            shadows: [
                              BoxShadow(
                                color: _red.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      "Save Target",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 20)],
      ),
    );
  }
}
