import 'package:booking/login_page.dart';
import 'package:booking/providerpagejob.dart';
import 'package:booking/chats_list_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';
import 'location_tracker.dart';
// import 'provider_jobs_page.dart';

class ProviderHome extends StatefulWidget {
  const ProviderHome({super.key});
  @override
  State<ProviderHome> createState() => _ProviderHomeState();
}

class _ProviderHomeState extends State<ProviderHome>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const ProviderAvailableJobsPage(),
    const ProviderJobsPage(),
    const ChatsListPage(),
  ];
  final LocationTracker _locationTracker = LocationTracker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLocationTracking();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _startLocationTracking();
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _startLocationTracking() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Stop existing tracking before starting new one
      if (_locationTracker.isTracking) {
        _locationTracker.stopTracking();
      }
      _locationTracker.startTracking(user.id);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationTracker.stopTracking();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'My Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
        ],
      ),
    );
  }
}

class ProviderAvailableJobsPage extends StatefulWidget {
  const ProviderAvailableJobsPage({super.key});

  @override
  State<ProviderAvailableJobsPage> createState() =>
      _ProviderAvailableJobsPageState();
}

class _ProviderAvailableJobsPageState extends State<ProviderAvailableJobsPage> {
  late Future<List<Map<String, dynamic>>> jobFuture;
  Map<String, dynamic>? _providerLocation;

  @override
  void initState() {
    super.initState();
    _loadProviderLocation();
    jobFuture = fetchPendingJobs();
  }

  Future<void> _debugDatabaseConnection() async {
    // Database connection test removed for production
  }

  Future<void> _loadProviderLocation() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final location = await LocationService.getUserLocation(user.id);
      setState(() {
        _providerLocation = location;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchPendingJobs() async {
    final providerId = Supabase.instance.client.auth.currentUser!.id;

    // Get provider category first
    final providerResponse = await Supabase.instance.client
        .from('users')
        .select('category')
        .eq('id', providerId)
        .maybeSingle();

    final providerCategory = providerResponse?['category'] as String?;

    // Get rejected job IDs for this provider
    final rejectedJobIdsResponse = await Supabase.instance.client
        .from('rejected_jobs')
        .select('job_id')
        .eq('provider_id', providerId);

    final rejectedJobIds = rejectedJobIdsResponse
        .map((e) => e['job_id'] as String)
        .toList();

    // Get all pending jobs with user locations and created_at
    final jobsResponse = await Supabase.instance.client
        .from('jobs')
        .select('*, users!fk_jobs_created_by(name, id)')
        .eq('status', 'pending')
        .order('created_at');

    final allJobs = List<Map<String, dynamic>>.from(jobsResponse);

    // Get provider location
    final providerLocation = await LocationService.getUserLocation(providerId);

    if (providerLocation == null) {
      // Try to get current location if not saved
      final position = await LocationService.getCurrentLocation(context);
      if (position != null) {
        await LocationService.saveUserLocation(
          providerId,
          position.latitude,
          position.longitude,
        );
        // Update the provider location
        setState(() {
          _providerLocation = {
            'latitude': position.latitude,
            'longitude': position.longitude,
          };
        });
        // Use the new location for calculations
        final updatedProviderLocation = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
        return await _fetchJobsWithLocation(
          updatedProviderLocation,
          providerCategory,
          rejectedJobIds,
          allJobs,
        );
      } else {
        // If we can't get location, show all jobs
        return await _fetchAllPendingJobs();
      }
    }

    // Use the provider location for calculations
    return await _fetchJobsWithLocation(
      providerLocation,
      providerCategory,
      rejectedJobIds,
      allJobs,
    );
  }

  // Helper method to fetch jobs with location-based filtering
  Future<List<Map<String, dynamic>>> _fetchJobsWithLocation(
    Map<String, dynamic> providerLocation,
    String? providerCategory,
    List<String> rejectedJobIds,
    List<Map<String, dynamic>> allJobs,
  ) async {
    final visibleJobs = <Map<String, dynamic>>[];

    for (var job in allJobs) {
      if (rejectedJobIds.contains(job['id'])) {
        continue;
      }

      // Filter by category - only show jobs that match provider's category
      final jobCategory = job['category'] as String?;

      if (providerCategory != null && jobCategory != null) {
        if (providerCategory != jobCategory) {
          continue; // Skip jobs that don't match provider's category
        }
      }

      // Get job requester location
      final userLocation = await LocationService.getUserLocation(
        job['users']['id'],
      );

      if (userLocation == null) {
        continue;
      }

      // Calculate distance
      final distance = LocationService.calculateDistance(
        providerLocation['latitude'],
        providerLocation['longitude'],
        userLocation['latitude'],
        userLocation['longitude'],
      );
      job['distance'] = distance;

      // Simplified distance logic - show jobs within reasonable distance
      const maxReasonableDistance = 10000.0; // 10km

      if (distance <= maxReasonableDistance) {
        visibleJobs.add(job);
      }
    }

    return visibleJobs;
  }

  // Fallback method to show all pending jobs when location is not available
  Future<List<Map<String, dynamic>>> _fetchAllPendingJobs() async {
    final providerId = Supabase.instance.client.auth.currentUser!.id;

    // Get provider category
    final providerResponse = await Supabase.instance.client
        .from('users')
        .select('category')
        .eq('id', providerId)
        .maybeSingle();

    final providerCategory = providerResponse?['category'] as String?;

    // Get rejected job IDs for this provider
    final rejectedJobIdsResponse = await Supabase.instance.client
        .from('rejected_jobs')
        .select('job_id')
        .eq('provider_id', providerId);

    final rejectedJobIds = rejectedJobIdsResponse
        .map((e) => e['job_id'] as String)
        .toList();

    // Get all pending jobs
    final jobsResponse = await Supabase.instance.client
        .from('jobs')
        .select('*, users!fk_jobs_created_by(name, id)')
        .eq('status', 'pending')
        .order('created_at');

    final allJobs = List<Map<String, dynamic>>.from(jobsResponse);

    final visibleJobs = <Map<String, dynamic>>[];

    for (var job in allJobs) {
      if (rejectedJobIds.contains(job['id'])) continue;

      // Filter by category - only show jobs that match provider's category
      final jobCategory = job['category'] as String?;

      if (providerCategory != null && jobCategory != null) {
        if (providerCategory != jobCategory) {
          continue; // Skip jobs that don't match provider's category
        }
      }

      // Add distance as null to indicate unknown
      job['distance'] = null;
      visibleJobs.add(job);
    }

    return visibleJobs;
  }

  Future<void> acceptJob(String jobId) async {
    final uid = Supabase.instance.client.auth.currentUser!.id;

    await Supabase.instance.client
        .from('jobs')
        .update({'status': 'accepted', 'accepted_by': uid})
        .eq('id', jobId);

    setState(() {
      jobFuture = fetchPendingJobs();
    });
  }

  Future<void> rejectJob(String jobId) async {
    final uid = Supabase.instance.client.auth.currentUser!.id;

    await Supabase.instance.client.from('rejected_jobs').insert({
      'job_id': jobId,
      'provider_id': uid,
    });

    setState(() {
      jobFuture = fetchPendingJobs();
    });
  }

  String _formatDistance(double? distance) {
    if (distance == null) return 'Distance unknown';
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m away';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Jobs'),
        actions: [
          IconButton(
            icon: Icon(Icons.location_on),
            onPressed: () {
              _loadProviderLocation();
              setState(() {
                jobFuture = fetchPendingJobs();
              });
            },
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: jobFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snapshot.data!;
          if (jobs.isEmpty) {
            return const Center(child: Text('No pending jobs'));
          }

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final requester = job['users']?['name'] ?? 'Unknown';
              final distance = job['distance'];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(job['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${job['description'] ?? ''}\nRequested by: $requester',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (job['category'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            job['category'],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (distance != null)
                        Text(
                          _formatDistance(distance),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 10,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: () => acceptJob(job['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => rejectJob(job['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Supabase.instance.client.auth.signOut();
          // Navigation will be handled automatically by AuthWrapper
        },
        child: const Icon(Icons.logout),
        tooltip: 'Log Out',
      ),
    );
  }
}
