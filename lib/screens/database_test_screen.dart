import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/personal_details.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<PersonalDetails> _allDetails = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final details = await _dbHelper.getAllPersonalDetails();
    // For each detail, we could load projects, but let's keep it simple for now and just show personal details.
    setState(() {
      _allDetails = details;
      _isLoading = false;
    });
  }

  Future<void> _deleteAll() async {
    await _dbHelper.deleteAllData();
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _deleteAll,
            tooltip: 'Delete All',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allDetails.isEmpty
              ? const Center(child: Text('No data found'))
              : ListView.builder(
                  itemCount: _allDetails.length,
                  itemBuilder: (context, index) {
                    final details = _allDetails[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('${details.firstName} ${details.lastName}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${details.email}'),
                            Text('Phone: ${details.phone}'),
                            Text('Job Target: ${details.jobTarget}'),
                            if (details.summary.isNotEmpty)
                              Text('Summary: ${details.summary}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            if (details.id != null) {
                              await _dbHelper
                                  .deletePersonalDetails(details.id!);
                              _loadAll();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
