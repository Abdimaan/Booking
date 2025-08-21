import 'package:booking/userppagejob.dart';
import 'package:booking/chats_list_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';
import 'location_tracker.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> with WidgetsBindingObserver {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final LocationTracker _locationTracker = LocationTracker();

  Map<String, dynamic>? _userLocation;
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const UserHomeBody(),
    const UserJobsPage(),
    const ChatsListPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTrackingAndLoadLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationTracker.stopTracking();
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('Resumed — restarting location tracking');
      _startTrackingAndLoadLocation();
    } else if (state == AppLifecycleState.paused) {
      print('Paused — stopping tracking temporarily');
      _locationTracker.stopTracking();
    }
  }

  Future<void> _startTrackingAndLoadLocation() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Request location permission first
    bool granted = await LocationService.requestLocationPermission(context);
    if (!granted) {
      print("Location permission denied.");
      return;
    }

    // Start continuous tracking for this user
    if (!_locationTracker.isTracking) {
      _locationTracker.startTracking(user.id);
    }

    // Load current saved location from Supabase
    await _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final loc = await LocationService.getUserLocation(user.id);
      setState(() {
        _userLocation = loc;
      });
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('User Home'),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh),
      //       tooltip: "Refresh location",
      //       onPressed: _loadUserLocation,
      //     ),
      //   ],
      // ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Post Job'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
        ],
      ),
    );
  }
}

class UserHomeBody extends StatefulWidget {
  const UserHomeBody({super.key});

  @override
  State<UserHomeBody> createState() => _UserHomeBodyState();
}

class _UserHomeBodyState extends State<UserHomeBody> {
  String? selectedCategory;

  final List<String> jobCategories = ['Plumber', 'Electrician', 'Handyman'];

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorStateOfType<_UserHomeState>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: parent?.titleController,
            decoration: const InputDecoration(labelText: 'Job Title'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: parent?.descController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 10),

          // Category Dropdown
          DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Job Category',
              border: OutlineInputBorder(),
            ),
            hint: const Text('Select Category'),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
              });
            },
            items: jobCategories
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (selectedCategory == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a job category')),
                );
                return;
              }

              final uid = Supabase.instance.client.auth.currentUser!.id;

              // Ensure user location is saved before creating job
              final currentLocation = await LocationService.getCurrentLocation(
                context,
              );
              if (currentLocation != null) {
                await LocationService.saveUserLocation(
                  uid,
                  currentLocation.latitude,
                  currentLocation.longitude,
                );
              }

              // Create the job with category
              await Supabase.instance.client.from('jobs').insert({
                'title': parent?.titleController.text,
                'description': parent?.descController.text,
                'category': selectedCategory,
                'created_by': uid,
                'status': 'pending',
              });

              parent?.titleController.clear();
              parent?.descController.clear();
              setState(() {
                selectedCategory = null;
              });

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Job submitted successfully!')),
              );
            },
            child: const Text('Submit Job'),
          ),
          const SizedBox(height: 200),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              // Navigation handled by AuthWrapper
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
