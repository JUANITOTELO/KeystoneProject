// Path: lib/home/home.dart
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  DatabaseReference gpsRef = FirebaseDatabase.instance.ref(
      "users/${FirebaseAuth.instance.currentUser!.uid}/gps/${DateTime.now().day}${DateTime.now().month}${DateTime.now().year}");
  DatabaseReference lockRef = FirebaseDatabase.instance
      .ref("users/${FirebaseAuth.instance.currentUser!.uid}/p1");
  bool lockStatus = false;
  List<String> coordinates = [];
  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
    _listenToChanges(gpsRef);
    _lockStatus(lockRef);
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _lockButton(DatabaseReference ref) async {
    ref.get().then((DataSnapshot? snapshot) {
      if (snapshot != null) {
        print(snapshot.value);
        setState(() {
          if (snapshot.value == false) {
            ref.set(true);
            lockStatus = true;
          } else {
            ref.set(false);
            lockStatus = false;
          }
        });
      }
    });
  }

  void _lockStatus(DatabaseReference ref) async {
    ref.get().then((DataSnapshot? snapshot) {
      if (snapshot != null) {
        setState(() {
          lockStatus = snapshot.value as bool;
        });
      }
    });
  }

  // listen to changes in the database
  void _listenToChanges(DatabaseReference ref) {
    ref.onValue.listen((event) {
      Map<Object?, Object?> myMap =
          event.snapshot.value as Map<Object?, Object?>;
      List<int> mykeys = [];
      myMap.forEach((key, value) {
        mykeys.add(int.parse(key.toString()));
      });
      mykeys.sort();
      setState(() {
        List<String> temp = [];
        for (var e in mykeys) {
          // '${entry.key}:${entry.value}'
          temp.add("$e:${myMap[e.toString()]}");
        }
        coordinates = temp;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hi ${FirebaseAuth.instance.currentUser!.email}'),
                    ElevatedButton(
                      onPressed: _logout,
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: SizedBox(
                    width: screenWidth,
                    height: screenHeight * 0.35,
                    child: MapWidget(
                      items: coordinates,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _lockButton(lockRef);
                },
                child: Text(lockStatus ? 'Unlock' : 'Lock'),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                    height: screenHeight * 0.25,
                    width: screenWidth,
                    child: CoordinatesList(
                      items: coordinates,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoordinatesList extends StatefulWidget {
  final List<String> items;
  const CoordinatesList({required this.items, Key? key}) : super(key: key);
  @override
  State<CoordinatesList> createState() => _CoordinatesListState();
}

class _CoordinatesListState extends State<CoordinatesList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(widget.items[index].split(':')[0]),
          subtitle: Text(
              "Latitude: ${widget.items[index].split(':')[1].split(',')[0]}\nLongitude: ${widget.items[index].split(':')[1].split(',')[1]}"),
        );
      },
    );
  }
}

class MapWidget extends StatefulWidget {
  final List<String> items;
  const MapWidget({Key? key, required this.items}) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  @override
  Widget build(BuildContext context) {
    double y = double.parse(widget.items[0].split(':')[1].split(',')[1]);
    double x = double.parse(widget.items[0].split(':')[1].split(',')[0]);
    return FlutterMap(
      options: MapOptions(
          center: LatLng(x, y),
          zoom: 15,
          maxZoom: 18,
          minZoom: 9,
          interactiveFlags: InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.flingAnimation |
              InteractiveFlag.rotate,
          keepAlive: true,
          rotationThreshold: 0.5),
      nonRotatedChildren: const [
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: widget.items
                  .map((e) => LatLng(
                      double.parse(e.split(':')[1].split(',')[0]),
                      double.parse(e.split(':')[1].split(',')[1])))
                  .toList(),
              strokeWidth: 4.0,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }
}
