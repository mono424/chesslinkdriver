# millenniumdriver

The millenniumdriver flutter package allows you to quickly get you Millennium-board connected
to your Android application.

![preview](https://user-images.githubusercontent.com/17506411/114317384-1a680380-9b08-11eb-8484-b263743d43f6.gif)


## Getting Started with Millenniumdriver + usb_serial

Add dependencies to `pubspec.yaml`
```
dependencies:
	millenniumdriver: ^0.0.1
	usb_serial: ^0.2.4
```

include the package
```
import 'package:millenniumdriver/Millenniumdriver.dart';
import 'package:usb_serial/usb_serial.dart';
```

add compileOptions to `android\app\build.gradle`
```
android {
    ...
    compileOptions {
        sourceCompatibility 1.8
        targetCompatibility 1.8
    }
    ...
}
```
you can do optional more steps to allow usb related features,
for that please take a look at the package we depend on: 
[usb_serial](https://pub.dev/packages/usb_serial).


Connect to a connected board and listen to its events:
```dart
List<UsbDevice> devices = await UsbSerial.listDevices();
    List<UsbDevice> millenniumDevices = devices.where((d) => d.vid == 1115).toList();
    UsbPort usbDevice = await millenniumDevices[0].create();
    await usbDevice.open();

    MillenniumCommunicationClient client = MillenniumCommunicationClient(usbDevice.write);
    usbDevice.inputStream.listen(client.handleReceive);
    
    if (millenniumDevices.length > 0) {
      // connect to board and initialize
      MillenniumBoard nBoard = new MillenniumBoard();
      await nBoard.init(client);
      print("MillenniumBoard connected - SerialNumber: " +
          nBoard.getSerialNumber() +
          " Version: " +
          nBoard.getVersion());

      // set connected board
      setState(() {
        connectedBoard = nBoard;
      });

      // set board to update mode
      nBoard.setBoardToUpdateMode();
    }
```

## In action

To get a quick look, it is used in the follwoing project, which is not open source yet.

https://khad.im/p/white-pawn

## Updates soon

sorry for the lack of information, i will soon:

- update this readme
- add an example
- add some tests maybe
- make it crossplatform compatible (currently it depends on usb_serial package which makes it android exclusive. Linux, OSX and Windows should be possible aswell)
