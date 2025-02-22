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
  late AnimationController _animationController;
  Timer? _countdownTimer;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  int workDuration = 25;
  int breakDuration = 5;
  int totalDurationInSeconds = 1500;
  bool isTimerRunning = false;
  bool isWorkMode = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalDurationInSeconds),
    );
    _initializeShakeDetection(); // 啟動搖晃偵測
  }

  void _startTimer() {
    setState(() {
      totalDurationInSeconds = (workDuration + breakDuration) * 60;
      isTimerRunning = true;
      _animationController.duration = Duration(seconds: totalDurationInSeconds);
      _animationController.forward(from: 0.0);
    });

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (totalDurationInSeconds > 0) {
        setState(() {
          totalDurationInSeconds--;
          _updateTimerMode();
        });
      } else {
        _countdownTimer?.cancel();
        setState(() {
          isTimerRunning = false;
        });
      }
    });
  }

  void _pauseTimer() {
    _countdownTimer?.cancel();
    _animationController.stop();
    setState(() {
      isTimerRunning = false;
    });
  }

  void _initializeShakeDetection() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if ((event.x.abs() > 15 || event.y.abs() > 15 || event.z.abs() > 10) &&
          isTimerRunning) {
        _pauseTimer();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
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
          Text(
            isWorkMode ? "工作時間" : "休息時間",
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
          Text(
            "${(totalDurationInSeconds ~/ 60).toString().padLeft(
                2, '0')}:${(totalDurationInSeconds % 60).toString().padLeft(
                2, '0')}",
            style: TextStyle(
                fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: CustomPaint(
                painter: ClockPainter(
                    isTimerRunning
                        ? 1 - (totalDurationInSeconds /
                        ((workDuration + breakDuration) * 60))
                        : 0,
                    workDuration,
                    breakDuration
                ),
                size: Size(300, 300),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Text("工作時間：$workDuration 分鐘",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                Slider(
                  value: workDuration.toDouble(),
                  min: 5,
                  max: 25,
                  divisions: 4,
                  label: "$workDuration min",
                  onChanged: (value) {
                    setState(() {
                      workDuration = value.toInt();
                      totalDurationInSeconds =
                          (workDuration + breakDuration) * 60;
                      _animationController.duration =
                          Duration(seconds: totalDurationInSeconds);
                      _animationController.value = 0.0;
                    });
                  },
                ),
                Text("休息時間：$breakDuration 分鐘",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                Slider(
                  value: breakDuration.toDouble(),
                  min: 3,
                  max: 10,
                  divisions: 7,
                  label: "$breakDuration min",
                  onChanged: (value) {
                    setState(() {
                      breakDuration = value.toInt();
                      totalDurationInSeconds =
                          (workDuration + breakDuration) * 60;
                      _animationController.duration =
                          Duration(seconds: totalDurationInSeconds);
                      _animationController.value = 0.0;
                    });
                  },
                )
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: isTimerRunning ? _pauseTimer : _startTimer,
                child: Text(isTimerRunning ? "暫停" : "開始"),
              ),
              IconButton(
                onPressed: TaskShow,
                icon: Icon(Icons.library_books, color: Colors.white),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.analytics, color: Colors.white),
              ),
            ],
          )
        ],
      ),
    );
  }

  void TaskShow() async {
    List<Map<String, dynamic>> tasks = await TaskStorage.loadTasks(); // 先載入任務
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 設置為透明以便自定義圓角
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              // 稍微增加初始高度
              minChildSize: 0.1,
              maxChildSize: 1.0,
              expand: true,
              // 設為true以確保能填滿整個螢幕
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      // 拖動指示器
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      // 標題 + 新增按鈕
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Text(
                              '任務清單',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Spacer(),
                            TextButton(
                              onPressed: () {
                                _showAddTaskDialog(
                                    context, setState); // 傳遞 setState 來更新清單
                              },
                              child: Text("新增任務"),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      // 保持 ListView 存在，避免影響拖動
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: tasks.isEmpty ? 1 : tasks.length,
                          // 確保至少有一個元素
                          itemBuilder: (context, index) {
                            if (tasks.isEmpty) {
                              return Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    "目前沒有任務，請新增！",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            final task = tasks[index];
                            return ListTile(
                              title: Text("工作 ${task["workMinutes"]} 分鐘"),
                              subtitle: Text(
                                  "休息 ${task["restMinutes"]} 分鐘"),
                              trailing: IconButton(
                                icon: Icon(
                                    Icons.delete_outline, color: Colors.red),
                                onPressed: () async {
                                  await TaskStorage.deleteTask(index);
                                  setState(() {
                                    tasks.removeAt(index);
                                  });
                                },
                              ),
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

  void _showAddTaskDialog(BuildContext context, StateSetter refreshTaskList) {
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
                    refreshTaskList(() {}); // 更新清單，不影響拖曳
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

  void _updateTimerMode() {
    int workTimeInSeconds = workDuration * 60;
    int elapsedSeconds = ((workDuration + breakDuration) * 60) -
        totalDurationInSeconds;

    setState(() {
      isWorkMode = elapsedSeconds < workTimeInSeconds;
    });
  }
}