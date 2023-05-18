import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math' show cos, sqrt, asin;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  double zoom = 15.5;

  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;

  static const LatLng sourceLocation = LatLng(23.037298, 72.5583761);
  static const LatLng destinationLocation = LatLng(23.0540638, 72.636001);

  List<LatLng> polylineCoordinates = [];

  LocationData? currentLocation;

  String estimateDistance = "";
  String estimateTime = "";
  double totalDistance = 0;

  @override
  void initState() {
    addCustomIcon();
    //getPolyPoints();
    getCurrentLocation();

    super.initState();
  }

  void addCustomIcon() {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), "assets/images/car.png")
        .then(
      (icon) {
        setState(() {
          markerIcon = icon;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map")),
      body: Stack(
        children: [
          GoogleMap(
            myLocationButtonEnabled: true,
            initialCameraPosition: CameraPosition(
              target: currentLocation != null
                  ? LatLng(
                      currentLocation!.latitude!, currentLocation!.longitude!)
                  : sourceLocation,
              zoom: zoom,
            ),
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
            markers: {
              Marker(
                  markerId: const MarkerId("source"),
                  position: currentLocation != null
                      ? LatLng(currentLocation!.latitude!,
                          currentLocation!.longitude!)
                      : sourceLocation,
                  icon: polylineCoordinates.isNotEmpty
                      ? markerIcon
                      : BitmapDescriptor.defaultMarker,
                  rotation: currentLocation != null
                      ? currentLocation!.heading!
                      : 0.0),
              const Marker(
                  markerId: MarkerId("destination"),
                  position: destinationLocation)
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId("route"),
                points: polylineCoordinates,
                color: Colors.red,
                width: 6,
              ),
            },
          ),
          estimateDistance.isNotEmpty
              ? Container(
                  color: Colors.white,
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        estimateDistance,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black),
                      ),
                      Text(
                        estimateTime,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black),
                      )
                    ],
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  /// this method will create polyline between two latlong point
  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyCgNe1m0YUQ_33ogv7lTVCoMb7OQMcZlAE", // Your Google Map Key
      PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!),
      PointLatLng(destinationLocation.latitude, destinationLocation.longitude),
    );

    /// clear already added polyline before setting new lines
    polylineCoordinates.clear();
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        );
      }
      getDistance();
    }
  }

  /// this method will get users current location
  void getCurrentLocation() async {
    Location location = Location();
    location.getLocation().then(
      (location) {
        setState(() {
          currentLocation = location;
        });

        getPolyPoints();
      },
    );
    GoogleMapController googleMapController = await _controller.future;
    location.onLocationChanged.listen(
      (newLoc) {
        currentLocation = newLoc;
        getPolyPoints();
        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              zoom: zoom,
              target: LatLng(
                newLoc.latitude!,
                newLoc.longitude!,
              ),
            ),
          ),
        );
        setState(() {});
      },
    );
  }

  void getDistance() {
    totalDistance = 0;
    for (var i = 0; i < polylineCoordinates.length - 1; i++) {
      totalDistance += calculateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude);
    }

    estimateDistance = "${(totalDistance).toStringAsFixed(2)} km";

    estimateTime = "${getEstimateTimeOfTravelling()}";

    setState(() {});
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;

    print("object ${1000 * 12742 * asin(sqrt(a))} Min est xxxxxxxxxxx");
    return 12742 * asin(sqrt(a));
  }

  String getEstimateTimeOfTravelling() {
    double travelTimeInHours = totalDistance / 25;
    int travelTimeInMinutes = (travelTimeInHours * 60).round();
    int hours = travelTimeInMinutes ~/ 60;
    int minutes = travelTimeInMinutes % 60;
    return "$hours h $minutes min";
  }
}
