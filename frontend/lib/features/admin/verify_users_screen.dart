import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class VerifyUsersScreen extends StatefulWidget {
  const VerifyUsersScreen({super.key});

  @override
  State<VerifyUsersScreen> createState() => _VerifyUsersScreenState();
}

class _VerifyUsersScreenState extends State<VerifyUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _unverifiedDrivers = [];
  List<dynamic> _unverifiedConnectors = [];
  bool _isLoadingDrivers = true;
  bool _isLoadingConnectors = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadDrivers(), _loadConnectors()]);
  }

  Future<void> _loadDrivers() async {
    setState(() => _isLoadingDrivers = true);
    try {
      final drivers = await ApiService.getUnverifiedDrivers();
      setState(() {
        _unverifiedDrivers = drivers;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading drivers: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingDrivers = false);
    }
  }

  Future<void> _loadConnectors() async {
    setState(() => _isLoadingConnectors = true);
    try {
      final connectors = await ApiService.getUnverifiedConnectors();
      setState(() {
        _unverifiedConnectors = connectors;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading connectors: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingConnectors = false);
    }
  }

  Future<void> _verifyDriver(String driverId) async {
    try {
      await ApiService.verifyDriver(driverId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDrivers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyConnector(String connectorId) async {
    try {
      await ApiService.verifyConnector(connectorId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connector verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadConnectors();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B3A),
      appBar: AppBar(
        title: const Text('Verify Users'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Drivers', icon: Icon(Icons.directions_bus)),
            Tab(text: 'Connectors', icon: Icon(Icons.connect_without_contact)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDriversList(),
          _buildConnectorsList(),
        ],
      ),
    );
  }

  Widget _buildDriversList() {
    if (_isLoadingDrivers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_unverifiedDrivers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'All drivers are verified!',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDrivers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _unverifiedDrivers.length,
        itemBuilder: (context, index) {
          final driver = _unverifiedDrivers[index];
          return Card(
            color: const Color(0xFF2A2B4A),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2563EB),
                        child: Text(
                          driver['fullName'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver['fullName'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              driver['email'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Phone', driver['phone'] ?? 'N/A'),
                  _buildInfoRow('License No.', driver['licenseNumber'] ?? 'N/A'),
                  _buildInfoRow('NIC No.', driver['nicNumber'] ?? 'N/A'),
                  _buildInfoRow('Bus No.', driver['busNumber'] ?? 'N/A'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showVerifyDialog(
                        context,
                        'Driver',
                        driver['fullName'],
                        () => _verifyDriver(driver['id']),
                      ),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Verify Driver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectorsList() {
    if (_isLoadingConnectors) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_unverifiedConnectors.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'All connectors are verified!',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConnectors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _unverifiedConnectors.length,
        itemBuilder: (context, index) {
          final connector = _unverifiedConnectors[index];
          return Card(
            color: const Color(0xFF2A2B4A),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2563EB),
                        child: Text(
                          connector['fullName'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connector['fullName'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              connector['email'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Phone', connector['phone'] ?? 'N/A'),
                  _buildInfoRow('License No.', connector['licenseNumber'] ?? 'N/A'),
                  _buildInfoRow('NIC No.', connector['nicNumber'] ?? 'N/A'),
                  _buildInfoRow('Vehicle No.', connector['vehicleNumber'] ?? 'N/A'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showVerifyDialog(
                        context,
                        'Connector',
                        connector['fullName'],
                        () => _verifyConnector(connector['id']),
                      ),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Verify Connector'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(color: Colors.white70),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerifyDialog(
    BuildContext context,
    String userType,
    String userName,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2B4A),
        title: Text(
          'Verify $userType',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to verify $userName?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}