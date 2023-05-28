// Path: lib/home/home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      setState(() {
        coordinates = myMap.entries
            .map((entry) => '${entry.key}:${entry.value}')
            .toList();
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                'You are logged in as ${FirebaseAuth.instance.currentUser!.email}'),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Logout'),
            ),
            ElevatedButton(
              onPressed: () {
                _lockButton(lockRef);
              },
              child: Text(lockStatus ? 'Unlock' : 'Lock'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                  height: screenHeight * 0.5,
                  width: screenWidth,
                  child: CoordinatesList(
                    items: coordinates,
                  )),
            ),
          ],
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
