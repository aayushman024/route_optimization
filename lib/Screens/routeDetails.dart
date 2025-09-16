import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Components/AppDrawer.dart';
import '../Globals/fontStyle.dart';

class RouteDetails extends StatefulWidget {
  const RouteDetails({super.key});

  @override
  State<RouteDetails> createState() => _RouteDetailsState();
}

class _RouteDetailsState extends State<RouteDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF0F8FF),

      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color(0xff2E2F2E),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: ElevatedButton.icon(
              onPressed: (){
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.home, color: Colors.black,),
              label: Text('Home',
                style: AppText.bold(
                    color: Colors.black,
                    fontSize: 14
                ),),
              style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Color(0xffF0F9FE))
              ),
            ),
          ),
        ],
      ),

      drawer: AppDrawer(),

      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("Route Details",
                      style: AppText.bold(fontSize: 18)),
                  const SizedBox(width: 8,),
                  Icon(Icons.route_rounded, color: Colors.black,),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
