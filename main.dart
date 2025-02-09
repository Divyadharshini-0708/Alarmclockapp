import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const AlarmClockApp());
}

class AlarmClockApp extends StatelessWidget {
  const AlarmClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alarm Clock',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentTime = '';
  String _currentDate = '';
  List<Map<String, dynamic>> _alarms = [];

  final List<String> _tones = ['Tone 1', 'Tone 2', 'Tone 3'];
  Timer? _alarmTimer;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Audio player instance

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('hh:mm a').format(DateTime.now());
      _currentDate = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  void _addAlarm(TimeOfDay time, String tone) {
    setState(() {
      _alarms.add({
        'time': time,
        'tone': tone,
        'enabled': true,
      });
    });
  }

  void _ringAlarm(Map<String, dynamic> alarm) async {
    if (_alarmTimer != null) return; // Prevent multiple triggers

    // Play the alarm tone
    final tone = alarm['tone'];
    await _playTone(tone);

    _alarmTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            AlertDialog(
              title: const Text('Alarm Ringing!'),
              content: Text('Time: ${alarm['time'].hour}:${alarm['time']
                  .minute}\nTone: ${alarm['tone']}'),
              actions: [
                TextButton(
                  onPressed: () {
                    _snoozeAlarm(alarm);
                  },
                  child: const Text('Snooze'),
                ),
                TextButton(
                  onPressed: () {
                    _dismissAlarm(alarm);
                  },
                  child: const Text('Dismiss'),
                ),
              ],
            ),
      );
    });
  }

  Future<void> _playTone(String tone) async {
    // Play a specific tone based on the selected tone
    String toneUrl = ''; // Replace this with a valid local or network URL for your tones

    if (tone == 'Tone 1') {
      toneUrl = 'assets/tones/tone1.mp3';
    } else if (tone == 'Tone 2') {
      toneUrl = 'assets/tones/tone2.mp3';
    } else if (tone == 'Tone 3') {
      toneUrl = 'assets/tones/tone3.mp3';
    }
    await _audioPlayer.play(DeviceFileSource(toneUrl)); // Play the tone
  }


  void _snoozeAlarm(Map<String, dynamic> alarm) async {
    await _audioPlayer.stop(); // Stop the audio
    Navigator.pop(context);
    _alarmTimer?.cancel();
    _alarmTimer = null;

    // Snooze for 5 minutes
    final snoozeTime = TimeOfDay(
      hour: alarm['time'].hour,
      minute: (alarm['time'].minute + 5) % 60,
    );
    alarm['time'] = snoozeTime;
  }

  void _dismissAlarm(Map<String, dynamic> alarm) async {
    await _audioPlayer.stop(); // Stop the audio
    Navigator.pop(context);
    _alarmTimer?.cancel();
    _alarmTimer = null;

    setState(() {
      alarm['enabled'] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Clock'),
      ),
      body: Column(
        children: [
          // Current time and date
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  _currentTime,
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentDate,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),

          const Divider(),

          // List of alarms
          Expanded(
            child: ListView.builder(
              itemCount: _alarms.length,
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                return ListTile(
                  leading: const Icon(Icons.alarm),
                  title: Text(
                    '${alarm['time'].hour.toString().padLeft(
                        2, '0')}:${alarm['time'].minute.toString().padLeft(
                        2, '0')}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: alarm['enabled'] ? Colors.black : Colors.grey,
                    ),
                  ),
                  subtitle: Text('Tone: ${alarm['tone']}'),
                  trailing: Switch(
                    value: alarm['enabled'],
                    onChanged: (value) {
                      setState(() {
                        alarm['enabled'] = value;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Button to add new alarm
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (pickedTime != null) {
            String? selectedTone = await showDialog<String>(
              context: context,
              builder: (context) =>
                  AlertDialog(
                    title: const Text('Select Alarm Tone'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _tones.map((tone) {
                        return ListTile(
                          title: Text(tone),
                          onTap: () {
                            Navigator.pop(context, tone);
                          },
                        );
                      }).toList(),
                    ),
                  ),
            );
            if (selectedTone != null) {
              _addAlarm(pickedTime, selectedTone);
            }
          }
        },
        child: const Icon(Icons.add_alarm),
      ),
    );
  }
}
