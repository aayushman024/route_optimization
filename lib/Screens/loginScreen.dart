import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:route_optimization/Components/GradientButton.dart';
import 'package:route_optimization/Controllers/controllers.dart';
import 'dart:async';

import 'package:route_optimization/Screens/homeScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  bool isMobileNumberTen = false;
  bool is30secDone = false;
  int timerSeconds = 30;
  Timer? _timer;

  void startTimer() {
    setState(() {
      is30secDone = false;
      timerSeconds = 30;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timerSeconds > 0) {
          timerSeconds--;
        } else {
          is30secDone = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF0F8FF),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: screenHeight * 0.1),
              Image.asset('assets/logo.png'),
              SizedBox(height: screenHeight * 0.03),
              Text(
                'Welcome Back!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                ),
              ),
              SizedBox(height: screenHeight * 0.1),
              Text(
                'Route Optimization Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Divider(
                endIndent: screenWidth * 0.4,
                indent: screenWidth * 0.4,
                color: Colors.black,
              ),
              SizedBox(height: screenHeight * 0.05),
              Container(
                width: screenWidth,
                height: screenHeight * 0.55,
                decoration: BoxDecoration(
                  color: const Color(0xff2E2F2E),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      spreadRadius: 2,
                      blurRadius: 30,
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: TextField(
                          controller: mobileNumberController,
                          maxLength: 10,
                          cursorColor: Colors.blue,
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            if (val.length == 10) {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                isMobileNumberTen = true;
                              });
                            } else { setState(() {
                              isMobileNumberTen = false;
                            }); }
                          },
                          decoration: InputDecoration(
                            counterStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
                              child: Text(
                                '+91    ',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            suffixIcon: TextButton(
                              onPressed: isMobileNumberTen ? () {
                                startTimer();
                                setState(() {
                                  isMobileNumberTen = false;
                                });
                              } : null,
                              child: Text('Get OTP  ',
                                style: GoogleFonts.poppins(
                                    color: isMobileNumberTen ? Colors.blue : Colors.grey,
                                    fontWeight: FontWeight.w600
                                ),),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Colors.blue, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                            ),
                            hintText: 'Enter Your Mobile Number',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.black26,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            fillColor: const Color(0xffF0F9FF),
                            filled: true,
                          ),
                        ),
                      ),

                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text('Enter OTP',
                              style: GoogleFonts.poppins(
                                  color: Color(0xffCBECFF),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700
                              ),),
                          ),
                          OtpTextField(
                            filled: true,
                            fillColor: Colors.white30,
                            showFieldAsBox: true,
                            numberOfFields: 6,
                            keyboardType: TextInputType.number,
                            showCursor: false,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: Colors.blue, width: 1),
                                )
                            ),
                            fieldWidth: 40,
                            fieldHeight: 50,
                            borderWidth: 1,
                            enabledBorderColor: Colors.white24,
                            focusedBorderColor: Colors.white,
                            textStyle: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: TextButton(
                                onPressed: is30secDone ? () {
                                  startTimer();
                                } : null,
                                child: Text(is30secDone ? 'Resend OTP' : 'Resend OTP (${timerSeconds}s)',
                                  style: GoogleFonts.poppins(
                                      color: is30secDone ? Color(0xffB3E2FF) : Colors.grey,
                                      fontWeight: FontWeight.w600
                                  ),)),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: GradientButton(
                            text: 'Continue',
                            textColor: Colors.white,
                            onPressed: (){
                              Navigator.push(context, CupertinoPageRoute(builder: (_)=> HomeScreen()));
                            }
                        )
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}