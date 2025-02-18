import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart'; // 加速度感應器
import 'ClockPainter.dart';

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  int workMinutes = 25;
  int breakMinutes = 5;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: (workMinutes + breakMinutes) * 60),
    );
  }

  // **開始計時**
  void _startTimer() {
    setState(() {
      isRunning = true;
      _controller.duration = Duration(seconds: (workMinutes + breakMinutes) * 60);
      _controller.forward(from: 0.0);
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_controller.value >= 1.0) {
        _timer?.cancel();
        setState(() {
          isRunning = false;
        });
      }
    });
  }

  // **暫停計時**
  void _pauseTimer() {
    _timer?.cancel();
    _controller.stop();
    setState(() {
      isRunning = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SizedBox(height: 35),
          // **顯示倒數時間**
          Text(
            "${((1 - _controller.value) * (workMinutes + breakMinutes)).toInt()} 分鐘",
            style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: CustomPaint(
                painter: ClockPainter(_controller.value, workMinutes, breakMinutes),
                size: Size(300, 300),
              ),
            ),
          ),
          // **時間選擇 Slider**
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Text(
                  "工作時間：$workMinutes 分鐘",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Slider(
                  value: workMinutes.toDouble(),
                  min: 5,
                  max: 25,
                  divisions: 4,
                  label: "$workMinutes 分鐘",
                  onChanged: (value) {
                    setState(() {
                      workMinutes = value.toInt();
                      _controller.duration = Duration(seconds: (workMinutes + breakMinutes) * 60);
                    });
                  },
                ),
                Text(
                  "休息時間：$breakMinutes 分鐘",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Slider(
                  value: breakMinutes.toDouble(),
                  min: 3,
                  max: 10,
                  divisions: 4,
                  label: "$breakMinutes 分鐘",
                  onChanged: (value) {
                    setState(() {
                      breakMinutes = value.toInt();
                      _controller.duration = Duration(seconds: (workMinutes + breakMinutes) * 60);
                    });
                  },
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: isRunning ? _pauseTimer : _startTimer,
                child: Text(isRunning ? "暫停" : "開始"),
              ),
            ],
          )
        ],
      ),
    );
  }
}