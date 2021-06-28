import 'package:flutter_stateless_chessboard/flutter_stateless_chessboard.dart' as cb;
import 'package:millenniumdriver/MillenniumCommunicationClient.dart';
import 'package:flutter/material.dart';
import 'package:millenniumdriver/MillenniumBoard.dart';
import 'package:flutter_blue/flutter_blue.dart';

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
  }

  void getVersion() async {
    String _version = await connectedBoard.getVersion();
    setState(() {
      version = _version;
    });
  }

  void disconnect() async {
    _port.disconnect();
    setState(() {
      connectedBoard = null;
    });
  }

  Map<String, String> oldBoard;
  bool lightChangeSquareBlock = false;
  void lightChangeSquare(Map<String, String> board) async {
    if (lightChangeSquareBlock) {
      oldBoard = board;
      return;
    }
    lightChangeSquareBlock = true;
    List<String> squares = [];
    if (oldBoard != null) {
      for (String sq in board.keys) {
        if (board[sq] != oldBoard[sq]) squares.add(sq);
      }
    }
    oldBoard = board;
    if (squares.length > 0) {
      await connectedBoard.toggleLeds(squares);
    }
    Future.delayed(Duration(seconds: 1), () => (lightChangeSquareBlock = false));
  }

  String boardToFen(Map<String, String> board) {
    String res = "";
    List<String> values = board.values.toList().reversed.toList();
    for (var i = 0; i < 8; i++) {
      int free = 0;
      for (var j = 0; j < 8; j++) {
        String piece = values[i * 8 + j];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("millenniumdriver example"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: scanning ? CircularProgressIndicator() : TextButton(
            child: Text(connectedBoard == null ? "List Devices" : "Connected"),
            onPressed: connectedBoard == null ? listDevices : null,
          )),
          (
            connectedBoard == null ? Flexible( child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(devices[index].device.name),
                subtitle: Text(devices[index].device.id.id),
                onTap: () => connect(devices[index].device),
              )
            )) : Center( child: StreamBuilder(
            stream: connectedBoard?.getBoardUpdateStream(),
              builder: (context, AsyncSnapshot<Map<String, String>> snapshot) {
                if (!snapshot.hasData) return Text("-");

                lightChangeSquare(snapshot.data);
                String fen = boardToFen(snapshot.data);

                return cb.Chessboard(
                  size: 300,
                  fen: fen,
                  orientation: cb.Color.BLACK,  // optional
                  lightSquareColor: Color.fromRGBO(240, 217, 181, 1), // optional
                  darkSquareColor: Color.fromRGBO(181, 136, 99, 1), // optional
                );
              }
            ))
          ),
          TextButton(
            onPressed: getVersion,
            child: Text("Get Version (" + (version ?? "_") + ")")
          ),
          TextButton(
            onPressed: () => connectedBoard.extinguishAllLeds(),
            child: Text("Turn on LED's")
          ),
          TextButton(
            onPressed: disconnect,
            child: Text("Disconnect")
          ),
          SizedBox(height: 24)
        ],
      ),
    );
  }
}
