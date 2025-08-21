import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';
import 'chat_page.dart';

class UserJobsPage extends StatefulWidget {
  const UserJobsPage({super.key});

  @override
  State<UserJobsPage> createState() => _UserJobsPageState();
}

class _UserJobsPageState extends State<UserJobsPage> {
  Map<String, dynamic>? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final location = await LocationService.getUserLocation(user.id);
      setState(() {
        _userLocation = location;
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getUserJobsStream() {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    return Supabase.instance.client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('created_by', uid)
        .order('created_at')
        .asyncMap((data) async {
          // Enrich with provider name and distance
          for (var job in data) {
            final acceptedBy = job['accepted_by'];
            if (acceptedBy != null) {
              try {
                final providerRows = await Supabase.instance.client
                    .from('users')
                    .select('name')
                    .eq('id', acceptedBy)
                    .limit(1);
                if (providerRows is List && providerRows.isNotEmpty) {
                  job['provider_name'] = providerRows.first['name'];
                }
              } catch (_) {}

              if (_userLocation != null) {
                final providerLocation = await LocationService.getUserLocation(
                  acceptedBy,
                );
                if (providerLocation != null) {
                  final distance = LocationService.calculateDistance(
                    _userLocation!['latitude'],
                    _userLocation!['longitude'],
                    providerLocation['latitude'],
                    providerLocation['longitude'],
                  );
                  job['distance'] = distance;
                }
              }
            }
          }
          return data;
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
        // title: const Text('My Job Requests'),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.refresh),
        //     onPressed: () {
        //       _loadUserLocation();
        //       setState(() {});
        //     },
        //     tooltip: 'Refresh',
        //   ),
        // ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getUserJobsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snapshot.data!;
          if (jobs.isEmpty) {
            return const Center(child: Text('No job requests yet.'));
          }

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final status = job['status'];
              final providerName = job['provider_name'] ?? 'Unknown';
              final distance = job['distance'];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: status == 'completed'
                        ? Colors.green
                        : status == 'accepted'
                        ? Colors.green
                        : Colors.orange,
                    child: Icon(
                      status == 'completed'
                          ? Icons.done_all
                          : status == 'accepted'
                          ? Icons.check
                          : Icons.pending,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    job['title'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: $status'),
                      if (status == 'accepted' || status == 'completed') ...[
                        Text(
                          status == 'completed'
                              ? 'Completed by: $providerName'
                              : 'Accepted by: $providerName',
                        ),
                        if (distance != null)
                          Text(
                            _formatDistance(distance),
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ],
                  ),
                  isThreeLine: true,
                  trailing: (status == 'accepted' || status == 'completed')
                      ? Material(
                          color: const Color(0xFFE5F6F8),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    jobId: job['id'],
                                    jobTitle: job['title'],
                                    otherUserId: job['accepted_by'],
                                  ),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                color: Color(0xFF00A6B2),
                                size: 28,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
