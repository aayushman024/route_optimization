import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:route_optimization/Components/GradientButton.dart';
import 'package:route_optimization/Controllers/controllers.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:route_optimization/Screens/homeScreen.dart';

import '../Services/api.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isMobileNumberTen = false;
  bool is30secDone = false;
  bool isOtpSent = false;
  bool isLoading = false;
  int timerSeconds = 30;
  Timer? _timer;

  String? _jwtToken;
  String _enteredOtp = '';

  final AuthService _authService = AuthService();

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

  /// Get OTP: Generate JWT and send OTP
  Future<void> getOtp() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final contact = mobileNumberController.text.trim();
      print('Requesting OTP for: $contact'); // Debug log

      // 1. Generate JWT
      final token = await _authService.generateJwt(contact);
      if (token == null) {
        _showSnackBar('Failed to generate token', Colors.red);
        return;
      }

      print('JWT Token generated successfully'); // Debug log
      _jwtToken = token;

      // 2. Send OTP using token
      final otpSent = await _authService.sendOtp(contact, token);
      if (otpSent) {
        setState(() {
          isOtpSent = true;
        });
        _showSnackBar('OTP sent to WhatsApp', Colors.green);
        startTimer();
      } else {
        _showSnackBar('Failed to send OTP. Please try again.', Colors.red);
      }
    } catch (e) {
      print('Error in getOtp: $e'); // Debug log
      _showSnackBar('Network error. Please check your connection.', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Resend OTP (only call sendOtp using existing token)
  Future<void> resendOtp() async {
    if (isLoading) return;

    if (_jwtToken == null) {
      _showSnackBar('Please request OTP first', Colors.orange);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final contact = '+91${mobileNumberController.text.trim()}';
      final otpSent = await _authService.sendOtp(contact, _jwtToken!);
      if (otpSent) {
        _showSnackBar('OTP resent to WhatsApp', Colors.green);
        startTimer();
      } else {
        _showSnackBar('Failed to resend OTP', Colors.red);
      }
    } catch (e) {
      print('Error in resendOtp: $e'); // Debug log
      _showSnackBar('Network error. Please check your connection.', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Validate OTP
  Future<void> validateOtp() async {
    if (isLoading) return;

    if (_jwtToken == null) {
      _showSnackBar('Token missing. Please request OTP first', Colors.orange);
      return;
    }

    if (_enteredOtp.isEmpty || _enteredOtp.length != 6) {
      _showSnackBar('Please enter a valid 6-digit OTP', Colors.orange);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print('Validating OTP: $_enteredOtp'); // Debug log
      final isValid = await _authService.validateOtp(_enteredOtp, _jwtToken!);

      if (isValid) {
        // Store login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);

        _showSnackBar('Login successful!', Colors.green);
        Navigator.pushReplacement(
            context, CupertinoPageRoute(builder: (_) => HomeScreen()));
      } else {
        _showSnackBar('Invalid OTP. Please try again.', Colors.red);
        setState(() {
          _enteredOtp = '';
        });
      }
    } catch (e) {
      print('Error in validateOtp: $e'); // Debug log
      _showSnackBar('Network error. Please check your connection.', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
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
                          enabled: !isLoading,
                          onChanged: (val) {
                            setState(() {
                              isMobileNumberTen = val.length == 10;
                              if (val.length != 10) {
                                isOtpSent = false;
                                _jwtToken = null;
                                _enteredOtp = '';
                              }
                            });
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
                            suffixIcon: Container(
                              width: 100,
                              child: isLoading
                                  ? Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                  ),
                                ),
                              )
                                  : TextButton(
                                onPressed: isMobileNumberTen ? getOtp : null,
                                child: Text(
                                  isOtpSent ? 'Sent' : 'Get OTP',
                                  style: GoogleFonts.poppins(
                                    color: isMobileNumberTen
                                        ? (isOtpSent ? Colors.green : Colors.blue)
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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
                            enabled: isOtpSent && !isLoading,
                            onCodeChanged: (code) {
                              setState(() {
                                _enteredOtp = code;
                              });
                            },
                            onSubmit: (code) {
                              setState(() {
                                _enteredOtp = code;
                              });
                              if (code.length == 6) {
                                validateOtp();
                              }
                            },
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: Colors.blue, width: 1),
                                )
                            ),
                            fieldWidth: 40,
                            fieldHeight: 50,
                            borderWidth: 1,
                            enabledBorderColor: isOtpSent ? Colors.white24 : Colors.grey,
                            focusedBorderColor: Colors.white,
                            textStyle: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: isOtpSent ? Colors.white70 : Colors.grey,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: TextButton(
                                onPressed: (is30secDone && !isLoading && isOtpSent) ? resendOtp : null,
                                child: Text(
                                  is30secDone ? 'Resend OTP' : 'Resend OTP (${timerSeconds}s)',
                                  style: GoogleFonts.poppins(
                                      color: (is30secDone && isOtpSent) ? Color(0xffB3E2FF) : Colors.grey,
                                      fontWeight: FontWeight.w600
                                  ),
                                )),
                          ),
                        ],
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: GradientButton(
                            text: 'Continue',
                            textColor: Colors.white,
                            onPressed: (isOtpSent && _enteredOtp.length == 6 && !isLoading)
                                ? validateOtp
                                : null,
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