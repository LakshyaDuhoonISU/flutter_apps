import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import 'create_event_screen.dart';
import 'edit_event_screen.dart';
import 'organizer_event_bookings_screen.dart';

// Organizer Dashboard
class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  void initState() {
    super.initState();
    // Fetch organizer's events when screen loads
    Future.microtask(() {
      Provider.of<EventProvider>(context, listen: false).fetchMyEvents();
    });
  }

  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEventScreen()),
          ).then((_) {
            // Refresh events after creating
            eventProvider.fetchMyEvents();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
      body: RefreshIndicator(
        onRefresh: () => eventProvider.fetchMyEvents(),
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
                      onPressed: () => eventProvider.fetchMyEvents(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : eventProvider.events.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No events yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to create your first event',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: eventProvider.events.length,
                itemBuilder: (context, index) {
                  final event = eventProvider.events[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey[300],
                                child: const Icon(Icons.event, size: 50),
                              );
                            },
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                              // Date & Location
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy - hh:mm a',
                                ).format(event.date),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.location,
                                style: TextStyle(color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),

                              // Stats
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStat(
                                    'Price',
                                    '₹${event.price.toStringAsFixed(2)}',
                                    Icons.payments,
                                  ),
                                  _buildStat(
                                    'Sold',
                                    '${event.ticketsSold}',
                                    Icons.confirmation_number,
                                  ),
                                  _buildStat(
                                    'Available',
                                    '${event.availableTickets}',
                                    Icons.event_available,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                OrganizerEventBookingsScreen(
                                                  event: event,
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.people, size: 18),
                                      label: const Text('Bookings'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final updated =
                                            await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditEventScreen(
                                                      event: event,
                                                    ),
                                              ),
                                            );
                                        // Refresh events if updated
                                        if (updated == true) {
                                          eventProvider.fetchMyEvents();
                                        }
                                      },
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Edit'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      _showDeleteDialog(event.id);
                                    },
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  // Helper widget for stats
  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // Show delete confirmation dialog
  void _showDeleteDialog(String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final eventProvider = Provider.of<EventProvider>(
                context,
                listen: false,
              );
              final success = await eventProvider.deleteEvent(eventId);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Event deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      eventProvider.errorMessage ?? 'Failed to delete event',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
