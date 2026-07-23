import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'create_resource_screen.dart';
import 'edit_resource_screen.dart';
import '../utils/snackbar_helper.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List resources = [];
  List filteredResources = [];
  bool isLoading = true;
  String errorMessage = '';
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchResources();
    searchController.addListener(applyFilter);
  }

  Future<void> fetchResources() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _authService.getToken();

      final response = await _apiService.getRequest(
        '/api/resources',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          resources = data;
          filteredResources = data;
          isLoading = false;
        });
      } else {
        setState(() {
          resources = [];
          filteredResources = [];
          isLoading = false;
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Exception: $e';
      });
    }
  }

  void applyFilter() {
    final query = searchController.text.toLowerCase().trim();

    setState(() {
      filteredResources = resources.where((resource) {
        final name = (resource['name'] ?? '').toString().toLowerCase();
        final type = (resource['type'] ?? '').toString().toLowerCase();
        return name.contains(query) || type.contains(query);
      }).toList();
    });
  }

  Future<void> deleteResource(int id) async {
  final token = await _authService.getToken();

  final response = await _apiService.deleteRequest(
    '/api/resources/$id',
    token: token,
  );

  dynamic data = {};
  if (response.body.isNotEmpty) {
    try {
      data = jsonDecode(response.body);
    } catch (_) {}
  }

  if (!mounted) return;

  if (response.statusCode == 200) {
    SnackbarHelper.showSuccess(context, 'Resource deleted successfully');
  } else {
    SnackbarHelper.showError(
      context,
      data['message'] ?? 'Failed to delete resource',
    );
  }

  fetchResources();
}

  void confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteResource(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget buildResourceCard(dynamic resource) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(resource['name'] ?? 'Unnamed Resource'),
        subtitle: Text(
          '${resource['type']} • Capacity: ${resource['capacity']} • Priority: ${resource['priority']}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditResourceScreen(resource: resource),
                  ),
                );
                fetchResources();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => confirmDelete(resource['id'], resource['name']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search resources',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : filteredResources.isEmpty
                         ? Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey),
        SizedBox(height: 12),
        Text(
          'No resources found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6),
        Text(
          'Create a resource to get started',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
  )
                        : RefreshIndicator(
                            onRefresh: fetchResources,
                            child: ListView.builder(
                              itemCount: filteredResources.length,
                              itemBuilder: (context, index) {
                                return buildResourceCard(filteredResources[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateResourceScreen(),
            ),
          );
          fetchResources();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}