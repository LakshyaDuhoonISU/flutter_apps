import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';

// My Bookings Screen (User)
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  void initState() {
    super.initState();
    // Fetch bookings when screen loads
    Future.microtask(() {
      Provider.of<BookingProvider>(context, listen: false).fetchMyBookings();
    });
  }

  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: RefreshIndicator(
        onRefresh: () => bookingProvider.fetchMyBookings(),
        child: bookingProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : bookingProvider.errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(bookingProvider.errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => bookingProvider.fetchMyBookings(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : bookingProvider.bookings.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No bookings yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookingProvider.bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookingProvider.bookings[index];
                  final event = booking.event;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Booking ID
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Booking #${booking.id.substring(0, 8)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(booking.bookingDate),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: Colors.green[100],
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Event Info
                          if (event != null) ...[
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    event.imageUrl,
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 60,
                                        width: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.event),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat(
                                          'MMM dd, yyyy - hh:mm a',
                                        ).format(event.date),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        event.location,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Tickets and Price
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.confirmation_number,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${booking.numberOfTickets} Ticket(s)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '₹${booking.totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const Text('Event details unavailable'),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
