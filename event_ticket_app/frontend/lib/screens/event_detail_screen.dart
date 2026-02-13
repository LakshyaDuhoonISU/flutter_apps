import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/Event.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import 'edit_event_screen.dart';

// Event Detail Screen
class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int _numberOfTickets = 1;

  // Handle booking
  void _handleBooking() async {
    if (_numberOfTickets > (widget.event.availableTickets ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough tickets available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Text(
          'Book $_numberOfTickets ticket(s) for ₹${(widget.event.price * _numberOfTickets).toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      final success = await bookingProvider.createBooking(
        eventId: widget.event.id,
        numberOfTickets: _numberOfTickets,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate booking was made
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingProvider.errorMessage ?? 'Booking failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOrganizer =
        authProvider.currentUser?.id == widget.event.organizerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          // Show Edit button only if current user is the organizer
          if (isOrganizer)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Event',
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEventScreen(event: widget.event),
                  ),
                );
                // If event was updated, pop back with true to refresh parent
                if (updated == true && mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            Image.network(
              widget.event.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Icon(Icons.event, size: 80),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.event.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Date',
                    DateFormat('EEEE, MMM dd, yyyy').format(widget.event.date),
                  ),
                  const SizedBox(height: 12),

                  // Time
                  _buildInfoRow(
                    Icons.access_time,
                    'Time',
                    DateFormat('hh:mm a').format(widget.event.date),
                  ),
                  const SizedBox(height: 12),

                  // Location
                  _buildInfoRow(
                    Icons.location_on,
                    'Location',
                    widget.event.location,
                  ),
                  const SizedBox(height: 12),

                  // Organizer
                  if (widget.event.organizerName != null)
                    _buildInfoRow(
                      Icons.person,
                      'Organizer',
                      widget.event.organizerName!,
                    ),
                  const SizedBox(height: 12),

                  // Price
                  _buildInfoRow(
                    Icons.payments,
                    'Price per ticket',
                    '₹${widget.event.price.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),

                  // Available Tickets
                  _buildInfoRow(
                    Icons.confirmation_number,
                    'Available Tickets',
                    '${widget.event.availableTickets} / ${widget.event.totalTickets}',
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'About Event',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),

                  // Show booking section only for non-organizers
                  if (!isOrganizer) ...[
                    // Ticket Selection
                    Text(
                      'Number of Tickets',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        IconButton(
                          onPressed: _numberOfTickets > 1
                              ? () {
                                  setState(() {
                                    _numberOfTickets--;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 32,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$_numberOfTickets',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed:
                              _numberOfTickets <
                                  (widget.event.availableTickets ?? 0)
                              ? () {
                                  setState(() {
                                    _numberOfTickets++;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 32,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Total Price
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${(widget.event.price * _numberOfTickets).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Book Button
                    Consumer<BookingProvider>(
                      builder: (context, bookingProvider, child) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                (widget.event.availableTickets ?? 0) > 0 &&
                                    !bookingProvider.isLoading
                                ? _handleBooking
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: bookingProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    (widget.event.availableTickets ?? 0) > 0
                                        ? 'Book Now'
                                        : 'Sold Out',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ], // End of booking section for non-organizers
                  // Show message for organizers
                  if (isOrganizer)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You are the organizer of this event. Use the edit button above to modify event details.',
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build info rows
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
