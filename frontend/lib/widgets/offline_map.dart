import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OfflineMapWidget extends StatelessWidget {
  final LatLng center;
  final List<LatLng>? routePoints;

  const OfflineMapWidget({Key? key, required this.center, this.routePoints})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(center: center, zoom: 10.0),
      children: [
        // OpenStreetMap tile layer (cached automatically by flutter_map)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.smart_rural',
          maxNativeZoom: 19,
          maxZoom: 19,
          // Tiles are cached by default in flutter_map
        ),

        // Route polyline if points provided
        if (routePoints != null && routePoints!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints!,
                color: Colors.blue,
                strokeWidth: 4.0,
              ),
            ],
          ),

        // Markers
        MarkerLayer(
          markers: [
            Marker(
              width: 40,
              height: 40,
              point: center,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
