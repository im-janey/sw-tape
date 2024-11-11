import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class Showcos extends StatefulWidget {
  final String docId;
  const Showcos({super.key, required this.docId});

  @override
  State<Showcos> createState() => _ShowcosState();
}

class _ShowcosState extends State<Showcos> {
  List<String> contentIds = [];
  List<Map<String, dynamic>> places = [];
  late GoogleMapController mapController;
  final LatLng _initialPosition = const LatLng(37.5665, 126.9780);
  Set<Marker> _markers = {};
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _fetchContentIds();
  }

  Future<void> _fetchContentIds() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('my cos')
          .doc(widget.docId)
          .get();

      contentIds =
          List<String>.from(docSnapshot.data()?['selectedplace'] ?? []);
      print('Fetched content IDs: $contentIds');
      await _fetchPlaceDetails();
    } catch (e) {
      print('Error fetching content IDs: $e');
    }
  }

  Future<void> _fetchPlaceDetails() async {
    const apiKey =
        'KM3ecfJElcRcl6wIaSFS36i2YxG6DDD53ng%2Bgt0IZGWPCDgSXvWhdyH%2BOh1Wz41b2m4LzW5kCQaOuUfbN8HNOA%3D%3D';
    List<Map<String, dynamic>> fetchedDetails = [];

    for (String contentId in contentIds) {
      final apiUrl =
          'https://apis.data.go.kr/B551011/KorWithService1/detailCommon1?MobileOS=ios&MobileApp=sad&contentId=$contentId&defaultYN=Y&firstImageYN=Y&mapinfoYN=Y&_type=json&serviceKey=$apiKey';

      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final decodedData = json.decode(utf8.decode(response.bodyBytes));
          print('API Response: $decodedData');
          var item = decodedData['response']?['body']?['items']?['item'];

          if (item is Map<String, dynamic>) {
            _processPlaceDetails(item, fetchedDetails);
          } else if (item is List && item.isNotEmpty) {
            _processPlaceDetails(item[0], fetchedDetails);
          }
        } else {
          print('API request failed with status: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching place details: $e');
      }
    }

    setState(() {
      places = fetchedDetails;
      print('Fetched places: $places');
    });
    _updateCameraBounds();
  }

  void _processPlaceDetails(
      Map<String, dynamic> item, List<Map<String, dynamic>> fetchedDetails) {
    double? lat = double.tryParse(item['mapy'] ?? '');
    double? lng = double.tryParse(item['mapx'] ?? '');
    String title = item['title'] ?? '제목 없음';
    String contentId = item['contentid'] ?? '';

    if (lat != null && lng != null && lat != 0 && lng != 0) {
      final place = {
        'contentid': contentId,
        'title': title,
        'lat': lat,
        'lng': lng,
        'firstimage': item['firstimage'] ?? '',
      };

      fetchedDetails.add(place);
      _addMarker(place);
    }
  }

  void _addMarker(Map<String, dynamic> place) {
    final lat = place['lat'];
    final lng = place['lng'];
    final title = place['title'];
    final contentId = place['contentid'];

    if (lat != null && lng != null) {
      final marker = Marker(
        markerId: MarkerId(contentId),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: title),
      );

      setState(() {
        _markers.add(marker);
      });
    }
  }

  void _updateCameraBounds() {
    if (_markers.isEmpty || !_isMapReady) return;

    LatLngBounds bounds;
    final latitudes =
        _markers.map((marker) => marker.position.latitude).toList();
    final longitudes =
        _markers.map((marker) => marker.position.longitude).toList();

    final southwest = LatLng(
      latitudes.reduce((a, b) => a < b ? a : b),
      longitudes.reduce((a, b) => a < b ? a : b),
    );
    final northeast = LatLng(
      latitudes.reduce((a, b) => a > b ? a : b),
      longitudes.reduce((a, b) => a > b ? a : b),
    );

    bounds = LatLngBounds(southwest: southwest, northeast: northeast);

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 10,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                mapController = controller;
                _isMapReady = true;
                _updateCameraBounds();
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 10,
              ),
              itemCount: places.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                final place = places[index];
                return Card(
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: place['firstimage'] != ''
                            ? Image.network(
                                place['firstimage'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : const Icon(
                                Icons.image_not_supported,
                                size: 50,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          place['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
