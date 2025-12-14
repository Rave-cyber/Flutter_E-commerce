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
  static const double freeShippingThreshold =
      100.00; // Free shipping for orders over this amount

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
    // For now, return Manila coordinates as default
    // In a real implementation, you would use a geocoding service
    // like Google Maps Geocoding API or similar

    // Default to Manila coordinates
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
    // Free shipping for orders over threshold
    if (orderTotal >= freeShippingThreshold) {
      return 0.0;
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
