import 'package:flutter/material.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:puremood_frontend/services/api_service.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _loading = true;
  String _error = '';

  List<_MomentItem> _gratitudeMoments = [];
  List<_MomentItem> _reflectionMoments = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    try {
      setState(() {
        _loading = true;
        _error = '';
      });

      final moods = await _api.getUserMoods();
      final List<_MomentItem> gratitude = [];
      final List<_MomentItem> reflections = [];

      for (final mood in moods) {
        final String emoji = (mood['mood_emoji'] ?? '').toString();
        final String note = (mood['note_text'] ?? mood['note'] ?? '').toString();
        final String createdAt = (mood['created_at'] ?? '').toString();

        if (note.isEmpty) continue;

        final DateTime? date = DateTime.tryParse(createdAt);

        final lines = note.split('\n');
        for (final rawLine in lines) {
          final line = rawLine.trim();
          if (line.isEmpty) continue;

          if (line.startsWith('[Gratitude]')) {
            final text = line.replaceFirst('[Gratitude]', '').trim();
            if (text.isNotEmpty) {
              gratitude.add(_MomentItem(
                type: MomentType.gratitude,
                text: text,
                emoji: emoji,
                date: date,
              ));
            }
          } else if (line.startsWith('[Reflection]')) {
            final text = line.replaceFirst('[Reflection]', '').trim();
            if (text.isNotEmpty) {
              reflections.add(_MomentItem(
                type: MomentType.reflection,
                text: text,
                emoji: emoji,
                date: date,
              ));
            }
          }
        }
      }

      // أحدث اللحظات أولاً
      gratitude.sort((a, b) => (b.date ?? DateTime(1970))
          .compareTo(a.date ?? DateTime(1970)));
      reflections.sort((a, b) => (b.date ?? DateTime(1970))
          .compareTo(a.date ?? DateTime(1970)));

      setState(() {
        _gratitudeMoments = gratitude;
        _reflectionMoments = reflections;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: const Color(0xFFE8F5F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        elevation: 0,
        title: Text(
          'Your Moments',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Gratitude'),
            Tab(text: 'Reflections'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error,
            style: GoogleFonts.poppins(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_gratitudeMoments.isEmpty && _reflectionMoments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'You have no saved moments yet.\nTry adding Reflections or Gratitude notes when tracking your mood.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildMomentsList(_gratitudeMoments, emptyLabel: 'No gratitude moments yet'),
        _buildMomentsList(_reflectionMoments, emptyLabel: 'No reflections yet'),
      ],
    );
  }

  Widget _buildMomentsList(List<_MomentItem> items, {required String emptyLabel}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: GoogleFonts.poppins(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMomentCard(item);
      },
    );
  }

  Widget _buildMomentCard(_MomentItem item) {
    final Color baseColor =
        item.type == MomentType.gratitude ? Colors.orange : Colors.teal;
    final String title =
        item.type == MomentType.gratitude ? 'Gratitude' : 'Reflection';

    return Card
(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.emoji.isNotEmpty ? item.emoji : '📝',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: baseColor,
                      ),
                    ),
                    if (item.date != null)
                      Text(
                        _formatDate(item.date!),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[(date.weekday - 1) % 7];
    final monthName = months[date.month - 1];
    return '$dayName, $monthName ${date.day}, ${date.year}';
  }
}

enum MomentType { gratitude, reflection }

class _MomentItem {
  final MomentType type;
  final String text;
  final String emoji;
  final DateTime? date;

  _MomentItem({
    required this.type,
    required this.text,
    required this.emoji,
    required this.date,
  });
}
