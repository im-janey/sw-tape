import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/packages/product.dart';
import 'package:flutter_application_1/screens/detail/detailpage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class Frame extends StatelessWidget {
  final Product product;

  const Frame({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: fetchBySubCategories(product.subCategories),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          }

          return MapPage(places: snapshot.data!, collectionName: product.name);
        },
      ),
    );
  }

  Future<List<dynamic>> fetchBySubCategories(List<String> subCategories) async {
    const apiKey =
        'K%2Bwrqt0w3kcqkpq5TzBHI8P37Kfk50Rlz1dYzc62tM2ltmIBDY3VG4eiblr%2FQbjw1JSXZYsFQBw4IieHP9cP9g%3D%3D';

    List<dynamic> allItems = [];

    for (String subCategory in subCategories) {
      final apiUrl =
          'http://apis.data.go.kr/B551011/KorWithService1/searchKeyword1?serviceKey=$apiKey&MobileOS=ETC&MobileApp=AppTest&keyword=$subCategory&numOfRows=20&pageNo=1&_type=json';

      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final decodedData = json.decode(utf8.decode(response.bodyBytes));
          if (decodedData['response'] != null &&
              decodedData['response']['body'] != null &&
              decodedData['response']['body']['items'] != null) {
            final items =
                decodedData['response']['body']['items']['item'] as List;

            allItems.addAll(items.where((item) =>
                item['firstimage'] != null &&
                item['firstimage'].toString().isNotEmpty));
          }
        } else {
          throw Exception('Failed to load data for subcategory: $subCategory');
        }
      } catch (e) {
        print('Error fetching data for subcategory: $subCategory. $e');
      }
    }

    return allItems;
  }
}

class MapPage extends StatefulWidget {
  final List<dynamic> places;
  final String collectionName;

  MapPage({
    super.key,
    required this.places,
    required this.collectionName,
  });

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final LatLng _center = const LatLng(37.5758772, 126.9768121);
  final Map<String, LatLng> _cityCoordinates = {
    '서울': LatLng(37.5665, 126.9780),
    '대구': LatLng(35.8714, 128.6014),
    '포항': LatLng(36.0190, 129.3435),
    '대전': LatLng(36.3504, 127.3845),
  };
  String _selectedCity = '서울';
  final Set<Marker> _markers = {};

  void _adjustCameraToFitMarkers() {
    if (_markers.isEmpty) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (final marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  Future<void> _createMarkers() async {
    setState(() {
      _markers.clear();
    });

    for (var place in widget.places) {
      double latitude = double.parse(place['mapy']);
      double longitude = double.parse(place['mapx']);

      Marker marker = Marker(
        markerId: MarkerId(place['contentid'].toString()),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: place['title'],
          snippet: place['addr1'],
        ),
      );

      setState(() {
        _markers.add(marker);
      });
    }

    _adjustCameraToFitMarkers();
  }

  void _moveCamera(LatLng position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 12.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 100,
            child: DropdownButton<String>(
              value: _selectedCity,
              isExpanded: true,
              items: _cityCoordinates.keys.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value!;
                  _moveCamera(_cityCoordinates[_selectedCity]!);
                });
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _createMarkers();
            },
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            maxChildSize: 0.95,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                color: Colors.white,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.places.length,
                  itemBuilder: (context, index) {
                    var place = widget.places[index];
                    String imageUrl = place['firstimage'] ?? '';

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(
                              collectionName: widget.collectionName,
                              name: place['title'],
                              address: place['addr1'],
                              subname: '',
                              id: place['contentid'].toString(),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          if (imageUrl.isNotEmpty)
                            Image.network(
                              imageUrl,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.error);
                              },
                            )
                          else
                            Container(
                              height: 100,
                              width: 100,
                              color: Colors.grey,
                              child: Icon(Icons.image_not_supported),
                            ),
                          SizedBox(
                            width: 15,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place['title'] ?? 'No Name',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  place['addr1'] ?? 'No Address',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
