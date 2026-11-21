import 'dart:ui';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════
// Liquid Glass Widget — reusable across all pages
// ══════════════════════════════════════════════════════════════════

class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final Color tint;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.blur = 18,
    this.tint = const Color(0x14FFFFFF),
    this.borderColor = const Color(0x33FFFFFF),
    this.borderWidth = 1.0,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.04),
                blurRadius: 1,
                offset: const Offset(0, -1),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor, width: borderWidth),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.10),
                  Colors.white.withOpacity(0.03),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Accent tinted glass (red) ─────────────────────────────────────
class RedGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const RedGlass({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      tint: const Color(0x22D32F2F),
      borderColor: const Color(0x55EF5350),
      blur: 16,
      child: child,
    );
  }
}

// ── Gold tinted glass ─────────────────────────────────────────────
class GoldGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GoldGlass({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      tint: const Color(0x1AFFC107),
      borderColor: const Color(0x44FFC107),
      blur: 16,
      child: child,
    );
  }
}

// ── Green tinted glass ────────────────────────────────────────────
class GreenGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GreenGlass({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      tint: const Color(0x1A4CAF50),
      borderColor: const Color(0x444CAF50),
      blur: 16,
      child: child,
    );
  }
}