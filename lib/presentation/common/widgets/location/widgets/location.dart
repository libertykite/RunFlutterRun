import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../utils/map_math.dart';
import '../view_model/location_view_model.dart';

class Location extends HookConsumerWidget {
  const Location({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationViewModelProvider);
    final provider = ref.watch(locationViewModelProvider.notifier);

    var points = provider.savedPositionsLatLng();
    var center = getCenterOfMap(points);
    var zoomLevel = getZoomLevel(points, center);

    final markers = <Marker>[
      Marker(
        width: 80,
        height: 80,
        point: LatLng(state.currentPosition?.latitude ?? 0,
            state.currentPosition?.longitude ?? 0),
        builder: (ctx) => const Icon(
          Icons.place,
          size: 50,
          color: Colors.red,
        ),
      ),
    ];

    return Expanded(
        child: SizedBox(
            height: 500,
            child: FlutterMap(
              mapController: provider.mapController,
              options: MapOptions(
                center: points.isNotEmpty
                    ? center
                    : LatLng(state.currentPosition?.latitude ?? 0,
                        state.currentPosition?.longitude ?? 0),
                zoom: zoomLevel,
              ),
              nonRotatedChildren: const [],
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(markers: markers),
                PolylineLayer(
                  polylines: [
                    Polyline(
                        points: provider.savedPositionsLatLng(),
                        strokeWidth: 4,
                        color: Colors.blueGrey),
                  ],
                ),
              ],
            )));
  }
}