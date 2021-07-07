import 'dart:async';

import 'package:flutter_stateless_chessboard/flutter_stateless_chessboard.dart' as cb;
import 'package:millenniumdriver/MillenniumCommunicationClient.dart';
import 'package:flutter/material.dart';
import 'package:millenniumdriver/MillenniumBoard.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:millenniumdriver/protocol/model/LEDPattern.dart';
import 'package:millenniumdriver/protocol/model/StatusReportSendInterval.dart';

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
  MillenniumBoard connectedBoard;

  String _characteristicReadId = "49535343-1e4d-4bd9-ba61-23c647249616";
  String _characteristicWriteId = "49535343-8841-43f4-a8d4-ecbe34729bb3";
  Duration scanDuration = Duration(seconds: 4);
  List<ScanResult> devices = [];
  bool scanning = false;
  
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice _port;
  BluetoothCharacteristic _characteristicRead;
  BluetoothCharacteristic _characteristicWrite;
  Timer updateSquareLedTimer;


  String version;

  Future<void> listDevices() async {
    setState(() { scanning = true; });
    // Start scanning
    flutterBlue.startScan(timeout: scanDuration);

    // Listen to scan results
    flutterBlue.scanResults.listen((results) {
        // do something with scan results
        setState(() {
          devices = results.where((r) => r.device.name.contains("MILLENNIUM")).toList();
        });
    });

    Future.delayed(scanDuration, () => setState(() { scanning = false; }));
    // Stop scanning
    // flutterBlue.stopScan();
  }

  void connect(BluetoothDevice port) async {
    if (_port != port) {
      _port = port;
      await _port.connect();
    }
    
    List<BluetoothService> services = await _port.discoverServices();

    for (BluetoothService s in services) {
      for (BluetoothCharacteristic c in s.characteristics) {
        if (c.uuid.toString() == _characteristicReadId) _characteristicRead = c;
        if (c.uuid.toString() == _characteristicWriteId) _characteristicWrite = c;
        if (c.properties.write) print("Write avaiable on: " + c.uuid.toString());
        if (c.properties.read && c.properties.notify) print("Read/Noitify avaiable on: " + c.uuid.toString());
      }
    }

    await _characteristicRead.setNotifyValue(true);

    MillenniumCommunicationClient client = MillenniumCommunicationClient(_characteristicWrite.write);
    _characteristicRead.value.listen(client.handleReceive);
    
    // connect to board and initialize
    MillenniumBoard nBoard = new MillenniumBoard();
    await nBoard.init(client);
    // print("MillenniumBoard connected - SerialNumber: " +
    //     nBoard.getSerialNumber() +
    //     " Version: " +0
    //     nBoard.getVersion());

    // set connected board
    setState(() {
      connectedBoard = nBoard;
    });

    // // set board to update mode
    // nBoard.setBoardToUpdateMode();

    updateSquareLedTimer = Timer.periodic(Duration(milliseconds: 200), (t) => lightChangeSquare());
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
    _port.disconnect();
    _port = null;
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
        String square = MillenniumBoard.RANKS.reversed.elementAt(j) + MillenniumBoard.ROWS[i];
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
            title: Text(devices[index].device.name),
            subtitle: Text(devices[index].device.id.id),
            onTap: () => connect(devices[index].device),
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
        title: Text("millenniumdriver example"),
      ) : AppBar(
          title: Text("millenniumdriver example"),
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
