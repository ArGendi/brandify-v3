import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brandify/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedPackage;
  bool _sortByLatest = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp(String phone) async {
    final whatsappUrl = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        actions: [
          IconButton(
            icon: Icon(_sortByLatest ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () {
              setState(() {
                _sortByLatest = !_sortByLatest;
              });
            },
            tooltip: 'Sort by date',
          ),
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String? value) {
              setState(() {
                _selectedPackage = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String?>(
                value: null,
                child: Text('All Packages'),
              ),
              const PopupMenuItem<String?>(
                value: 'offline',
                child: Text('Offline'),
              ),
              const PopupMenuItem<String?>(
                value: 'online',
                child: Text('Online'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by brand name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  final userData = doc.data() as Map<String, dynamic>;
                  final brandName = (userData['brandName'] ?? '').toString().toLowerCase();
                  final package = userData['package'] as String?;
                  
                  bool matchesSearch = brandName.contains(_searchQuery);
                  bool matchesPackage = _selectedPackage == null || package == _selectedPackage;
                  
                  return matchesSearch && matchesPackage;
                }).toList();

                // Sort by createdAt
                filteredDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  
                  DateTime? aDate;
                  DateTime? bDate;
                  
                  if (aData['createdAt'] is Timestamp) {
                    aDate = (aData['createdAt'] as Timestamp).toDate();
                  } else if (aData['createdAt'] is String) {
                    aDate = DateTime.tryParse(aData['createdAt'] as String);
                  }
                  
                  if (bData['createdAt'] is Timestamp) {
                    bDate = (bData['createdAt'] as Timestamp).toDate();
                  } else if (bData['createdAt'] is String) {
                    bDate = DateTime.tryParse(bData['createdAt'] as String);
                  }
                  
                  // Place null dates at the end of the list
                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  return _sortByLatest 
                      ? bDate.compareTo(aDate)
                      : aDate.compareTo(bDate);
                });

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: mainColor, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Users',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: mainColor,
                                ),
                              ),
                              Text(
                                '${snapshot.data!.docs.length + 20}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: mainColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final userData = filteredDocs[index].data() as Map<String, dynamic>;
                          final userId = filteredDocs[index].id;

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          userData['brandName'] ?? 'No Brand Name',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: mainColor,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: userData['package'] == "offline" 
                                              ? Colors.grey 
                                              : userData['package'] == "online"? Colors.blue : Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          userData['package'] ?? 'No Package',
                                          style: TextStyle(
                                            color: userData['package'] == "offline" 
                                                ? mainColor 
                                                : Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: () {
                                      final phone = userData['brandPhone']?.toString().replaceAll(RegExp(r'[^0-9]'), '');
                                      if (phone != null && phone.isNotEmpty) {
                                        _launchWhatsApp(phone);
                                      }
                                    },
                                    child: _buildInfoRow(
                                      'Phone',
                                      userData['brandPhone'] ?? 'N/A',
                                      isClickable: true,
                                    ),
                                  ),
                                  _buildInfoRow('Created At', _formatDate(userData['createdAt'])),
                                  const SizedBox(height: 8),
                                  Text(
                                    'User ID: $userId',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isClickable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isClickable ? Colors.blue : null,
              decoration: isClickable ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    DateTime? dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is String) {
      dateTime = DateTime.tryParse(date);
    }
    
    if (dateTime == null) return 'N/A';
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
} 