import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyPlayerHome(),
  ));
}

class MyPlayerHome extends StatefulWidget {
  const MyPlayerHome({super.key});

  @override
  State<MyPlayerHome> createState() => _MyPlayerHomeState();
}

class _MyPlayerHomeState extends State<MyPlayerHome> with SingleTickerProviderStateMixin {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late TabController _tabController;
  String searchQuery = "";
  bool isVaultLocked = true;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    requestPermission();
  }

  void requestPermission() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
    setState(() {});
  }

  // سیفٹی لاک (Vault) کھولنے کا فنکشن
  void _openVault() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Safety Lock", style: TextStyle(color: Colors.redAccent)),
        content: TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter 4-Digit PIN",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_pinController.text == "1234") { // آپ کا پاس ورڈ
                setState(() => isVaultLocked = false);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wrong PIN!")));
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
        // آپ کی ایپ کا صحیح نام یہاں سیٹ کر دیا ہے
        title: const Text("MY PLAYER", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.music_note), text: "Audio"),
            Tab(icon: Icon(Icons.video_collection), text: "Video"),
            Tab(icon: Icon(Icons.security), text: "Vault"),
          ],
        ),
      ),
      body: Column(
        children: [
          // سرچ بار
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search files...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. آڈیو پلیئر
                FutureBuilder<List<SongModel>>(
                  future: _audioQuery.querySongs(),
                  builder: (context, item) {
                    if (item.data == null) return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                    final songs = item.data!.where((song) => song.displayNameWOExt.toLowerCase().contains(searchQuery)).toList();
                    return ListView.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) => ListTile(
                        leading: const Icon(Icons.music_note, color: Colors.redAccent),
                        title: Text(songs[index].displayNameWOExt, style: const TextStyle(color: Colors.white)),
                        onTap: () async {
                          await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(songs[index].uri!)));
                          _audioPlayer.play();
                        },
                      ),
                    );
                  },
                ),
                // 2. ویڈیو پلیئر (Placeholder)
                const Center(child: Text("Video player is ready to load your files", style: TextStyle(color: Colors.grey))),
                
                // 3. سیفٹی لاک (Private Vault)
                Center(
                  child: isVaultLocked 
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 80, color: Colors.redAccent),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: _openVault,
                          child: const Text("Access Private Vault"),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_open, size: 80, color: Colors.green),
                        Text("Private Area Unlocked", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ],
                    ),
                ),
              ],
            ),
          ),
          // نیچے والے کنٹرول بٹن (Next, Play, Previous)
          Container(
            color: Colors.white10,
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: () {}),
                IconButton(icon: const Icon(Icons.play_circle_fill, size: 45, color: Colors.redAccent), onPressed: () {}),
                IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: () {}),
              ],
            ),
          )
        ],
      ),
    );
  }
}
