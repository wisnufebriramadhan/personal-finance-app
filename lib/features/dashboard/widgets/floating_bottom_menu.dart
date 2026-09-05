import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FloatingBottomMenu extends StatelessWidget {
  const FloatingBottomMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25121A43),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MenuItem(
              icon: Icons.home_rounded,
              label: 'Beranda',
              selected: selectedIndex == 0,
              onTap: () => onItemTapped(0),
            ),
            _MenuItem(
              icon: Icons.pie_chart_rounded,
              label: 'Analisis',
              selected: selectedIndex == 1,
              onTap: () => onItemTapped(1),
            ),
            _MenuItem(
              icon: Icons.tune_rounded,
              label: 'Atur',
              selected: selectedIndex == 3,
              onTap: () => onItemTapped(3),
            ),
            _MenuItem(
              icon: Icons.event_note_rounded,
              label: 'Rencana',
              selected: selectedIndex == 2,
              onTap: () => onItemTapped(2),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: EdgeInsets.symmetric(
        horizontal: selected ? 13 : 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE5F9F0) : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: selected ? navy : const Color(0xFF85899B),
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Text(
                label,
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
