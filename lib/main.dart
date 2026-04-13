import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hỗ trợ kỹ thuật',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F66B3)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class DocumentItem {
  const DocumentItem({
    required this.title,
    required this.keyword,
    required this.url,
  });

  final String title;
  final String keyword;
  final String url;

  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        keyword.toLowerCase().contains(q) ||
        url.toLowerCase().contains(q);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentItem> _allDocuments = const [];
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await rootBundle.loadString('assets/documents.csv');
      final items = _parseDocuments(raw);
      if (!mounted) return;
      setState(() {
        _allDocuments = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được documents.csv. $e';
        _loading = false;
      });
    }
  }

  List<DocumentItem> _parseDocuments(String raw) {
    final lines = const LineSplitter()
        .convert(raw)
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];

    final items = <DocumentItem>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(';');
      if (parts.length < 3) continue;
      final title = parts[0].trim();
      final keyword = parts[1].trim();
      final url = parts.sublist(2).join(';').trim();
      if (title.isEmpty && url.isEmpty) continue;
      items.add(DocumentItem(title: title, keyword: keyword, url: url));
    }
    return items;
  }

  Future<void> _openDocument(DocumentItem item) async {
    final uri = Uri.tryParse(item.url);
    if (uri == null) {
      _showSnackBar('Link không hợp lệ');
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok && mounted) {
      _showSnackBar('Không mở được tài liệu');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allDocuments.where((e) => e.matches(_query)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ trợ kỹ thuật'),
        actions: [
          IconButton(
            tooltip: 'Tải lại dữ liệu',
            onPressed: _loadDocuments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, từ khóa...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => _searchController.clear(),
                              icon: const Icon(Icons.clear),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Tổng: ${_allDocuments.length} tài liệu'),
                      const Spacer(),
                      Text('Hiện: ${filtered.length}'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody(filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<DocumentItem> filtered) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Đang tải dữ liệu...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 12),
              FilledButton(
                onPressed: _loadDocuments,
                child: Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Không có tài liệu phù hợp.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(item.title),
            subtitle: item.keyword.isEmpty || item.keyword == item.title
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(item.keyword),
                  ),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openDocument(item),
          ),
        );
      },
    );
  }
}
