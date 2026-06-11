import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:route_optimization/Globals/fontStyle.dart';
import 'package:route_optimization/Globals/userDetails.dart';
import 'package:route_optimization/Globals/dimensions.dart';
import 'package:route_optimization/Screens/completedTasksScreen.dart';
import 'package:route_optimization/Screens/loginScreen.dart';
import 'package:route_optimization/Services/apiGlobal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Screens/pendingTasksScreen.dart';
import 'package:route_optimization/Services/notificationService.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Drawer(
      backgroundColor: const Color(0xff202020),
      child: Column(
        children: [
          // Profile / Header Section
          Container(
            padding: EdgeInsets.symmetric(vertical: 40.sdp, horizontal: 20.sdp),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24.sdp),
                bottomRight: Radius.circular(24.sdp),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40.sdp,
                  backgroundColor: Colors.grey.shade800,
                  child: Icon(Icons.person, size: 40.sdp, color: Colors.white),
                ),
                SizedBox(height: 12.sdp),
                Text(
                  "$name",
                  style: AppText.normal(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4.sdp),
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
                _buildDrawerItem(
                  icon: Icons.assignment_turned_in_rounded,
                  title: "Completed Tasks",
                  drawerTextStyle: AppText.normal(color: Colors.white, fontSize: 16),
                  iconColor: Colors.greenAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const CompletedTasks()),
                    );
                  },
                ),
                const Divider(color: Colors.white24, thickness: 0.5, indent: 16, endIndent: 16),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: "Logout",
                  drawerTextStyle: AppText.normal(color: Colors.white, fontSize: 16),
                  iconColor: Colors.redAccent,
                  onTap: () async {
                    // Unsubscribe from FCM topic
                    await NotificationService().unsubscribeFromUserTopic();

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
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildDrawerItem(
              icon: Icons.apps,
              title: "App Version: $version",
              drawerTextStyle: AppText.light(color: Colors.grey, fontSize: 12),
              iconColor: Colors.green.withAlpha(40),
              onTap: (){}
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
    required TextStyle drawerTextStyle,
    Color iconColor = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: drawerTextStyle,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.sdp)),
      hoverColor: Colors.white10,
      splashColor: Colors.white24,
    );
  }
}
