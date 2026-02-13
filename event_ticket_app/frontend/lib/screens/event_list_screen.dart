import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import 'event_detail_screen.dart';
import 'my_bookings_screen.dart';

// Event List Screen (for Users)
class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  void initState() {
    super.initState();
    // Fetch events when screen loads
    Future.microtask(() {
      Provider.of<EventProvider>(context, listen: false).fetchAllEvents();
    });
  }

  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_number),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyBookingsScreen(),
                ),
              );
            },
            tooltip: 'My Bookings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator( // RefreshIndicator provides pull-to-refresh functionality
        onRefresh: () => eventProvider.fetchAllEvents(),
        child: eventProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : eventProvider.errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(eventProvider.errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => eventProvider.fetchAllEvents(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : eventProvider.events.isEmpty
            ? const Center(child: Text('No events available'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: eventProvider.events.length,
                itemBuilder: (context, index) {
                  final event = eventProvider.events[index];
                  return EventCard(
                    event: event,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(event: event),
                        ),
                      );
                      // If booking was successful, refresh events
                      if (result == true && mounted) {
                        eventProvider.fetchAllEvents();
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}

// Event Card Widget (reusable)
class EventCard extends StatelessWidget {
  final dynamic event; // Can be Event model
  final VoidCallback onTap; // VoidCallback is a function type that takes no arguments and returns void, used for onTap handlers

  const EventCard({super.key, required this.event, required this.onTap});

  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                event.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.event, size: 60),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Date
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy - hh:mm a').format(event.date),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price and Tickets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${event.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${event.availableTickets} tickets left',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: event.availableTickets > 10
                            ? Colors.green[100]
                            : Colors.orange[100],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
