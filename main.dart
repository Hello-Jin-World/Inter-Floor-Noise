import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interfloor Noise',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('2층 층간소음 알림 시스템'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
          ],
        ),
        body: const MyHomePage(
          title: '',
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final List<String> _data = List.filled(4, 'Loading...');
  final List<Datum> _chartDataMic = [];
  final List<Datum> _chartDataMPU = [];
  final List<Datum> _chartDataMic2 = [];
  final List<Datum> _chartDataMPU2 = [];
  late StreamSubscription<DatabaseEvent> _chartDataSubscriptionMic;
  late StreamSubscription<DatabaseEvent> _chartDataSubscriptionMPU;

  @override
  void initState() {
    super.initState();
    _subscribeToFirebaseData();
  }

  void _subscribeToFirebaseData() {
    _databaseReference.child('MIC1').onValue.listen((event) {
      setState(() {
        _data[0] = '실시간 거실 소음 : ${event.snapshot.value.toString()}';
      });
    });

    _databaseReference.child('MPU1').onValue.listen((event) {
      setState(() {
        _data[1] = '실시간 거실 진동 : ${event.snapshot.value.toString()}';
      });
    });

    _databaseReference.child('MIC2').onValue.listen((event) {
      setState(() {
        _data[2] = '실시간 안방 소음 : ${event.snapshot.value.toString()}';
      });
    });

    _databaseReference.child('MPU2').onValue.listen((event) {
      setState(() {
        _data[3] = '실시간 안방 진동 : ${event.snapshot.value.toString()}';
      });
    });
  }

  @override
  void dispose() {
    _chartDataSubscriptionMic.cancel();
    _chartDataSubscriptionMPU.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white, // 텍스트 기본 색상 설정
                ),
                children: [
                  TextSpan(
                    text: '파란색',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.blue
                          : Colors
                              .blue.shade300, // 라이트 모드에서는 원래 색상, 다크 모드에서는 밝은 색상
                    ),
                  ),
                  const TextSpan(text: ' 일상적인 소음발생\n'),
                  TextSpan(
                    text: '주황색',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.orange
                          : Colors.orange.shade300,
                    ),
                  ),
                  const TextSpan(text: ' 층간소음 발생주의\n'),
                  TextSpan(
                    text: '빨간색',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.red
                          : Colors.red.shade300,
                    ),
                  ),
                  const TextSpan(text: ' 층간소음 발생경고'),
                ],
              ),
            ),
            for (int i = 0; i < _data.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: getColorForValue(
                        int.parse(_data[i].split(':')[1].trim()), i),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _data[i],
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChartScreen(
                      initialChartDataMic: _chartDataMic,
                      initialChartDataMPU: _chartDataMPU,
                    ),
                  ),
                );
              },
              child: const Text('거실 실시간 그래프'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChartScreen2(
                      initialChartDataMic2: _chartDataMic2,
                      initialChartDataMPU2: _chartDataMPU2,
                    ),
                  ),
                );
              },
              child: const Text('안방 실시간 그래프'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalendarScreen(),
                  ),
                );
              },
              child: const Text('캘린더'),
            ),
          ],
        ),
      ),
    );
  }

  Color getColorForValue(int value, int index) {
    // 실시간 진동1, 실시간 진동2
    if (index == 1 || index == 3) {
      if (value <= 200) {
        return Colors.blue;
      } else if (value <= 300) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    }
    // 실시간 마이크1, 실시간 마이크2
    else {
      if (value <= 25000) {
        return Colors.blue;
      } else if (value <= 35000) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    }
  }
}

class ChartScreen extends StatefulWidget {
  final List<Datum> initialChartDataMic;
  final List<Datum> initialChartDataMPU;

  const ChartScreen({
    super.key,
    required this.initialChartDataMic,
    required this.initialChartDataMPU,
  });

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late StreamSubscription<DatabaseEvent> _subscriptionMic;
  late StreamSubscription<DatabaseEvent> _subscriptionMPU;
  final DatabaseReference _databaseReferenceAVG =
      FirebaseDatabase.instance.ref('AVG');
  List<Datum> _chartDataMic = [];
  List<Datum> _chartDataMPU = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _subscribeToFirebaseData();
  }

  Future<void> _fetchInitialData() async {
    final now = DateTime.now();
    final tenMinutesAgo = now.subtract(const Duration(minutes: 10));

    final micSnapshot = await _databaseReferenceAVG
        .child('MIC1')
        .orderByKey()
        .startAt(DateFormat('HH:mm').format(tenMinutesAgo))
        .endAt(DateFormat('HH:mm').format(now))
        .once();
    final mpuSnapshot = await _databaseReferenceAVG
        .child('MPU1')
        .orderByKey()
        .startAt(DateFormat('HH:mm').format(tenMinutesAgo))
        .endAt(DateFormat('HH:mm').format(now))
        .once();

    setState(() {
      _chartDataMic = micSnapshot.snapshot.children.map((childSnapshot) {
        final timestamp = DateFormat('HH:mm').parse(childSnapshot.key!);
        final value = childSnapshot.value as int;
        return Datum(timestamp, value);
      }).toList();

      _chartDataMPU = mpuSnapshot.snapshot.children.map((childSnapshot) {
        final timestamp = DateFormat('HH:mm').parse(childSnapshot.key!);
        final value = childSnapshot.value as int;
        return Datum(timestamp, value);
      }).toList();

      _chartDataMic.sort((a, b) => a.time.compareTo(b.time));
      _chartDataMPU.sort((a, b) => a.time.compareTo(b.time));
    });
  }

  void _subscribeToFirebaseData() {
    _subscriptionMic = _databaseReferenceAVG
        .child('MIC1')
        .onChildAdded
        .listen((DatabaseEvent event) {
      final timestamp = DateFormat('HH:mm').parse(event.snapshot.key!);
      final value = event.snapshot.value as int;

      setState(() {
        _chartDataMic.add(Datum(timestamp, value));
        _chartDataMic.sort((a, b) => a.time.compareTo(b.time));
      });
    });

    _subscriptionMPU = _databaseReferenceAVG
        .child('MPU1')
        .onChildAdded
        .listen((DatabaseEvent event) {
      final timestamp = DateFormat('HH:mm').parse(event.snapshot.key!);
      final value = event.snapshot.value as int;

      setState(() {
        _chartDataMPU.add(Datum(timestamp, value));
        _chartDataMPU.sort((a, b) => a.time.compareTo(b.time));
      });
    });
  }

  @override
  void dispose() {
    _subscriptionMic.cancel();
    _subscriptionMPU.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('거실 실시간 그래프'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 300,
              child: _chartDataMic.isNotEmpty
                  ? charts.TimeSeriesChart(
                      [
                        charts.Series<Datum, DateTime>(
                          id: 'Data MIC1',
                          domainFn: (datum, _) =>
                              datum.time, // x 축에 timestamp 사용
                          measureFn: (datum, _) => datum.y,
                          data: _chartDataMic,
                        )
                      ],
                      defaultRenderer: charts.LineRendererConfig(
                        includeLine: true,
                        includePoints: true,
                      ),
                      behaviors: [
                        charts.ChartTitle(
                          '소음 평균 값',
                          behaviorPosition: charts.BehaviorPosition.top,
                          titleOutsideJustification:
                              charts.OutsideJustification.middleDrawArea,
                          titleStyleSpec: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ],
                      domainAxis: charts.DateTimeAxisSpec(
                        tickFormatterSpec:
                            const charts.AutoDateTimeTickFormatterSpec(
                          day: charts.TimeFormatterSpec(
                            format: 'HH:mm', // 시간 형식 지정 (시:분)
                            transitionFormat: 'HH:mm', // 변경되는 부분에 대한 형식
                          ),
                        ),
                        // x 축의 범위를 데이터의 시작부터 끝까지로 설정하여 전체 데이터가 그래프에 표시되도록 함
                        viewport: charts.DateTimeExtents(
                          start: _chartDataMic.first.time,
                          end: _chartDataMic.last.time,
                        ),
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ),
                      primaryMeasureAxis: charts.NumericAxisSpec(
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
                children: [
                  const TextSpan(
                    text: '소음의 최대값',
                  ),
                  TextSpan(
                    text:
                        '${_chartDataMic.isEmpty ? 0 : _chartDataMic.reduce((curr, next) => curr.y > next.y ? curr : next).y}',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.red
                          : Colors.red.shade300,
                    ),
                  ),
                  const TextSpan(
                    text: '이(가) ',
                  ),
                  TextSpan(
                    text:
                        '${_chartDataMic.isEmpty ? '00:00' : _chartDataMic.firstWhere((datum) => datum.y == _chartDataMic.reduce((curr, next) => curr.y > next.y ? curr : next).y).time.hour.toString().padLeft(2, '0')}:${_chartDataMic.isEmpty ? '00' : _chartDataMic.firstWhere((datum) => datum.y == _chartDataMic.reduce((curr, next) => curr.y > next.y ? curr : next).y).time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.blue
                          : Colors.blue.shade300,
                    ),
                  ),
                  const TextSpan(
                    text: '에 측정되었습니다.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _chartDataMPU.isNotEmpty
                  ? charts.TimeSeriesChart(
                      [
                        charts.Series<Datum, DateTime>(
                          id: 'Data MPU1',
                          domainFn: (datum, _) =>
                              datum.time, // x 축에 timestamp 사용
                          measureFn: (datum, _) => datum.y,
                          data: _chartDataMPU,
                        )
                      ],
                      defaultRenderer: charts.LineRendererConfig(
                        includeLine: true,
                        includePoints: true,
                      ),
                      behaviors: [
                        charts.ChartTitle(
                          '진동 평균 값',
                          behaviorPosition: charts.BehaviorPosition.top,
                          titleOutsideJustification:
                              charts.OutsideJustification.middleDrawArea,
                          titleStyleSpec: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ],
                      domainAxis: charts.DateTimeAxisSpec(
                        tickFormatterSpec:
                            const charts.AutoDateTimeTickFormatterSpec(
                          day: charts.TimeFormatterSpec(
                            format: 'HH:mm', // 시간 형식 지정 (시:분)
                            transitionFormat: 'HH:mm', // 변경되는 부분에 대한 형식
                          ),
                        ),
                        // x 축의 범위를 데이터의 시작부터 끝까지로 설정하여 전체 데이터가 그래프에 표시되도록 함
                        viewport: charts.DateTimeExtents(
                          start: _chartDataMPU.first.time,
                          end: _chartDataMPU.last.time,
                        ),
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ),
                      primaryMeasureAxis: charts.NumericAxisSpec(
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
                children: [
                  const TextSpan(
                    text: '진동의 최대값',
                  ),
                  TextSpan(
                    text:
                        '${_chartDataMPU.isEmpty ? 0 : _chartDataMPU.reduce((curr, next) => curr.y > next.y ? curr : next).y}',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.red
                          : Colors.red.shade300,
                    ),
                  ),
                  const TextSpan(
                    text: '이(가) ',
                  ),
                  TextSpan(
                    text:
                        '${_chartDataMPU.isEmpty ? '00:00' : _chartDataMPU.firstWhere((datum) => datum.y == _chartDataMPU.reduce((curr, next) => curr.y > next.y ? curr : next).y).time.hour.toString().padLeft(2, '0')}:${_chartDataMPU.isEmpty ? '00' : _chartDataMPU.firstWhere((datum) => datum.y == _chartDataMPU.reduce((curr, next) => curr.y > next.y ? curr : next).y).time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.blue
                          : Colors.blue.shade300,
                    ),
                  ),
                  const TextSpan(
                    text: '에 측정되었습니다.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartScreen2 extends StatefulWidget {
  final List<Datum> initialChartDataMic2;
  final List<Datum> initialChartDataMPU2;

  const ChartScreen2({
    super.key,
    required this.initialChartDataMic2,
    required this.initialChartDataMPU2,
  });

  @override
  State<ChartScreen2> createState() => _ChartScreenState2();
}

class _ChartScreenState2 extends State<ChartScreen2> {
  late StreamSubscription<DatabaseEvent> _subscriptionMic2;
  late StreamSubscription<DatabaseEvent> _subscriptionMPU2;
  final DatabaseReference _databaseReferenceAVG2 =
      FirebaseDatabase.instance.ref('AVG');
  List<Datum> _chartDataMic2 = [];
  List<Datum> _chartDataMPU2 = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _subscribeToFirebaseData();
  }

  Future<void> _fetchInitialData() async {
    final now = DateTime.now();
    final tenMinutesAgo = now.subtract(const Duration(minutes: 10));

    final micSnapshot2 = await _databaseReferenceAVG2
        .child('MIC2')
        .orderByKey()
        .startAt(DateFormat('HH:mm').format(tenMinutesAgo))
        .endAt(DateFormat('HH:mm').format(now))
        .once();
    final mpuSnapshot2 = await _databaseReferenceAVG2
        .child('MPU2')
        .orderByKey()
        .startAt(DateFormat('HH:mm').format(tenMinutesAgo))
        .endAt(DateFormat('HH:mm').format(now))
        .once();

    setState(() {
      _chartDataMic2 = micSnapshot2.snapshot.children.map((childSnapshot2) {
        final timestamp = DateFormat('HH:mm').parse(childSnapshot2.key!);
        final value = childSnapshot2.value as int;
        return Datum(timestamp, value);
      }).toList();

      _chartDataMPU2 = mpuSnapshot2.snapshot.children.map((childSnapshot2) {
        final timestamp = DateFormat('HH:mm').parse(childSnapshot2.key!);
        final value = childSnapshot2.value as int;
        return Datum(timestamp, value);
      }).toList();

      _chartDataMic2.sort((a, b) => a.time.compareTo(b.time));
      _chartDataMPU2.sort((a, b) => a.time.compareTo(b.time));
    });
  }

  void _subscribeToFirebaseData() {
    _subscriptionMic2 = _databaseReferenceAVG2
        .child('MIC2')
        .onChildAdded
        .listen((DatabaseEvent event) {
      final timestamp = DateFormat('HH:mm').parse(event.snapshot.key!);
      final value = event.snapshot.value as int;

      setState(() {
        _chartDataMic2.add(Datum(timestamp, value));
        _chartDataMic2.sort((a, b) => a.time.compareTo(b.time));
      });
    });

    _subscriptionMPU2 = _databaseReferenceAVG2
        .child('MPU2')
        .onChildAdded
        .listen((DatabaseEvent event) {
      final timestamp = DateFormat('HH:mm').parse(event.snapshot.key!);
      final value = event.snapshot.value as int;

      setState(() {
        _chartDataMPU2.add(Datum(timestamp, value));
        _chartDataMPU2.sort((a, b) => a.time.compareTo(b.time));
      });
    });
  }

  @override
  void dispose() {
    _subscriptionMic2.cancel();
    _subscriptionMPU2.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('안방 실시간 그래프'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 300,
              child: _chartDataMic2.isNotEmpty
                  ? charts.TimeSeriesChart(
                      [
                        charts.Series<Datum, DateTime>(
                          id: 'Data MIC2',
                          domainFn: (datum, _) =>
                              datum.time, // x 축에 timestamp 사용
                          measureFn: (datum, _) => datum.y,
                          data: _chartDataMic2,
                        )
                      ],
                      defaultRenderer: charts.LineRendererConfig(
                        includeLine: true,
                        includePoints: true,
                      ),
                      behaviors: [
                        charts.ChartTitle(
                          '소음 평균 값',
                          behaviorPosition: charts.BehaviorPosition.top,
                          titleOutsideJustification:
                              charts.OutsideJustification.middleDrawArea,
                          titleStyleSpec: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ],
                      domainAxis: charts.DateTimeAxisSpec(
                        tickFormatterSpec:
                            const charts.AutoDateTimeTickFormatterSpec(
                          day: charts.TimeFormatterSpec(
                            format: 'HH:mm', // 시간 형식 지정 (시:분)
                            transitionFormat: 'HH:mm', // 변경되는 부분에 대한 형식
                          ),
                        ),
                        // x 축의 범위를 데이터의 시작부터 끝까지로 설정하여 전체 데이터가 그래프에 표시되도록 함
                        viewport: charts.DateTimeExtents(
                          start: _chartDataMic2.first.time,
                          end: _chartDataMic2.last.time,
                        ),
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ),
                      primaryMeasureAxis: charts.NumericAxisSpec(
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
                children: [
                  const TextSpan(
                    text: '소음의 최대값',
                  ),
                  TextSpan(
                    text:
                        '${_chartDataMic2.isEmpty ? 0 : _chartDataMic2.reduce((curr, next) => curr.y > next.y ? curr : next).y}',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.red
                          : Colors.red.shade300,
                    ),
                  ),
                  const TextSpan(
                    text: '이(가) ',
                  ),
                  TextSpan(
                    text:
                        '${_chartDataMic2.isEmpty ? '00:00' : _chartDataMic2.firstWhere((datum) => datum.y == _chartDataMic2.reduce((curr, next) => curr.y > next.y ? curr : next).y).time.hour.toString().padLeft(2, '0')}:${_chartDataMic2.isEmpty ? '00' : _chartDataMic2.firstWhere((datum) => datum.y == _chartDataMic2.reduce((curr, next) => curr.y > next.y ? curr : next).y).time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.blue
                          : Colors.blue.shade300,
                    ),
                  ),
                  const TextSpan(
                    text: '에 측정되었습니다.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _chartDataMPU2.isNotEmpty
                  ? charts.TimeSeriesChart(
                      [
                        charts.Series<Datum, DateTime>(
                          id: 'Data MPU2',
                          domainFn: (datum, _) =>
                              datum.time, // x 축에 timestamp 사용
                          measureFn: (datum, _) => datum.y,
                          data: _chartDataMPU2,
                        )
                      ],
                      defaultRenderer: charts.LineRendererConfig(
                        includeLine: true,
                        includePoints: true,
                      ),
                      behaviors: [
                        charts.ChartTitle(
                          '진동 평균 값',
                          behaviorPosition: charts.BehaviorPosition.top,
                          titleOutsideJustification:
                              charts.OutsideJustification.middleDrawArea,
                          titleStyleSpec: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ],
                      domainAxis: charts.DateTimeAxisSpec(
                        tickFormatterSpec:
                            const charts.AutoDateTimeTickFormatterSpec(
                          day: charts.TimeFormatterSpec(
                            format: 'HH:mm', // 시간 형식 지정 (시:분)
                            transitionFormat: 'HH:mm', // 변경되는 부분에 대한 형식
                          ),
                        ),
                        // x 축의 범위를 데이터의 시작부터 끝까지로 설정하여 전체 데이터가 그래프에 표시되도록 함
                        viewport: charts.DateTimeExtents(
                          start: _chartDataMPU2.first.time,
                          end: _chartDataMPU2.last.time,
                        ),
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ),
                      primaryMeasureAxis: charts.NumericAxisSpec(
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
                children: [
                  const TextSpan(
                    text: '진동의 최대값',
                  ),
                  TextSpan(
                    text:
                        '${_chartDataMPU2.isEmpty ? 0 : _chartDataMPU2.reduce((curr, next) => curr.y > next.y ? curr : next).y}',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.red
                          : Colors.red.shade300,
                    ),
                  ),
                  const TextSpan(
                    text: '이(가) ',
                  ),
                  TextSpan(
                    text:
                        '${_chartDataMPU2.isEmpty ? '00:00' : _chartDataMPU2.firstWhere((datum) => datum.y == _chartDataMPU2.reduce((curr, next) => curr.y > next.y ? curr : next).y).time.hour.toString().padLeft(2, '0')}:${_chartDataMPU2.isEmpty ? '00' : _chartDataMPU2.firstWhere((datum) => datum.y == _chartDataMPU2.reduce((curr, next) => curr.y > next.y ? curr : next).y).time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.blue
                          : Colors.blue.shade300,
                    ),
                  ),
                  const TextSpan(
                    text: '에 측정되었습니다.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryChartScreen extends StatefulWidget {
  final DateTime selectedDate;

  const HistoryChartScreen({super.key, required this.selectedDate});

  @override
  State<HistoryChartScreen> createState() => _HistoryChartScreenState();
}

class _HistoryChartScreenState extends State<HistoryChartScreen> {
  late DateTime _selectedDate;
  final DatabaseReference _databaseReferenceMic1 =
      FirebaseDatabase.instance.ref('history/mic1');
  final DatabaseReference _databaseReferenceMpu1 =
      FirebaseDatabase.instance.ref('history/vib1');
  final DatabaseReference _databaseReferenceMic2 =
      FirebaseDatabase.instance.ref('history/mic2');
  final DatabaseReference _databaseReferenceMpu2 =
      FirebaseDatabase.instance.ref('history/vib2');
  final List<String> _historyDataMic1 = [];
  final List<String> _historyDataMpu1 = [];
  final List<String> _historyDataMic2 = [];
  final List<String> _historyDataMpu2 = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    await _fetchDataForPath(
        _databaseReferenceMic1, selectedDateStr, _historyDataMic1);
    await _fetchDataForPath(
        _databaseReferenceMpu1, selectedDateStr, _historyDataMpu1);
    await _fetchDataForPath(
        _databaseReferenceMic2, selectedDateStr, _historyDataMic2);
    await _fetchDataForPath(
        _databaseReferenceMpu2, selectedDateStr, _historyDataMpu2);
    setState(() {});
  }

  Future<void> _fetchDataForPath(
      DatabaseReference reference, String date, List<String> dataList) async {
    final snapshot = await reference.child(date).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      dataList.addAll(data.entries
          .map((entry) => '${entry.key} // ${entry.value}')
          .toList());
      dataList.sort((a, b) => a.compareTo(b));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${DateFormat('yyyy년 MM월 dd일').format(_selectedDate)} 시간대 별 기록'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              children: [
                if (_historyDataMic1.isNotEmpty)
                  _buildListView('   거실 소음', _historyDataMic1),
                if (_historyDataMpu1.isNotEmpty)
                  _buildListView('   거실 진동', _historyDataMpu1),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (_historyDataMic2.isNotEmpty)
                  _buildListView('   안방 소음', _historyDataMic2),
                if (_historyDataMpu2.isNotEmpty)
                  _buildListView('   안방 진동', _historyDataMpu2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(String title, List<String> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(1.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ...data.map((data) => ListTile(
              dense: true, // 이 줄을 추가하였습니다.
              title: Text(data),
            )),
      ],
    );
  }
}

class YesterdayBarChartScreen extends StatefulWidget {
  final DateTime selectedDate;

  const YesterdayBarChartScreen({super.key, required this.selectedDate});

  @override
  State<YesterdayBarChartScreen> createState() =>
      _YesterdayBarChartScreenState();
}

class _YesterdayBarChartScreenState extends State<YesterdayBarChartScreen> {
  late DateTime _selectedDate;
  List<charts.Series<BarChartDatum, String>> barChartDataNoise = [];
  List<charts.Series<BarChartDatum, String>> barChartDataVibration = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final historyDataMic1 =
        await _fetchDataForPath('history/mic1/$selectedDateStr');
    final historyDataMic2 =
        await _fetchDataForPath('history/mic2/$selectedDateStr');
    final historyDataVib1 =
        await _fetchDataForPath('history/vib1/$selectedDateStr');
    final historyDataVib2 =
        await _fetchDataForPath('history/vib2/$selectedDateStr');

    Map<int, List<Datum>> noiseDataByHour = {};
    Map<int, List<Datum>> vibrationDataByHour = {};

    for (var datum in [...historyDataMic1, ...historyDataMic2]) {
      int hour = datum.timestamp.hour;
      noiseDataByHour.putIfAbsent(hour, () => []);
      noiseDataByHour[hour]!.add(datum);
    }

    for (var datum in [...historyDataVib1, ...historyDataVib2]) {
      int hour = datum.timestamp.hour;
      vibrationDataByHour.putIfAbsent(hour, () => []);
      vibrationDataByHour[hour]!.add(datum);
    }

    List<BarChartDatum> barChartDataListNoise = [];
    for (var entry in noiseDataByHour.entries) {
      barChartDataListNoise
          .add(BarChartDatum(entry.key.toString(), entry.value.length));
    }

    List<BarChartDatum> barChartDataListVibration = [];
    for (var entry in vibrationDataByHour.entries) {
      barChartDataListVibration
          .add(BarChartDatum(entry.key.toString(), entry.value.length));
    }

    setState(() {
      barChartDataNoise = [
        charts.Series<BarChartDatum, String>(
          id: 'Noise Data',
          domainFn: (BarChartDatum datum, _) => '${datum.hour}시',
          measureFn: (BarChartDatum datum, _) => datum.count,
          data: barChartDataListNoise
            ..sort((a, b) => int.parse(a.hour).compareTo(int.parse(b.hour))),
        ),
      ];

      barChartDataVibration = [
        charts.Series<BarChartDatum, String>(
          id: 'Vibration Data',
          domainFn: (BarChartDatum datum, _) => '${datum.hour}시',
          measureFn: (BarChartDatum datum, _) => datum.count,
          data: barChartDataListVibration
            ..sort((a, b) => int.parse(a.hour).compareTo(int.parse(b.hour))),
        ),
      ];
    });
  }

  Future<List<Datum>> _fetchDataForPath(String path) async {
    final historyDataRef = FirebaseDatabase.instance.ref(path);
    final snapshot = await historyDataRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.entries.map((entry) {
        final timestamp = DateFormat('HH:mm:ss').parse('${entry.key}:00');
        final value = entry.value as int;
        return Datum(timestamp, value);
      }).toList();
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${DateFormat('yyyy년 MM월 dd일').format(_selectedDate)} 시간대별 층간소음'),
      ),
      body: Column(
        children: [
          Expanded(
            child: barChartDataNoise.isNotEmpty
                ? SizedBox(
                    height: 300,
                    child: charts.BarChart(
                      barChartDataNoise,
                      animate: true,
                      behaviors: [
                        charts.ChartTitle(
                          '소음 횟수',
                          behaviorPosition: charts.BehaviorPosition.top,
                          titleOutsideJustification:
                              charts.OutsideJustification.middleDrawArea,
                          titleStyleSpec: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ],
                      domainAxis: charts.OrdinalAxisSpec(
                        renderSpec: charts.SmallTickRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ),
                      primaryMeasureAxis: charts.NumericAxisSpec(
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: barChartDataVibration.isNotEmpty
                ? SizedBox(
                    height: 300,
                    child: charts.BarChart(
                      barChartDataVibration,
                      animate: true,
                      behaviors: [
                        charts.ChartTitle(
                          '진동 횟수',
                          behaviorPosition: charts.BehaviorPosition.top,
                          titleOutsideJustification:
                              charts.OutsideJustification.middleDrawArea,
                          titleStyleSpec: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ],
                      domainAxis: charts.OrdinalAxisSpec(
                        renderSpec: charts.SmallTickRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ),
                      primaryMeasureAxis: charts.NumericAxisSpec(
                        renderSpec: charts.GridlineRendererSpec(
                          labelStyle: charts.TextStyleSpec(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? charts.MaterialPalette.black
                                    : charts.MaterialPalette.white,
                          ),
                        ),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HistoryChartScreen(selectedDate: _selectedDate),
                      ),
                    );
                  },
                  child: const Text('상세 보기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BarChartDatum {
  final String hour;
  final int count;
  BarChartDatum(this.hour, this.count);
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2024),
            lastDay: DateTime.now(),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: _onDaySelected,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      YesterdayBarChartScreen(selectedDate: _selectedDate),
                ),
              );
            },
            child: const Text('선택한 날짜 보기'),
          ),
        ],
      ),
    );
  }
}

class Datum {
  final DateTime timestamp;
  final int y;

  // Define getter x to return timestamp in milliseconds
  int get x => timestamp.millisecondsSinceEpoch;

  // Define getter x to return timestamp as DateTime
  DateTime get time => timestamp;

  Datum(this.timestamp, this.y);
}
