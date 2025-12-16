import 'dart:convert';
import 'package:http/http.dart' as http;

class PhilippineAddressService {
  // Using PSGC API (Philippine Standard Geographic Code)
  static const String baseUrl = 'https://psgc.gitlab.io/api';

  // Get all regions
  static Future<List<Map<String, dynamic>>> getRegions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/regions/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((e) => {
                  'code': e['code'],
                  'name': e['name'],
                  'regionName': e['regionName'] ?? e['name'],
                })
            .toList();
      }
    } catch (e) {
      print('Error fetching regions: $e');
    }
    return [];
  }

  // Get provinces by region code
  static Future<List<Map<String, dynamic>>> getProvinces(
      String regionCode) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/regions/$regionCode/provinces/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((e) => {
                  'code': e['code'],
                  'name': e['name'],
                })
            .toList();
      }
    } catch (e) {
      print('Error fetching provinces: $e');
    }
    return [];
  }

  // Get cities/municipalities by province code
  static Future<List<Map<String, dynamic>>> getCitiesMunicipalities(
      String provinceCode) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/provinces/$provinceCode/cities-municipalities/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((e) => {
                  'code': e['code'],
                  'name': e['name'],
                })
            .toList();
      }
    } catch (e) {
      print('Error fetching cities/municipalities: $e');
    }
    return [];
  }

  // Get barangays by city/municipality code
  static Future<List<Map<String, dynamic>>> getBarangays(
      String cityMunicipalityCode) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/cities-municipalities/$cityMunicipalityCode/barangays/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((e) => {
                  'code': e['code'],
                  'name': e['name'],
                })
            .toList();
      }
    } catch (e) {
      print('Error fetching barangays: $e');
    }
    return [];
  }
}
