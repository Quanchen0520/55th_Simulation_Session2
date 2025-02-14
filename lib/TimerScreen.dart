import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'ClockPainter.dart'; // 確保這個檔案存在並正確導入

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  int totalSeconds = 1500; // 25 分鐘
  bool isRunning = true;
  List<int> focusData = [30, 45, 60, 20, 50, 40, 35];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalSeconds),
    );
    _controller.forward();
    _startTimer();
    _listenForShake();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (totalSeconds > 0) {
        setState(() {
          totalSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _controller.stop();
    setState(() {
      isRunning = false;
    });
  }

  void _resumeTimer() {
    _startTimer();
    _controller.forward();
    setState(() {
      isRunning = true;
    });
  }

  void _listenForShake() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if ((event.x.abs() > 10 || event.y.abs() > 10 || event.z.abs() > 10) && isRunning) {
        _pauseTimer();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _accelerometerSubscription?.cancel(); // 取消訂閱，避免記憶體洩漏
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: CustomPaint(
                painter: ClockPainter(_controller.value),
                size: Size(300, 300),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: false),
                  barGroups: focusData.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [BarChartRodData(toY: e.value.toDouble(), color: Colors.red)],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isRunning ? _pauseTimer : _resumeTimer,
        child: Icon(isRunning ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
