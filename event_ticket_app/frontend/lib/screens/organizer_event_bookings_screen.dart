import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/Event.dart';
import '../service/api_service.dart';

// Organizer Event Bookings Screen
class OrganizerEventBookingsScreen extends StatefulWidget {
  final Event event;

  const OrganizerEventBookingsScreen({super.key, required this.event});

  State<OrganizerEventBookingsScreen> createState() =>
      _OrganizerEventBookingsScreenState();
}

class _OrganizerEventBookingsScreenState
    extends State<OrganizerEventBookingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  int _totalTicketsSold = 0;
  double _totalRevenue = 0;

  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _apiService.getEventBookings(widget.event.id);
      setState(() {
        _bookings = data['bookings'];
        _totalTicketsSold = data['totalTicketsSold'];
        _totalRevenue = (data['totalRevenue'] as num).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Bookings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Column(
                    children: [
                      Text(
                        widget.event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            'Total Bookings',
                            '${_bookings.length}',
                            Icons.receipt,
                          ),
                          _buildStatCard(
                            'Tickets Sold',
                            '$_totalTicketsSold',
                            Icons.confirmation_number,
                          ),
                          _buildStatCard(
                            'Revenue',
                            '₹${_totalRevenue.toStringAsFixed(2)}',
                            Icons.currency_rupee,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bookings List
                Expanded(
                  child: _bookings.isEmpty
                      ? const Center(child: Text('No bookings yet'))
                      : RefreshIndicator(
                          onRefresh: _fetchBookings,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _bookings.length,
                            itemBuilder: (context, index) {
                              final booking = _bookings[index];
                              final totalPrice =
                                  booking.numberOfTickets * widget.event.price;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(
                                    booking.userName ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Booked on: ${DateFormat('MMM dd, yyyy').format(booking.bookingDate)}',
                                      ),
                                      Text(
                                        'Tickets: ${booking.numberOfTickets}',
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    '₹${totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
