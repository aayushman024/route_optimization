// File: home_screen_dark.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:route_optimization/core/widgets/floatingActionButton.dart';
import 'package:route_optimization/core/theme/fontStyle.dart';
import 'package:route_optimization/core/utils/dimensions.dart';
import 'package:route_optimization/data/network/task_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:route_optimization/core/widgets/AppDrawer.dart';
import 'package:route_optimization/features/tasks/views/widgets/map_view_tab.dart';
import 'package:route_optimization/features/tasks/views/widgets/todaysTasks.dart';
import 'package:route_optimization/features/tasks/viewmodels/home_viewmodel.dart';
import 'package:route_optimization/core/managers/userDetails.dart';
import 'package:route_optimization/data/services/update_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final GlobalKey<TodaysTasksState> _todaysTasksKey = GlobalKey<TodaysTasksState>();

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
    
    // Check for new Shorebird updates once the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdateChangelog(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      ref.read(homeViewModelProvider.notifier).checkServiceStatus();
      _refreshTasks();
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
    final refreshTasksFuture = _todaysTasksKey.currentState?.refresh();
    final fetchTaskCountFuture = _fetchTaskCount();
    final refreshMapFuture = ref.read(homeViewModelProvider.notifier).refreshMapSafely();

    await Future.wait([
      if (refreshTasksFuture != null) refreshTasksFuture,
      fetchTaskCountFuture,
      refreshMapFuture,
    ]);
  }

  int _todaysTaskCount = 0;

  Future<void> _fetchTaskCount() async {
    try {
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
    SizeUtil.init(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Watch the state
    final homeState = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: kScaffoldBg,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: kTextPrimary),
        backgroundColor: kCard,
        elevation: 0,
        actions: [
          if (homeState.isLocationLoading)
            Padding(
              padding: EdgeInsets.only(right: 8.0.sdp),
              child: Lottie.asset(
                'assets/Location.json',
                height: 40.sdp,
                width: 40.sdp,
              ),
            ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0.sdp, horizontal: 10.0.sdp),
            child: OutlinedButton(
              onPressed: _refreshTasks,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.sdp),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 8.sdp),
                backgroundColor: Colors.white.withAlpha(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, color: kTextPrimary),
                  SizedBox(width: 8.sdp),
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
                fontSize: 16.ssp,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: 15.ssp,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8.sdp,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Tasks"),
                      if (_todaysTaskCount > 0) ...[
                        CircleAvatar(
                          radius: 11.sdp,
                          backgroundColor: Colors.redAccent,
                          child: Text(
                            '$_todaysTaskCount',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12.ssp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 8.sdp),
                    child: Icon(Icons.task_alt_rounded, size: 20.sdp),
                  ),
                ),
                Tab(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 8.sdp),
                    child: Icon(Icons.map_rounded, size: 20.sdp),
                  ),
                  text: 'Map View',
                ),
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
          TodaysTasks(
            key: _todaysTasksKey,
            onRefresh: _refreshTasks,
          ),
          // We will refactor MapViewTab to not require the controller parameter
          KeepAliveWrapper(child: MapViewTab()),
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