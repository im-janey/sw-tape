import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/course/add_place.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MakeCosPage extends StatefulWidget {
  final String id;
  final String cosName;
  final DateTime timestamp;

  const MakeCosPage({
    super.key,
    required this.id,
    required this.cosName,
    required this.timestamp,
  });

  @override
  State<MakeCosPage> createState() => _MakeCosPageState();
}

class _MakeCosPageState extends State<MakeCosPage> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 14,
  );
  late GoogleMapController _controller;

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 10, left: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${widget.cosName}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${widget.timestamp.toLocal().year}.${widget.timestamp.toLocal().month}.${widget.timestamp.toLocal().day}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Container(
            height: 200.0,
            color: Colors.grey[300],
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: _onMapCreated,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '코스 만들기',
                  style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Padding(
                  padding: const EdgeInsets.only(right: 60.0),
                  child: Image.asset(
                    'assets/make_cos.png',
                    width: double.infinity,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 38.0, right: 4, top: 7),
                  child: SizedBox(
                    width: double.infinity,
                    height: 25,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPlacePage(
                            id: widget.id,
                            cosName: widget.cosName,
                            timestamp: widget.timestamp,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 0.3),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        '장소 추가',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
