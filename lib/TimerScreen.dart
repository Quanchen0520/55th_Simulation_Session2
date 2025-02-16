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

  int selectedMinutes = 25; // 使用者選擇的時間
  int totalSeconds = 1500;  // 預設為 25 分鐘
  bool isRunning = false;   // 記錄計時狀態

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalSeconds),
    );
    _listenForShake(); // 啟動搖晃偵測
  }

  // 開始計時
  void _startTimer() {
    setState(() {
      totalSeconds = selectedMinutes * 60; // 根據選擇的分鐘數重新計算秒數
      isRunning = true;
      _controller.duration = Duration(seconds: totalSeconds);
      _controller.forward(from: 0.0); // 重新啟動動畫
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (totalSeconds > 0) {
        setState(() {
          totalSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          isRunning = false;
        });
      }
    });
  }

  // 暫停計時
  void _pauseTimer() {
    _timer?.cancel();
    _controller.stop();
    setState(() {
      isRunning = false;
    });
  }

  // 監聽搖晃暫停
  void _listenForShake() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if ((event.x.abs() > 15 || event.y.abs() > 15 || event.z.abs() > 10) && isRunning) {
        _pauseTimer(); // 偵測到搖晃則暫停計時
      }
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
          // 倒數計時顯示
          Text(
            "${(totalSeconds ~/ 60).toString().padLeft(2, '0')}:${(totalSeconds % 60).toString().padLeft(2, '0')}",
            style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: CustomPaint(
                painter: ClockPainter(_controller.value, selectedMinutes), // 傳遞選擇的分鐘數
                size: Size(300, 300),
              ),
            ),
          ),
          // 時間選擇 Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Text(
                  "工作時間：$selectedMinutes 分鐘",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Slider(
                  value: selectedMinutes.toDouble(),
                  min: 5,
                  max: 25,
                  divisions: 4, // 5, 10, 15, 20, 25
                  label: "$selectedMinutes 分鐘",
                  onChanged: (value) {
                    setState(() {
                      selectedMinutes = value.toInt();
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
              SizedBox(width: 10),
              IconButton(
                  onPressed: TaskShow,
                  icon: Icon(Icons.library_books,color: Colors.white)
              ),
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.analytics,color: Colors.white)
              ),
            ],
          )
        ],
      ),
    );
  }

  void TaskShow() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允許全螢幕
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // 預設高度（50%螢幕）
          minChildSize: 0.3, // 最小高度（30%螢幕）
          maxChildSize: 1.0, // 最大高度（全螢幕）
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ListView(
                controller: scrollController, // 讓內容可滾動
                children: [
                  Row(
                    children: [
                      Text(
                        '任務清單',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              int workMinutes = 15; // 預設工作時間
                              int restMinutes = 3;  // 預設休息時間

                              return StatefulBuilder( // 讓 setState() 正常運作
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: Text("新增任務"),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min, // 讓對話框高度符合內容
                                      children: [
                                        Text("工作時間"),
                                        Slider(
                                          value: workMinutes.toDouble(),
                                          min: 5,
                                          max: 25,
                                          divisions: 4,
                                          label: "$workMinutes min",
                                          onChanged: (value) {
                                            setState(() {
                                              workMinutes = value.toInt();
                                            });
                                          },
                                        ),
                                        SizedBox(height: 10), // 增加間距
                                        Text("休息時間"),
                                        Slider(
                                          value: restMinutes.toDouble(),
                                          min: 3,
                                          max: 5,
                                          divisions: 2,
                                          label: "$restMinutes min",
                                          onChanged: (value) {
                                            setState(() {
                                              restMinutes = value.toInt();
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text("取消"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text("確定"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                          child: Text("新增任務")
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  ListTile(title: Text('任務 1')),
                  ListTile(title: Text('任務 2')),
                  ListTile(title: Text('任務 3')),
                ],
              ),
            );
          },
        );
      },
    );
  }
}