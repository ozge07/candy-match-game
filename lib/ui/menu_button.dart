import 'package:flutter/material.dart';

/// Menü ve oyun sonu ekranlarının ortak düğmesi.
class MenuButton extends StatelessWidget {
  const MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = true,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  /// Birincil eylem dolu, ikincil eylem sadece çerçeveli.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? const Color(0xFF1B1642) : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: filled
              ? const LinearGradient(
                  colors: [Color(0xFFF1C40F), Color(0xFFFF8A3D)],
                )
              : null,
          color: filled ? null : Colors.white.withValues(alpha: 0.08),
          border: filled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.28), width: 2),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF8A3D).withValues(alpha: 0.4),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 26),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
