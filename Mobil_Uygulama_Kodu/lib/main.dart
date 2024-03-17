import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert'; // ENCODE Edilmiş Verinin İşlenmesi İçin
import 'dart:async'; // Delay'ları Kullanmak İçin
import 'dart:typed_data'; // Byte Data Tipleri İçin
import 'dart:math';
import 'package:fluttertoast/fluttertoast.dart'; // Bildirimleri Göstermek İçin

void main() {
  runApp(MaterialApp(home: ConnectionScreen()));
}

// ConnectionScreen Widgeti
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({Key? key}) : super(key: key);

  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool isConnecting = true;
  bool connectionFailed = false; // Bağlanılamaması Halinde Güncelleniyor

  @override
  void initState() {
    // Bağlantı Başlatılması
    super.initState();
    connectToDevice();
  }

  // Bağlanma Fonksiyonu
  void connectToDevice() async {
    setState(() {
      isConnecting = true;
      connectionFailed = false;
    });

    try {
      final connection =
          await BluetoothConnection.toAddress('00:21:07:00:0B:57');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp(connection: connection)),
      );
    } catch (e) {
      print('Cannot connect, exception occurred');
      print(e);
      setState(() {
        isConnecting = false;
        connectionFailed = true;
      });
      // Başarısısz olması Halinde Tekrar Bağlanma
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          connectToDevice();
        }
      });
    }
  }

  void navigateToMyAppManually() {
    // Bluetooth Bağlantısı Olmaması Halinde Manuel Olarak İkinci Ekrana Geçme Butonu
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyApp(connection: null)),
    );
  }

  // Birinci Ekran Tasarımı
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.red,
            ),
            SizedBox(
                height: 20), // Space between CircularProgressIndicator and Text
            if (connectionFailed) Text('Bağlantı Kuruluyor...'),
            SizedBox(height: 20), // Space before the button
            ElevatedButton(
              onPressed: navigateToMyAppManually,
              child: Text('Görsel Kısmına Geç'),
            ),
          ],
        ),
      ),
    );
  }
}

// İkinci Ekranın Tasarımı

class MyApp extends StatefulWidget {
  BluetoothConnection?
      connection; // Connection is nullable but can be reassigned

  MyApp({Key? key, this.connection}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<int> adetArray = [0, 0, 0, 0, 0, 0];
  List<int> kutuArray = [0, 0, 0, 0, 0, 0];
  final String deviceAddress = '00:21:07:00:0F:F2'; // Example device address
  bool isAttemptingReconnect = false;

  //Ikıncı Ekran Başlatılması
  @override
  void initState() {
    super.initState();
    setupConnection();
  }

  void setupConnection() async {
    if (widget.connection == null) {
      await connectToDevice();
    } else {
      setupDataListener();
    }
  }

  // Bağlantı Fonksiyonu
  Future<void> connectToDevice() async {
    if (isAttemptingReconnect) {
      return; // Bağlanma İsteklerinin Üst Üste Binmemesi İçin Kontrol
    }
    isAttemptingReconnect = true;
    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(deviceAddress);
      setState(() {
        widget.connection = connection;
        isAttemptingReconnect = false;
      });
      setupDataListener();
      Fluttertoast.showToast(
          msg: "Connected to device", toastLength: Toast.LENGTH_SHORT);
    } catch (e) {
      setState(() {
        isAttemptingReconnect = false;
      });
      Fluttertoast.showToast(
          msg: "Bağlantı Koptu. Tekrar Bağlanılıyor...",
          toastLength: Toast.LENGTH_SHORT);
      Future.delayed(Duration(seconds: 10), () {
        if (mounted) {
          connectToDevice(); // Retry connection
        }
      });
    }
  }

  void setupDataListener() {
    widget.connection?.input?.listen(_onDataReceived).onDone(() {
      if (!mounted) return;
      Fluttertoast.showToast(
          msg: "Bağlantı Koptu Tekrar Bağlanılıyor...",
          toastLength: Toast.LENGTH_LONG);
      widget.connection = null; // Reset connection
      // Bağlantı kaybolduğunda ConnectionScreen'e geri dön
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ConnectionScreen()));
    });
  }

  // Verilerin DECODE Edilip Kullanıma Uygun Hale Getirilmesi
  void _onDataReceived(Uint8List data) {
    String dataString = ascii.decode(data);
    dataString = dataString.replaceAll('[', '').replaceAll(']', '');
    List<String> stringParts = dataString.split(',');
    // Fluttertoast.showToast(msg: "$dataString", toastLength: Toast.LENGTH_LONG);

    // Verinin beklenen uzunlukta olup olmadığını kontrol et
    if (stringParts.length == 12) {
      List<int> newData =
          stringParts.map((part) => int.tryParse(part) ?? 0).toList();

      setState(() {
        adetArray = newData.sublist(0, 6);
        kutuArray = newData.sublist(6, 12);
      });
    } else {
      // Hata işleme veya varsayılan değerler atama
      Fluttertoast.showToast(
          msg: "Hatalı Veri", toastLength: Toast.LENGTH_SHORT);
    }
  }

  // Fotoğrafları Koymak İçin Fonksiyon
  Container imageCreator(int imageNo) {
    return Container(
      height: 70,
      width: 100,
      child: InkWell(
        // onTap: () {
        //   setState(() {
        //     adetArray = generateRandomArray(6, 1, 5);
        //     kutuArray = generateRandomArray(6, 1, 5);
        //     // Fluttertoast.showToast(
        //     //     msg: "$adetArray", toastLength: Toast.LENGTH_LONG);
        //   });
        // },
        child: Image.asset('images/image$imageNo.png'),
      ),
    );
  }

  // Test İçin Random Veri Üretimi
  List<int> generateRandomArray(int length, int minValue, int maxValue) {
    Random random = Random();
    return List.generate(
        length, (i) => random.nextInt(maxValue - minValue + 1) + minValue);
  }

  // İkinci Ekran Tasarımı
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.blue[600],
        appBar: AppBar(
          title: Center(
            child: Text('Ürün Sayacı', style: TextStyle(color: Colors.white)),
          ),
          backgroundColor: Colors.grey,
        ),
        body: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Ürünler',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30.0,
                          fontFamily: 'Lato')),
                  for (int i = 1; i <= 6; i++) imageCreator(i),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                      Container(
                        height: 70,
                        child: Text('Toplam',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 30.0,
                                fontFamily: 'Lato')),
                      ),
                    ] +
                    List.generate(
                      adetArray.length,
                      (index) => Container(
                        height: 70,
                        child: Text('${adetArray[index]}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 30.0,
                                fontFamily: 'Lato')),
                      ),
                    ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                      Container(
                        height: 70,
                        child: Text('Kutu',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 30.0,
                                fontFamily: 'Lato')),
                      ),
                    ] +
                    List.generate(
                      kutuArray.length,
                      (index) => Container(
                        height: 70,
                        child: Text('${kutuArray[index]}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 30.0,
                                fontFamily: 'Lato')),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Bağlantı Bittikten Sonra Verilerin Temizlenmesi
    widget.connection?.dispose();
    super.dispose();
  }
}
