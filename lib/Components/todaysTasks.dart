import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:route_optimization/functions.dart';

import '../DialogBoxes/modalBottomSheet.dart';
import '../Globals/fontStyle.dart';

class TodaysTasks extends StatefulWidget {
  const TodaysTasks({super.key});

  @override
  State<TodaysTasks> createState() => _TodaysTasksState();
}

class _TodaysTasksState extends State<TodaysTasks> {
  final String phoneNumber = "9304504962";
  final String address =
      "101G, Crown Heights, Sector 10, Rohini, New Delhi, Delhi 110085";

  Future<void> launchDialer() async {
    final String fullPhoneNumber = "+91$phoneNumber";

    try {
      final Uri telpromptUri = Uri.parse('telprompt:$fullPhoneNumber');
      if (await canLaunchUrl(telpromptUri)) {
        print('Launching with telprompt...');
        final bool launched = await launchUrl(
          telpromptUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }
      final Uri telUri = Uri.parse('tel:$fullPhoneNumber');
      if (await canLaunchUrl(telUri)) {
        print('Launching with tel...');
        final bool launched = await launchUrl(
          telUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }

      final Uri telUri2 = Uri(scheme: 'tel', path: fullPhoneNumber);
      if (await canLaunchUrl(telUri2)) {
        print('Launching with Uri constructor...');
        final bool launched = await launchUrl(
          telUri2,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }

      final Uri telUri3 = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(telUri3)) {
        print('Launching without country code...');
        final bool launched = await launchUrl(
          telUri3,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }
    } catch (e) {
      print('Error launching dialer: $e');
    }
  }

  Future<void> launchMaps() async {
    try {
      Uri mapUri;

      if (Platform.isAndroid) {
        mapUri = Uri.parse(
            "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
      } else if (Platform.isIOS) {
        mapUri = Uri.parse(
            "http://maps.apple.com/?q=${Uri.encodeComponent(address)}");
      } else {
        mapUri = Uri.parse(
            "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
      }

      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('Could not open maps application');
      }
    } catch (e) {
      print('Error launching maps: $e');
      _showErrorDialog('Could not open maps');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.95,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffE4F6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xff003BB1), width: 0.75),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Today's Tasks", style: AppText.bold(fontSize: 20)),
              const SizedBox(width: 15),
              Expanded(child: Container(height: 1, color: Colors.black38)),
            ],
          ),

          const SizedBox(height: 25),

          /// Client details
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '1. Client Name:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: ' Aayushman Ranjan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Task: ',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: ' Collect Mutual Fund Documents',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Time Period: ',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: ' Before 4PM',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Text(
            'Milestone Global Moneymart, Rohini Sec-10, Delhi.',
            style: AppText.bold(fontSize: 16),
          ),
          const SizedBox(height: 15),
          Text(
            address,
            style: AppText.normal(fontSize: 14),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    backgroundColor: const Color(0xffF0F8FF),
                    builder: (context) {
                      return const ModalBottomSheet();
                    },
                  );
                },
                label: Text(
                  'Mark as Completed',
                  style: AppText.bold(color: Colors.white, fontSize: 15),
                ),
                style: ButtonStyle(
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  backgroundColor:
                  const WidgetStatePropertyAll(Color(0xff282828)),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
              ),

              /// Popup menu for Navigate & Call
              PopupMenuButton<String>(
                color: Color(0xffF0F8FF),
                elevation: 10,
                onSelected: (value) {
                  if (value == 'navigate') {
                    launchMaps();
                  } else if (value == 'call') {
                    launchDialer();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'call',
                    child: Row(
                      children: [
                        Icon(Icons.call, color: Colors.black),
                        SizedBox(width: 8),
                        Text("Call",
                          style: AppText.normal(
                              color: Colors.black,
                              fontSize: 16
                          ),),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'navigate',
                    child: Row(
                      children: [
                        Icon(Icons.navigation, color: Colors.black),
                        SizedBox(width: 8),
                        Text("Navigate",
                          style: AppText.normal(
                              color: Colors.black,
                              fontSize: 16
                          ),),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert, color: Colors.black),
              ),
            ],
          ),

          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 30, bottom: 10),
              height: 1,
              width: screenWidth * 0.6,
              color: const Color(0xff00436A).withAlpha(60),
            ),
          ),

          //example
          //example
          //example



          const SizedBox(height: 25),

          /// Client details
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '2. Client Name:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: ' Aayushman Ranjan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Task: ',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: ' Collect Mutual Fund Documents',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Time Period: ',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: ' Before 4PM',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Text(
            'Milestone Global Moneymart, Rohini Sec-10, Delhi.',
            style: AppText.bold(fontSize: 16),
          ),
          const SizedBox(height: 15),
          Text(
            address,
            style: AppText.normal(fontSize: 14),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    backgroundColor: const Color(0xffF0F8FF),
                    builder: (context) {
                      return const ModalBottomSheet();
                    },
                  );
                },
                label: Text(
                  'Mark as Completed',
                  style: AppText.bold(color: Colors.white, fontSize: 15),
                ),
                style: ButtonStyle(
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  backgroundColor:
                  const WidgetStatePropertyAll(Color(0xff282828)),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
              ),

              /// Popup menu for Navigate & Call
              PopupMenuButton<String>(
                color: Color(0xffF0F8FF),
                elevation: 10,
                onSelected: (value) {
                  if (value == 'navigate') {
                    launchMaps();
                  } else if (value == 'call') {
                    launchDialer();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'call',
                    child: Row(
                      children: [
                        Icon(Icons.call, color: Colors.black),
                        SizedBox(width: 8),
                        Text("Call",
                          style: AppText.normal(
                              color: Colors.black,
                              fontSize: 16
                          ),),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'navigate',
                    child: Row(
                      children: [
                        Icon(Icons.navigation, color: Colors.black),
                        SizedBox(width: 8),
                        Text("Navigate",
                          style: AppText.normal(
                              color: Colors.black,
                              fontSize: 16
                          ),),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert, color: Colors.black),
              ),
            ],
          ),

          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 30, bottom: 10),
              height: 1,
              width: screenWidth * 0.6,
              color: const Color(0xff00436A).withAlpha(60),
            ),
          ),



          const SizedBox(height: 25),

          /// Client details
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '3. Client Name:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: ' Aayushman Ranjan',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Task: ',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: ' Collect Mutual Fund Documents',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Time Period: ',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: ' Before 4PM',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Text(
            'Milestone Global Moneymart, Rohini Sec-10, Delhi.',
            style: AppText.bold(fontSize: 16),
          ),
          const SizedBox(height: 15),
          Text(
            address,
            style: AppText.normal(fontSize: 14),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    backgroundColor: const Color(0xffF0F8FF),
                    builder: (context) {
                      return const ModalBottomSheet();
                    },
                  );
                },
                label: Text(
                  'Mark as Completed',
                  style: AppText.bold(color: Colors.white, fontSize: 15),
                ),
                style: ButtonStyle(
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  backgroundColor:
                  const WidgetStatePropertyAll(Color(0xff282828)),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
              ),

              /// Popup menu for Navigate & Call
              PopupMenuButton<String>(
                color: Color(0xffF0F8FF),
                elevation: 10,
                onSelected: (value) {
                  if (value == 'navigate') {
                    launchMaps();
                  } else if (value == 'call') {
                    launchDialer();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'call',
                    child: Row(
                      children: [
                        Icon(Icons.call, color: Colors.black),
                        SizedBox(width: 8),
                        Text("Call",
                          style: AppText.normal(
                              color: Colors.black,
                              fontSize: 16
                          ),),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'navigate',
                    child: Row(
                      children: [
                        Icon(Icons.navigation, color: Colors.black),
                        SizedBox(width: 8),
                        Text("Navigate",
                          style: AppText.normal(
                              color: Colors.black,
                              fontSize: 16
                          ),),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert, color: Colors.black),
              ),
            ],
          ),

          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 30, bottom: 10),
              height: 1,
              width: screenWidth * 0.6,
              color: const Color(0xff00436A).withAlpha(60),
            ),
          ),





        ],
      ),
    );
  }
}