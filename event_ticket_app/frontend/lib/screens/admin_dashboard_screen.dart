import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../service/api_service.dart';

// Admin Dashboard Screen
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _apiService.getAdminStats();
      setState(() {
        _stats = stats;
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
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: SingleChildScrollView( // SingleChildScrollView allows the whole dashboard to be scrollable, especially when there are many stats and charts
                physics: const AlwaysScrollableScrollPhysics(), // AlwaysScrollableScrollPhysics allows pull-to-refresh even when content is not enough to scroll
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Stats
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildOverviewCards(),
                    const SizedBox(height: 32),

                    // Revenue Chart
                    Text(
                      'Revenue by Event',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRevenueChart(),
                    const SizedBox(height: 32),

                    // Top Events
                    Text(
                      'Top Events',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTopEvents(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final overview = _stats?['overview'] ?? {};
    return GridView.count(
      shrinkWrap: true, // shrinkWrap allows GridView to take only the space it needs, so it can be used inside a SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling since it's inside a scrollable parent
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Events',
          '${overview['totalEvents'] ?? 0}',
          Icons.event,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Bookings',
          '${overview['totalBookings'] ?? 0}',
          Icons.receipt,
          Colors.green,
        ),
        _buildStatCard(
          'Tickets Sold',
          '${overview['totalTicketsSold'] ?? 0}',
          Icons.confirmation_number,
          Colors.orange,
        ),
        _buildStatCard(
          'Total Revenue',
          '₹${(overview['totalRevenue'] ?? 0).toStringAsFixed(2)}',
          Icons.currency_rupee,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final revenueData = _stats?['eventStats'] as List? ?? [];

    if (revenueData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No data available')),
        ),
      );
    }

    // Take top 5 events
    final topEvents = revenueData.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: topEvents.isEmpty
                  ? 100
                  : topEvents
                            .map((e) => (e['revenue'] as num).toDouble())
                            .reduce((a, b) => a > b ? a : b) *
                        1.2, // Add 20% height to the max Y value (max revenue)
              barTouchData: BarTouchData(enabled: false), // Disable touch interactions
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles( // Show event titles on the x-axis(disabled left, top, right titles)
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= topEvents.length) {
                        return const Text('');
                      }
                      final eventTitle =
                          topEvents[value.toInt()]['eventTitle'] ?? '';
                      return Text(
                        eventTitle.length > 8
                            ? '${eventTitle.substring(0, 8)}...'
                            : eventTitle,
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate( // Generate bars based on top events
                topEvents.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: (topEvents[index]['revenue'] as num).toDouble(),
                      color: Colors.blue,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopEvents() {
    final revenueData = _stats?['eventStats'] as List? ?? [];

    if (revenueData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No events yet'),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: revenueData.length > 5 ? 5 : revenueData.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final event = revenueData[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text('${index + 1}'),
            ),
            title: Text(
              event['eventTitle'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Tickets: ${event['totalTicketsSold']}'),
            trailing: Text(
              '₹${(event['revenue'] as num).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
