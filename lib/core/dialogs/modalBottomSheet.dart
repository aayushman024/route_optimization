import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:route_optimization/core/widgets/GradientButton.dart';
import 'package:route_optimization/core/widgets/NormalElevatedButton.dart';
import 'package:route_optimization/core/theme/fontStyle.dart';
import 'package:route_optimization/core/utils/dimensions.dart';
import 'package:route_optimization/data/services/locationTracking.dart';

class ModalBottomSheet extends StatefulWidget {
  const ModalBottomSheet({super.key});

  @override
  State<ModalBottomSheet> createState() => _ModalBottomSheetState();
}

class _ModalBottomSheetState extends State<ModalBottomSheet> {
  bool showAnimation = false;

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.sdp, vertical: 30.sdp),
      height: MediaQuery.of(context).size.height * 0.3,
      child: showAnimation
          ? Center(
        child: Lottie.asset(
          'assets/Success.json',
          height: 100.sdp,
          width: 100.sdp,
          repeat: false,
          frameRate: FrameRate(120),
          onLoaded: (composition) {
            Future.delayed(composition.duration, () {
              Navigator.of(context).pop();
            });
          },
        ),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Are you sure you want to mark this Task as Completed?',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 18.ssp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CustomElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                text: 'No',
                fontSize: 18,
                textColor: Colors.red,
                width: MediaQuery.of(context).size.width * 0.25,
                backgroundColor: Colors.red.shade100,
                borderColor: Colors.red,
                borderRadius: 15,
              ),
              CustomElevatedButton(
                onPressed: () {
                  //sendCurrentLocationNow();
                  setState(() {
                    showAnimation = true;
                  });
                },
                text: 'Confirm',
                fontSize: 18,
                textColor: Colors.green,
                width: MediaQuery.of(context).size.width * 0.4,
                backgroundColor: Colors.green.shade100,
                borderColor: Colors.green,
                borderRadius: 15,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
