import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/recommendation_service.dart';
import '../models/mood_models.dart';

class MusicPlayerScreen extends StatefulWidget {
  final String? initialMusicUrl;
  final List<dynamic>? musicList;
  final Recommendation? recommendation;

  const MusicPlayerScreen({
    Key? key,
    this.initialMusicUrl,
    this.musicList,
    this.recommendation,
  }) : super(key: key);

  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final RecommendationService _recommendationService = RecommendationService();
  List<Map<String, dynamic>> allMusic = [];
  bool isLoading = true;
  bool isSaving = false;
  String? currentPlayingUrl;

  @override
  void initState() {
    super.initState();
    currentPlayingUrl = widget.initialMusicUrl;
    loadMusic();
  }

  Future<void> _markAsCompleted() async {
    if (widget.recommendation == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      await _recommendationService.updateRecommendationStatus(
        widget.recommendation!.recommendationId,
        true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Recommendation completed successfully! ✅',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> loadMusic() async {
    try {
      if (widget.musicList != null && widget.musicList!.isNotEmpty) {
        setState(() {
          allMusic = widget.musicList!.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        final music = await _recommendationService.getRelaxingMusic();
        setState(() {
          allMusic = music;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading music: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load music: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> playMusic(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() {
          currentPlayingUrl = url;
        });
      } else {
        throw 'Cannot play music';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing music: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3E5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFF9C27B0),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Calming Music 🎵',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
              ),
            )
          : allMusic.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎼', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 16),
                      Text(
                        'No music available',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header card
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFBA68C8).withOpacity(0.3),
                            Color(0xFF9C27B0).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(0xFF9C27B0).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF9C27B0).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('🎵', style: TextStyle(fontSize: 32)),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Relax and listen',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9C27B0),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Choose the music that suits you',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Music list
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: allMusic.length,
                        itemBuilder: (context, index) {
                          final music = allMusic[index];
                          final isPlaying =
                              currentPlayingUrl == music['url'];
                          return _buildMusicCard(music, isPlaying);
                        },
                      ),
                    ),

                    // Complete Button
                    if (widget.recommendation != null)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _markAsCompleted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF9C27B0),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: isSaving
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Completed ✓',
                                      style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildMusicCard(Map<String, dynamic> music, bool isPlaying) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPlaying
              ? [Color(0xFF9C27B0), Color(0xFF7B1FA2)]
              : [Color(0xFFBA68C8), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF9C27B0).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => playMusic(music['url']),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      music['icon'] ?? '🎵',
                      style: TextStyle(fontSize: 26),
                    ),
                  ),
                ),

                SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        music['title'] ?? 'Music',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        music['duration'] ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Play button
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
