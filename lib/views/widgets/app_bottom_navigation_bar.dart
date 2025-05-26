import 'package:flutter/material.dart';
import '/localization/app_localizations_extension.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const AppBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          currentIndex: currentIndex,
          selectedItemColor: Color(0xFFFF8B55),
          unselectedItemColor: Colors.grey.shade500,
          showUnselectedLabels: true,
          onTap: (index) {
            if (index != currentIndex) {
              onTabSelected(index);
            }
          },
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: [
            _buildItem(context, icon: Icons.edit, label: context.tr('tab_expense'), isActive: currentIndex == 0),
            _buildItem(context, icon: Icons.calendar_today, label: context.tr('tab_calendar'), isActive: currentIndex == 1),
            _buildItem(context, icon: Icons.pie_chart, label: context.tr('tab_report'), isActive: currentIndex == 2),
            _buildItem(context, icon: Icons.more_horiz, label: context.tr('tab_more'), isActive: currentIndex == 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildItem(BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return BottomNavigationBarItem(
      label: label,
      icon: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(isActive ? 8 : 0),
        decoration: isActive
            ? BoxDecoration(
          color: Color(0xFFFF8B55).withOpacity(0.1),
          shape: BoxShape.circle,
        )
            : null,
        child: Icon(icon, size: isActive ? 26 : 22),
      ),
    );
  }
}