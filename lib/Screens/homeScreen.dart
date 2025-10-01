import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:route_optimization/Components/floatingActionButton.dart';
import 'package:route_optimization/Components/taskSummary.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Components/AppDrawer.dart';
import '../Components/map_view_tab.dart';
import '../Components/todaysTasks.dart';
import '../Controllers/home_controller.dart';
import '../Globals/userDetails.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late HomeController _controller;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _controller = HomeController(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
      context: context,
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _controller.checkServiceStatus();
    }
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('feName') ?? "";
      contactNumber = prefs.getString('contactNumber');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (_controller.currentPosition == null || _controller.isLocationLoading) {
      return Scaffold(
        backgroundColor: const Color(0xffF0F8FF),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _controller.isLocationLoading
                      ? 'Setting up location tracking...'
                      : 'Fetching your location...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Lottie.asset(
                  'assets/Location.json',
                  width: 250,
                  height: 250,
                  frameRate: FrameRate(120),
                  repeat: true,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF0F8FF),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xff2E2F2E),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off,
                color: _controller.isTrackingActive ? Colors.grey : Colors.red,
                size: 28,
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _controller.isTrackingActive,
                  activeThumbColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  activeTrackColor: Colors.green.withAlpha(40),
                  inactiveTrackColor: Colors.red.withAlpha(40),
                  onChanged: (val) {
                    _controller.toggleTracking();
                  },
                ),
              ),
              Icon(
                Icons.location_on,
                color: _controller.isTrackingActive
                    ? Colors.green
                    : Colors.grey,
                size: 30,
              ),
              const SizedBox(width: 20),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(screenHeight * 0.1),
          child: Container(
            color: const Color(0xff2E2F2E),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.task_alt_rounded, size: 20),
                  text: 'Today\'s Tasks',
                ),
                Tab(icon: Icon(Icons.map_rounded, size: 20), text: 'Map View'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FAB(),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: const TodaysTasks(),
          ),
          KeepAliveWrapper(child: MapViewTab(controller: _controller)),
        ],
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _KeepAliveWrapperState createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
