import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';
import 'chat_page.dart';

class ProviderJobsPage extends StatefulWidget {
  const ProviderJobsPage({super.key});

  @override
  State<ProviderJobsPage> createState() => _ProviderJobsPageState();
}

class _ProviderJobsPageState extends State<ProviderJobsPage> {
  Map<String, dynamic>? _providerLocation;

  @override
  void initState() {
    super.initState();
    _loadProviderLocation();
  }

  Future<void> _completeJob(String jobId) async {
    try {
      await Supabase.instance.client
          .from('jobs')
          .update({'status': 'completed'})
          .eq('id', jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete job: $e')),
        );
      }
    }
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

  Stream<List<Map<String, dynamic>>> getAcceptedJobs() {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    return Supabase.instance.client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('accepted_by', uid)
        .order('created_at')
        .asyncMap((data) async {
          // Add distance information if provider location is available
          if (_providerLocation != null) {
            for (var job in data) {
              final userLocation = await LocationService.getUserLocation(
                job['created_by'],
              );
              if (userLocation != null) {
                final distance = LocationService.calculateDistance(
                  _providerLocation!['latitude'],
                  _providerLocation!['longitude'],
                  userLocation['latitude'],
                  userLocation['longitude'],
                );
                job['distance'] = distance;
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
        backgroundColor: const Color(0xFF23113B),
        title: const Text(
          'PROVIDER STATUS',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadProviderLocation();
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getAcceptedJobs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = snapshot.data!;
          if (jobs.isEmpty) {
            return const Center(child: Text('No accepted jobs yet.'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  ' JOBS:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final distance = job['distance'];

                    final isCompleted = (job['status'] ?? '') == 'completed';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF28C76F),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCompleted ? Icons.done_all : Icons.check,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job['title'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Text(
                                          'Status:  ',
                                          style: TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          job['status'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (distance != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDistance(distance),
                                        style: const TextStyle(
                                          color: Color(0xFF6C63FF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Chat button
                              Material(
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
                                          otherUserId: job['created_by'],
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
                              ),
                              const SizedBox(width: 8),
                              // Complete button
                              Material(
                                color: isCompleted
                                    ? const Color(0xFFEAECEF)
                                    : const Color(0xFFEFFAF1),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: isCompleted
                                      ? null
                                      : () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) {
                                              return AlertDialog(
                                                title: const Text('Complete job?'),
                                                content: const Text(
                                                  'Mark this job as completed. This cannot be undone.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    child: const Text('Complete'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          if (confirm == true) {
                                            await _completeJob(job['id']);
                                          }
                                        },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.task_alt,
                                          color: isCompleted
                                              ? const Color(0xFF9097A1)
                                              : const Color(0xFF27AE60),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isCompleted ? 'Completed' : 'Complete',
                                          style: TextStyle(
                                            color: isCompleted
                                                ? const Color(0xFF9097A1)
                                                : const Color(0xFF27AE60),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      backgroundColor: const Color(0xFFF6F6F9),
    );
  }
}
