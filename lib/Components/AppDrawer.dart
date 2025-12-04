import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:route_optimization/Globals/fontStyle.dart';
import 'package:route_optimization/Globals/userDetails.dart';
import 'package:route_optimization/Screens/completedTasksScreen.dart';
import 'package:route_optimization/Screens/loginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Screens/pendingTasksScreen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Drawer(
      backgroundColor: const Color(0xff202020),
      child: Column(
        children: [
          // Profile / Header Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  "$name",
                  style: AppText.normal(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$contactNumber",
                  style: AppText.normal(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: screenHeight * 0.03),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // _buildDrawerItem(
                //   icon: Icons.comment_rounded,
                //   title: "View Comments",
                //   onTap: () {},
                // ),
                // _buildDrawerItem(
                //   icon: Icons.check_circle,
                //   title: "Completed Tasks",
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.push(context, CupertinoPageRoute(builder: (_)=> CompletedTasks()));
                //   },
                // ),
                // _buildDrawerItem(
                //   icon: Icons.pending_actions_rounded,
                //   title: "Pending Tasks",
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.push(context, CupertinoPageRoute(builder: (_)=> PendingTasksScreen()));
                //   },
                // ),
                const Divider(color: Colors.white24, thickness: 0.5, indent: 16, endIndent: 16),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: "Logout",
                  iconColor: Colors.redAccent,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('jwt_token');
                    Navigator.pushAndRemoveUntil(
                      context,
                      CupertinoPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: AppText.normal(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Colors.white10,
      splashColor: Colors.white24,
    );
  }
}
