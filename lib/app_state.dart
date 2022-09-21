import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/lat_lng.dart';
import 'dart:convert';

class FFAppState {
  static final FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal() {
    initializePersistedState();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _isInitailLaunch = prefs.getBool('ff_isInitailLaunch') ?? _isInitailLaunch;
    _locale = prefs.getString('ff_locale') ?? _locale;
    _authToken = prefs.getString('ff_authToken') ?? _authToken;
  }

  late SharedPreferences prefs;

  dynamic property;

  LatLng? coordinates;

  dynamic filter = jsonDecode(
      '{\"city\":null,\" furnishing_type\":null,\"property_type\":null,\"minimum_price\":null,\"mximum_price\":null}');

  String filterCity = '';

  bool _isInitailLaunch = true;
  bool get isInitailLaunch => _isInitailLaunch;
  set isInitailLaunch(bool _value) {
    _isInitailLaunch = _value;
    prefs.setBool('ff_isInitailLaunch', _value);
  }

  List<String> filterPropertyType = [];

  List<String> filterFurnishingType = [];

  int filterMinPrice = 0;

  int filterMaxPrice = 0;

  String propertyStatus = '';

  String _locale = 'ar';
  String get locale => _locale;
  set locale(String _value) {
    _locale = _value;
    prefs.setString('ff_locale', _value);
  }

  String refreshToken = '';

  String _authToken = '';
  String get authToken => _authToken;
  set authToken(String _value) {
    _authToken = _value;
    prefs.setString('ff_authToken', _value);
  }
}

LatLng? _latLngFromString(String? val) {
  if (val == null) {
    return null;
  }
  final split = val.split(',');
  final lat = double.parse(split.first);
  final lng = double.parse(split.last);
  return LatLng(lat, lng);
}
