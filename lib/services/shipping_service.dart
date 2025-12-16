import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'philippine_address_service.dart';
import 'admin/warehouse_service.dart';
import '../models/warehouse_model.dart';

class ShippingService {
  final WarehouseService _warehouseService = WarehouseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Base shipping rates
  static const double baseRate = 5.99; // Base rate for first 5km
  static const double additionalPerKm = 2.50; // Rate per km after first 5km

  /// Calculate shipping fee based on address and order total
  Future<ShippingCalculation> calculateShipping({
    required String fullAddress,
    required double orderTotal,
    String? region,
    String? province,
    String? cityMunicipality,
    String? barangay,
  }) async {
    try {
      // Get all active warehouses
      final warehouses = await _warehouseService.fetchWarehousesOnce();
      final activeWarehouses = warehouses.where((w) => !w.is_archived).toList();

      if (activeWarehouses.isEmpty) {
        return ShippingCalculation(
          shippingFee: baseRate,
          distance: 0.0,
          nearestWarehouse: null,
          estimatedDays: 3,
        );
      }

      // Get coordinates for customer address
      final customerCoordinates = await _getCustomerCoordinates(
        region: region,
        province: province,
        cityMunicipality: cityMunicipality,
        barangay: barangay,
        fullAddress: fullAddress,
      );

      // Find nearest warehouse
      WarehouseModel? nearestWarehouse;
      double minDistance = double.infinity;

      for (final warehouse in activeWarehouses) {
        final distance = _calculateDistance(
          customerCoordinates.latitude,
          customerCoordinates.longitude,
          warehouse.latitude,
          warehouse.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearestWarehouse = warehouse;
        }
      }

      // Calculate shipping fee
      double shippingFee = _calculateShippingFee(minDistance, orderTotal);

      // Estimate delivery days based on distance
      int estimatedDays = _estimateDeliveryDays(minDistance);

      return ShippingCalculation(
        shippingFee: shippingFee,
        distance: minDistance,
        nearestWarehouse: nearestWarehouse,
        estimatedDays: estimatedDays,
      );
    } catch (e) {
      // Fallback to default shipping if calculation fails
      return ShippingCalculation(
        shippingFee: baseRate,
        distance: 0.0,
        nearestWarehouse: null,
        estimatedDays: 3,
      );
    }
  }

  /// Get coordinates for customer address using Philippine address service
  Future<Coordinates> _getCustomerCoordinates({
    String? region,
    String? province,
    String? cityMunicipality,
    String? barangay,
    String? fullAddress,
  }) async {
    // Try to parse address components from the full address
    if (fullAddress != null && fullAddress.isNotEmpty) {
      final address = fullAddress.toLowerCase();

      // Manila Metro areas
      if (address.contains('manila') ||
          address.contains('metro manila') ||
          address.contains('ncr') ||
          address.contains('city of manila')) {
        return Coordinates(latitude: 14.5995, longitude: 120.9842);
      }

      // Quezon City
      if (address.contains('quezon city') || address.contains('qc')) {
        return Coordinates(latitude: 14.6760, longitude: 121.0437);
      }

      // Makati
      if (address.contains('makati')) {
        return Coordinates(latitude: 14.5547, longitude: 121.0244);
      }

      // Cebu City
      if (address.contains('cebu city') || address.contains('cebu')) {
        return Coordinates(latitude: 10.3155, longitude: 123.8851);
      }

      // Davao City
      if (address.contains('davao city') || address.contains('davao')) {
        return Coordinates(latitude: 7.1907, longitude: 125.4553);
      }

      // Baguio
      if (address.contains('baguio')) {
        return Coordinates(latitude: 16.4023, longitude: 120.5960);
      }

      // Iloilo City
      if (address.contains('iloilo city') || address.contains('iloilo')) {
        return Coordinates(latitude: 10.6947, longitude: 122.5644);
      }

      // General Philippines regions - rough coordinates
      if (address.contains('luzon')) {
        return Coordinates(latitude: 15.0, longitude: 121.0);
      }
      if (address.contains('visayas')) {
        return Coordinates(latitude: 11.0, longitude: 123.5);
      }
      if (address.contains('mindanao')) {
        return Coordinates(latitude: 8.0, longitude: 125.0);
      }

      // Additional major cities
      if (address.contains('clark') || address.contains('pampanga')) {
        return Coordinates(latitude: 15.1851, longitude: 120.5596);
      }
      if (address.contains('subic') || address.contains('zambales')) {
        return Coordinates(latitude: 14.8747, longitude: 120.3464);
      }
      if (address.contains('laguna')) {
        return Coordinates(latitude: 14.2681, longitude: 121.3633);
      }
      if (address.contains('batangas')) {
        return Coordinates(latitude: 13.7568, longitude: 121.0584);
      }
      if (address.contains('cavite')) {
        return Coordinates(latitude: 14.4792, longitude: 120.8974);
      }
      if (address.contains('rizal')) {
        return Coordinates(latitude: 14.7055, longitude: 121.1413);
      }
    }

    // Default to Manila coordinates if no match found
    return Coordinates(latitude: 14.5995, longitude: 120.9842);
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in kilometers
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Calculate shipping fee based on distance and order total
  double _calculateShippingFee(double distance, double orderTotal) {
    // Ensure we have a valid distance
    if (distance <= 0 || distance.isNaN || distance.isInfinite) {
      return baseRate; // Fallback to base rate for invalid distances
    }

    // Base rate for first 5km
    if (distance <= 5.0) {
      return baseRate;
    }

    // Additional rate for distance beyond 5km
    double additionalDistance = distance - 5.0;
    double additionalCost = additionalDistance * additionalPerKm;

    return baseRate + additionalCost;
  }

  /// Estimate delivery days based on distance
  int _estimateDeliveryDays(double distance) {
    if (distance <= 5.0) {
      return 1; // Same day delivery for very close areas
    } else if (distance <= 20.0) {
      return 2; // Next day delivery
    } else if (distance <= 50.0) {
      return 3; // 2-3 business days
    } else if (distance <= 100.0) {
      return 5; // 3-5 business days
    } else {
      return 7; // 5-7 business days for very far areas
    }
  }

  /// Get shipping zones for display purposes
  List<ShippingZone> getShippingZones() {
    return [
      ShippingZone(
        name: 'Same Day',
        maxDistance: 5.0,
        baseRate: baseRate,
        description: 'Within 5km',
        estimatedDays: 1,
      ),
      ShippingZone(
        name: 'Next Day',
        maxDistance: 20.0,
        baseRate: baseRate + (15.0 * additionalPerKm),
        description: '5-20km',
        estimatedDays: 2,
      ),
      ShippingZone(
        name: 'Standard',
        maxDistance: 50.0,
        baseRate: baseRate + (45.0 * additionalPerKm),
        description: '20-50km',
        estimatedDays: 3,
      ),
      ShippingZone(
        name: 'Express',
        maxDistance: 100.0,
        baseRate: baseRate + (95.0 * additionalPerKm),
        description: '50-100km',
        estimatedDays: 5,
      ),
      ShippingZone(
        name: 'Remote',
        maxDistance: double.infinity,
        baseRate: baseRate + (100.0 * additionalPerKm),
        description: '100km+',
        estimatedDays: 7,
      ),
    ];
  }
}

/// Model for shipping calculation result
class ShippingCalculation {
  final double shippingFee;
  final double distance;
  final WarehouseModel? nearestWarehouse;
  final int estimatedDays;

  ShippingCalculation({
    required this.shippingFee,
    required this.distance,
    required this.nearestWarehouse,
    required this.estimatedDays,
  });

  String get formattedDistance => '${distance.toStringAsFixed(1)}km';
  String get formattedFee => '\$${shippingFee.toStringAsFixed(2)}';
}

/// Model for coordinates
class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({required this.latitude, required this.longitude});
}

/// Model for shipping zones
class ShippingZone {
  final String name;
  final double maxDistance;
  final double baseRate;
  final String description;
  final int estimatedDays;

  ShippingZone({
    required this.name,
    required this.maxDistance,
    required this.baseRate,
    required this.description,
    required this.estimatedDays,
  });

  String get formattedRate => '\$${baseRate.toStringAsFixed(2)}';
}
