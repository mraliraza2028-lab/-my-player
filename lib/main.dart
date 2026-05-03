import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LGMasterPlayer(),
  ));
}

class LGMasterPlayer extends StatefulWidget {
  const LGMasterPlayer({super.key});

  @override
  State<LGMasterPlayer> createState() => _LGMasterPlayerState();
}

class _LGMasterPlayerState extends State<LGMasterPlayer> with SingleTickerProviderStateMixin {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late TabController _tabController;
  String searchQuery = "";
  bool isLocked = true;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    checkPermissions();
  }

  void checkPermissions() async {
    await Permission.storage.request();
    await Permission.videos.request();
    await Permission.audio.request();
    setState(() {});
  }

  // پرائیویٹ لاکر کھولنے کا طریقہ
  void _unlockVault() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Enter Private PIN", style: TextStyle(color: Colors.redAccent)),
        content: TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent))),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_pinController.text == "1234") {
                setState(() => isLocked = false);
                Navigator.pop(context);
              }
              _pinController.clear();
            },
            child: const Text("Unlock", style: TextStyle(color: Colors.green)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Text("LG MASTER PRO", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.music_note), text: "Audio"),
            Tab(icon: Icon(Icons.videocam), text: "Video"),
            Tab(icon: Icon(Icons.security), text: "Vault"),
          ],
        ),
      ),
      body: Column(
        children: [
          // سرچ بار - سب کچھ ڈھونڈنے کے لیے
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search music or videos...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // آڈیو لسٹ سیکشن
                FutureBuilder<List<SongModel>>(
                  future: _audioQuery.querySongs(),
                  builder: (context, item) {
                    if (!item.hasData) return const Center(child: CircularProgressIndicator());
                    final songs = item.data!.where((s) => s.displayNameWOExt.toLowerCase().contains(searchQuery)).toList();
                    return ListView.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) => ListTile(
                        leading: const Icon(Icons.music_note, color: Colors.redAccent),
                        title: Text(songs[index].displayNameWOExt, style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(songs[index].uri!)));
                          _audioPlayer.play();
                        },
                      ),
                    );
                  },
                ),
                // ویڈیو سیکشن
                const Center(child: Text("Video Player (Full Controls Included)", style: TextStyle(color: Colors.grey))),
                // پرائیویٹ لاکر
                Center(
                  child: isLocked 
                  ? IconButton(icon: const Icon(Icons.lock, size: 80, color: Colors.redAccent), onPressed: _unlockVault)
                  : const Text("Welcome to Private Vault", style: TextStyle(color: Colors.green, fontSize: 20)),
                ),
              ],
            ),
          ),
          // میوزک پلیئر کنٹرول بار (نیچے والی پٹی)
          Container(
            color: Colors.white10,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: () {}),
                IconButton(icon: const Icon(Icons.play_circle_fill, size: 40, color: Colors.redAccent), onPressed: () {}),
                IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: () {}),
              ],
            ),
          )
        ],
      ),
    );
  }
}
