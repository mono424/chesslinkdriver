import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_stateless_chessboard/flutter_stateless_chessboard.dart' as cb;
import 'package:chesslinkdriver/ChessLinkCommunicationClient.dart';
import 'package:flutter/material.dart';
import 'package:chesslinkdriver/ChessLink.dart';
import 'package:chesslinkdriver/protocol/model/LEDPattern.dart';
import 'package:chesslinkdriver/protocol/model/StatusReportSendInterval.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ChessLink connectedBoard;

  Uuid _serviceId = Uuid.parse("49535343-FE7D-4AE5-8FA9-9FAFD205E455");
  Uuid _characteristicReadId = Uuid.parse("49535343-1e4d-4bd9-ba61-23c647249616");
  Uuid _characteristicWriteId = Uuid.parse("49535343-8841-43f4-a8d4-ecbe34729bb3");
  Duration scanDuration = Duration(seconds: 4);
  List<DiscoveredDevice> devices = [];
  bool scanning = false;
  
  final flutterReactiveBle = FlutterReactiveBle();
  Timer updateSquareLedTimer;
  StreamSubscription<ConnectionStateUpdate> connection;
  String version;

  Future<void> reqPermission() async {
    await Permission.locationWhenInUse.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
  }

  Future<void> listDevices() async {
    setState(() { scanning = true; devices = []; });

    await reqPermission();

    // Listen to scan results
    final sub = flutterReactiveBle.scanForDevices(withServices: [], scanMode: ScanMode.balanced).listen((device) {
      if (!device.name.contains("MILLENNIUM") || devices.indexWhere((e) => e.id == device.id) > -1) return;
      setState(() {
        devices.add(device);
      });
    }, onError: (e) {
      print(e);
    });

    // Stop scanning
    Future.delayed(scanDuration, () {
      sub.cancel();
      setState(() { scanning = false; });
    });
  }

  void connect(DiscoveredDevice device) async {
    connection = flutterReactiveBle.connectToDevice(
      id: device.id,
      servicesWithCharacteristicsToDiscover: {_serviceId: [_serviceId]},
      connectionTimeout: const Duration(seconds: 2),
    ).listen((connectionState) async {
      final read = QualifiedCharacteristic(serviceId: _serviceId, characteristicId: _characteristicReadId, deviceId: device.id);
      final write = QualifiedCharacteristic(serviceId: _serviceId, characteristicId: _characteristicWriteId, deviceId: device.id);

      ChessLinkCommunicationClient client = ChessLinkCommunicationClient((v) => flutterReactiveBle.writeCharacteristicWithoutResponse(write, value: v));
      flutterReactiveBle.subscribeToCharacteristic(read).listen(client.handleReceive);
      
      ChessLink nBoard = new ChessLink();
      await nBoard.init(client, initialDelay: Duration(seconds: 1));

      setState(() {
        connectedBoard = nBoard;
      });

      updateSquareLedTimer = Timer.periodic(Duration(milliseconds: 200), (t) => lightChangeSquare());
    }, onError: (Object e) {
      print(e);
    });
  }

  void getVersion() async {
    String _version = await connectedBoard.getVersion();
    setState(() {
      version = _version;
    });
  }

  void setLedPatternB1ToC3() async {
    LEDPattern ledPattern = LEDPattern();
    ledPattern.set("B1", LEDPattern.generateSquarePattern(true, true, true, true, false, false, false, false));
    ledPattern.set("C3", LEDPattern.generateSquarePattern(false, false, false, false, true, true, true, true));
    connectedBoard.setLeds(ledPattern, slotTime: Duration(milliseconds: 100));
  }

  void disconnect() async {
    if (updateSquareLedTimer != null) {
      updateSquareLedTimer.cancel();
      updateSquareLedTimer = null;
    }
    connection.cancel();
    setState(() {
      connectedBoard = null;
    });
  }

  Map<String, String> board;
  Map<String, String> oldBoard;
  void lightChangeSquare() async {
    if (board == null) {
      return;
    }
    List<String> squares = [];
    if (oldBoard != null) {
      for (String sq in board.keys) {
        bool hasPiece = board[sq] != null;
        bool isNew = board[sq] != oldBoard[sq];
        if (hasPiece && isNew) squares.add(sq);
      }
    }
    oldBoard = board;
    if (squares.length > 0) {
      await connectedBoard.turnOnLeds(squares);
    }
  }

  String boardToFen(Map<String, String> board) {
    String res = "";
    for (var i = 0; i < 8; i++) {
      int free = 0;
      for (var j = 0; j < 8; j++) {
        String square = ChessLink.RANKS.reversed.elementAt(j) + ChessLink.ROWS[i];
        String piece = board[square];
        if (piece == null) {
          free++;
        } else {
          if (free > 0) {
            res += free.toString();
            free = 0;
          }
          res += piece;
        }
      }
      if (free > 0) {
        res += free.toString();
      }
      res += "/";
    }
    return res.substring(0, res.length - 1) + ' w KQkq - 0 1';
  }

  Widget connectedBoardButtons() {
    return Column(
      children: [
        SizedBox(height: 25),
        Center(
          child: StreamBuilder(
            stream: connectedBoard?.getBoardUpdateStream(),
              builder: (context, AsyncSnapshot<Map<String, String>> snapshot) {
                if (!snapshot.hasData) return Text("-");

                board = snapshot.data;
                String fen = boardToFen(snapshot.data);

                return cb.Chessboard(
                  size: 300,
                  fen: fen,
                  orientation: cb.Color.BLACK,  // optional
                  lightSquareColor: Color.fromRGBO(240, 217, 181, 1), // optional
                  darkSquareColor: Color.fromRGBO(181, 136, 99, 1), // optional
                );
              }
          )
        ),
        TextButton(
          onPressed: getVersion,
          child: Text("Get Version (" + (version ?? "_") + ")")
        ),
        TextButton(
          onPressed: () => connectedBoard.turnOnAllLeds(),
          child: Text("Turn on LED's")
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: setLedPatternB1ToC3,
              child: Text("Turn on B1 -> C3")
            ),
            TextButton(
              onPressed: () => connectedBoard.turnOnSingleLed("A1"),
              child: Text("Turn on A1 LED")
            ),
          ],
        ),
        TextButton(
          onPressed: () => connectedBoard.extinguishAllLeds(),
          child: Text("Turn off LED's")
        ),
        TextButton(
          onPressed: () => connectedBoard.getStatus(),
          child: Text("Get Board")
        ),
        TextButton(
          onPressed: () => connectedBoard.reset(),
          child: Text("Reset")
        ),
        TextButton(
          onPressed: disconnect,
          child: Text("Disconnect")
        ),
      ],
    );
  }

  Widget additionalSettings() {
    return Column(
      children: [
        SizedBox(height: 25),
        Text("SetAutomaticReports"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => connectedBoard.setAutomaticReports(StatusReportSendInterval.disabled),
              child: Text("disabled")
            ),
            TextButton(
              onPressed: () => connectedBoard.setAutomaticReports(StatusReportSendInterval.onEveryScan),
              child: Text("onEveryScan")
            ),
            TextButton(
              onPressed: () => connectedBoard.setAutomaticReports(StatusReportSendInterval.onChange),
              child: Text("onChange")
            ),
            TextButton(
              onPressed: () => connectedBoard.setAutomaticReports(StatusReportSendInterval.withSetTime),
              child: Text("withSetTime")
            ),
          ],
        ),
        SizedBox(height: 25),
        Text("SetAutomaticReportsTime"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => connectedBoard.setAutomaticReportsTime(Duration(milliseconds: 200)),
              child: Text("200ms")
            ),
            TextButton(
              onPressed: () => connectedBoard.setAutomaticReportsTime(Duration(milliseconds: 500)),
              child: Text("500ms")
            ),
            TextButton(
              onPressed: () => connectedBoard.setAutomaticReportsTime(Duration(seconds: 1)),
              child: Text("1s")
            ),
          ],
        ),
        SizedBox(height: 25),
        Text("SetBrightness"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => connectedBoard.setLedBrightness(0),
              child: Text("dim(0)")
            ),
            TextButton(
              onPressed: () => connectedBoard.setLedBrightness(0.5),
              child: Text("middle(0.5)")
            ),
            TextButton(
              onPressed: () => connectedBoard.setLedBrightness(1),
              child: Text("full(1)")
            ),
          ],
        ),
        SizedBox(height: 25),
        Text("setScanTime"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => connectedBoard.setScanTime(Duration(milliseconds: 31)),
              child: Text("32 Scans/Sec")
            ),
            TextButton(
              onPressed: () => connectedBoard.setScanTime(Duration(milliseconds: 41)),
              child: Text("24.4 Scans/Sec")
            ),
            TextButton(
              onPressed: () => connectedBoard.setScanTime(Duration(milliseconds: 523)),
              child: Text("1.9 Scans/Sec")
            ),
          ],
        )
      ],
    );
  }

  Widget deivceList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 25),
        Center(child: scanning ? CircularProgressIndicator() : TextButton(
          child: Text("List Devices"),
          onPressed: listDevices,
        )),

        Flexible( child: ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(devices[index].name),
            subtitle: Text(devices[index].id.toString()),
            onTap: () => connect(devices[index]),
          )
        )),
        
        SizedBox(height: 24)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = connectedBoard == null 
      ? deivceList() : TabBarView(
        children: [
          connectedBoardButtons(),
          additionalSettings(),
        ],
      );
    Widget appBar = connectedBoard == null 
      ? AppBar(
        title: Text("chesslinkdriver example"),
      ) : AppBar(
          title: Text("chesslinkdriver example"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Additional"),
            ],
        ),
      );


    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: appBar,
        body: content
      )
    );
  }
}
