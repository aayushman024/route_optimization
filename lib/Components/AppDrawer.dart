import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:route_optimization/Globals/fontStyle.dart';
import 'package:route_optimization/Screens/loginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      backgroundColor: Color(0xff202020),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight*0.1,),
            ListTile(
              leading: Icon(Icons.comment_rounded, color: Colors.white,),
              title: Text('View Comments',
              style: AppText.normal(
                color: Colors.white,
                fontSize: 16
              ),),
              onTap: (){},
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.white,),
              title: Text('Completed Tasks',
                style: AppText.normal(
                    color: Colors.white,
                    fontSize: 16
                ),),
              onTap: (){},
            ),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: Colors.white,),
              title: Text('Logout',
                style: AppText.normal(
                    color: Colors.white,
                    fontSize: 16
                ),),
              onTap: () async{
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('jwt_token');
                Navigator.pushAndRemoveUntil(
                  context,
                  CupertinoPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
