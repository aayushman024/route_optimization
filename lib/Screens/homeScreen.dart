// File: home_screen_dark.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:route_optimization/Components/floatingActionButton.dart';
import 'package:route_optimization/Components/taskSummary.dart';
import 'package:route_optimization/Globals/fontStyle.dart';
import 'package:route_optimization/Services/task_api.dart';
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

  static const Color kScaffoldBg = Color(0xFF000000);
  static const Color kSurface = Color(0xFF0A0A0A);
  static const Color kCard = Color(0xFF121212);
  static const Color kAccent = Color(0xFF1E8E6E);
  static const Color kTextPrimary = Colors.white;
  static const Color kTextSecondary = Colors.white70;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _fetchTaskCount();
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
      _fetchTaskCount();
    }
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('feName') ?? "";
      contactNumber = prefs.getString('contactNumber');
    });
  }

  Future<void> _refreshTasks() async {
    print("[DEBUG] Pull-to-refresh triggered...");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeScreen(),
      ),
          (route) => false,
    );
  }

  int _todaysTaskCount = 0;

  Future<void> _fetchTaskCount() async {
    try {
      // Re-using your existing TaskApi
      final tasks = await TaskApi.fetchTasks();
      if (mounted) {
        setState(() {
          _todaysTaskCount = tasks.length;
        });
      }
    } catch (e) {
      print("Error fetching task count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // 1. REMOVED the full-screen loading check here.
    // The UI will now render immediately.

    return Scaffold(
      backgroundColor: kScaffoldBg,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: kTextPrimary),
        backgroundColor: kCard,
        elevation: 0,
        actions: [
          // 2. Conditional Lottie Animation
          // Shows only when location is loading
          if (_controller.isLocationLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Lottie.asset(
                'assets/Location.json',
                height: 40, // Small size for AppBar
                width: 40,
              ),
            ),

          // Existing Refresh Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
            child: OutlinedButton(
              onPressed: _refreshTasks,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: Colors.white.withAlpha(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, color: kTextPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Refresh',
                    style: AppText.normal(
                      color: kTextPrimary,
                      fontSize: 14,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(screenHeight * 0.1),
          child: Container(
            color: kCard,
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorColor: kTextPrimary,
              indicatorWeight: 4,
              labelColor: kTextPrimary,
              unselectedLabelColor: kTextSecondary,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Tasks"),
                      // Only show badge if we have tasks
                      if (_todaysTaskCount > 0) ...[
                        //const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 11, // Size of the circle
                          backgroundColor: Colors.redAccent,
                          child: Text(
                            '$_todaysTaskCount',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Icon(
                      Icons.task_alt_rounded,
                      size: 20,
                                    ),
                  ),),
                const Tab(icon: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                  child: Icon(Icons.map_rounded, size: 20),
                ), text: 'Map View'),
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
          const TodaysTasks(),
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