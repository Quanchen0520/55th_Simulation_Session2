import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart'; // 加速度感應器
import 'ClockPainter.dart';
import 'TaskStorage.dart';

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
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: TaskStorage.loadTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("載入失敗"));
                }

                List<Map<String, dynamic>> tasks = snapshot.data ?? [];

                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '任務清單',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Spacer(),
                          TextButton(
                            onPressed: () {
                              _showAddTaskDialog(context); // 這裡不呼叫 TaskShow()，讓對話框自己處理
                            },
                            child: Text("新增任務"),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return ListTile(
                              title: Text("工作 ${task["workMinutes"]} 分鐘"),
                              subtitle: Text("休息 ${task["restMinutes"]} 分鐘"),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int workMinutes = 15;
        int restMinutes = 3;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("新增任務"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
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
                  SizedBox(height: 10),
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
                  onPressed: () async {
                    await TaskStorage.saveTask(workMinutes, restMinutes);
                    Navigator.pop(context);
                    Navigator.pop(context);
                    TaskShow(); // 重新打開 TaskShow() 更新畫面
                  },
                  child: Text("確定"),
                ),
              ],
            );
          },
        );
      },
    );
  }

}