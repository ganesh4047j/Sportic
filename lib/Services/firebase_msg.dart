import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Providers/view_request_provider.dart';

class ViewRequestsPage extends ConsumerWidget {
  const ViewRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingRequestsAsync = ref.watch(viewRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Friend Requests')),
      body: incomingRequestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(child: Text('No friend requests'));
          }

          return ListView.separated(
            itemCount: requests.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final sender = requests[index];
              final name = sender['name'] ?? 'Unknown';
              final email = sender['email'];
              final location = sender['location'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text(email ?? ''),
                                Text(location),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (email == null || email.isEmpty) return;
                              await ref.read(acceptRequestProvider(email));
                              ref.invalidate(viewRequestsProvider);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Accept'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              if (email == null || email.isEmpty) return;
                              await ref.read(rejectRequestProvider(email));
                              ref.invalidate(viewRequestsProvider);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Reject'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}