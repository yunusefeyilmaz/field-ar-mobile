import 'package:field_ar/data/models/crop.dart';
import 'package:field_ar/data/models/multiPolygon.dart';
import 'package:field_ar/data/services/crop_service.dart';
import 'package:field_ar/data/services/field_service.dart';
import 'package:field_ar/data/services/user_service.dart';
import 'package:field_ar/features/field/fields_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class FieldCreateScreen extends StatefulWidget {
  const FieldCreateScreen({super.key});

  @override
  _FieldCreateScreenState createState() => _FieldCreateScreenState();
}

class _FieldCreateScreenState extends State<FieldCreateScreen> {
  final _formKey = GlobalKey<FormState>(); // Add form key for validation
  final TextEditingController _fieldNameController = TextEditingController();
  // Use Crop? for selectedCrop to handle nullability and store the whole object
  Crop? _selectedCrop;
  DateTime? _plantedDate;
  DateTime? _harvestedDate;
  List<LatLng> _geometryLatLngPoints =
      []; // Store LatLng for map display and conversion

  final userService = UserService();
  final fieldService = FieldService();
  final cropService = CropService();
  bool _isLoading = false; // For loading indicator

  void _backButton() {
    // Check if we can pop or need to replace
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FieldsScreen()),
      );
    }
  }

  void _selectGeometryOnMap() async {
    final List<LatLng>? selectedLatLngPoints = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapSelectionScreen()),
    );
    if (selectedLatLngPoints != null && selectedLatLngPoints.isNotEmpty) {
      setState(() {
        _geometryLatLngPoints = selectedLatLngPoints;
      });
    }
  }

  Future<List<Crop>> _fetchCrops() async {
    // Changed to return List<Crop> and handle null inside
    final List<Crop>? crops = await cropService.fetchCrops();
    if (crops != null) {
      return crops;
    } else {
      if (!mounted) return [];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ürünler yüklenemedi.')));
      return []; // Return empty list on failure
    }
  }

  void _saveField() async {
    if (!_formKey.currentState!.validate()) {
      return; // Validation failed
    }
    if (_geometryLatLngPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen haritadan en az 3 nokta seçin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String fieldName = _fieldNameController.text;
    final String cropId =
        _selectedCrop!
            .id; // Assumes _selectedCrop is not null due to validation

    // Convert LatLng points to the required format for MultiPolygon
    // The API expects longitude first, then latitude: [lng, lat]
    final List<List<double>> geom =
        _geometryLatLngPoints
            .map((point) => [point.longitude, point.latitude])
            .toList();
    // Close the polygon by adding the first point at the end
    if (geom.isNotEmpty) {
      geom.add(geom.first);
    }

    final MultiPolygon multiPolygon = MultiPolygon(
      type: 'MultiPolygon',
      coordinates: [
        [geom], // A single polygon ring
      ],
    );

    final Map<String, String?> userInfo = await userService.getUserInfo();
    final String userId = userInfo['id'] ?? '';

    if (userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kullanıcı bilgisi alınamadı. Lütfen tekrar giriş yapın.',
          ),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await fieldService.createField(
        fieldName,
        multiPolygon,
        cropId,
        userId,
        _plantedDate,
        _harvestedDate,
      );
      if (!mounted) return;
      if (response != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarla başarıyla oluşturuldu!')),
        );
        // Pop back to FieldsScreen and trigger a refresh
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tarla oluşturulamadı.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
      );
    } finally {
      // Corrected finally block
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, double>> _calculateCenterFromLatLng(
    List<LatLng> points,
  ) async {
    if (points.isEmpty) {
      return {'latitude': 0, 'longitude': 0};
    }
    double latSum = 0;
    double lngSum = 0;
    for (var point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    return {
      'latitude': latSum / points.length,
      'longitude': lngSum / points.length,
    };
  }

  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime) onDateSelected,
    DateTime? initialDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () => _selectDate(context, onDateSelected, selectedDate),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate != null
              ? DateFormat.yMd('tr_TR').format(selectedDate)
              : 'Tarih Seçilmedi',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fieldNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Tarla Oluştur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              _isLoading
                  ? null
                  : _backButton, // Disable back button when loading
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fieldNameController,
                decoration: const InputDecoration(
                  labelText: 'Tarla Adı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_important_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen tarla adını girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Crop>>(
                future: _fetchCrops(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text(
                      'Hata: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Uygun ürün bulunamadı.');
                  } else {
                    final crops = snapshot.data!;
                    // Ensure _selectedCrop is one of the fetched crops if it was set before
                    if (_selectedCrop != null &&
                        !crops.any((c) => c.id == _selectedCrop!.id)) {
                      _selectedCrop = null;
                    }
                    return DropdownButtonFormField<Crop>(
                      decoration: const InputDecoration(
                        labelText: 'Ürün Seçin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.agriculture_outlined),
                      ),
                      value: _selectedCrop,
                      isExpanded: true,
                      items:
                          crops.map((Crop crop) {
                            return DropdownMenuItem<Crop>(
                              value: crop,
                              child: Text(crop.name),
                            );
                          }).toList(),
                      onChanged: (Crop? selectedCrop) {
                        setState(() {
                          _selectedCrop = selectedCrop;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Lütfen bir ürün seçin.';
                        }
                        return null;
                      },
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                label: 'Ekim Tarihi',
                selectedDate: _plantedDate,
                onDateSelected: (date) {
                  setState(() {
                    _plantedDate = date;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                label: 'Tahmini Hasat Tarihi',
                selectedDate: _harvestedDate,
                onDateSelected: (date) {
                  setState(() {
                    _harvestedDate = date;
                  });
                },
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined),
                onPressed: _isLoading ? null : _selectGeometryOnMap,
                label: const Text('Haritadan Alan Seç'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              if (_geometryLatLngPoints.isNotEmpty)
                Text(
                  "${_geometryLatLngPoints.length} nokta seçildi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              const SizedBox(height: 16),
              // Preview Map
              if (_geometryLatLngPoints.length >=
                  3) // Show map only if there are enough points for a polygon
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FutureBuilder<Map<String, double>>(
                    future: _calculateCenterFromLatLng(_geometryLatLngPoints),
                    builder: (context, centerSnapshot) {
                      if (centerSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (centerSnapshot.hasError ||
                          !centerSnapshot.hasData) {
                        return const Center(
                          child: Text('Harita merkezi hesaplanamadı.'),
                        );
                      } else {
                        final center = centerSnapshot.data!;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FlutterMap(
                            options: MapOptions(
                              center: LatLng(
                                center['latitude']!,
                                center['longitude']!,
                              ),
                              zoom:
                                  15.0, // Adjust zoom to fit polygon better if possible
                              interactiveFlags:
                                  InteractiveFlag
                                      .none, // Make it non-interactive for preview
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                                subdomains: const ['0', '1', '2', '3'],
                                userAgentPackageName: 'com.example.app',
                              ),
                              PolygonLayer(
                                polygons: [
                                  Polygon(
                                    points: _geometryLatLngPoints,
                                    color: Colors.blue.withOpacity(0.5),
                                    borderColor: Colors.blueAccent,
                                    borderStrokeWidth: 2.5,
                                    isFilled: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon:
                    _isLoading
                        ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Icon(Icons.save_alt_outlined),
                onPressed: _isLoading ? null : _saveField,
                label: Text(_isLoading ? 'Kaydediliyor...' : 'Tarlayı Kaydet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final List<LatLng> _polygonPoints = [];
  bool _isDrawing = false;
  MapController _mapController = MapController(); // Add map controller

  // Bursa, Turkey coordinates
  final LatLng _initialCenter = LatLng(40.193298, 29.074202); // Removed const

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // Added TapPosition argument
    if (_isDrawing) {
      setState(() {
        _polygonPoints.add(point);
      });
    }
  }

  void _finishSelection() {
    if (_polygonPoints.length >= 3) {
      // Return the points as LatLng objects
      Navigator.pop(context, List<LatLng>.from(_polygonPoints));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bir poligon oluşturmak için lütfen en az 3 nokta seçin.',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  void _clearPoints() {
    setState(() {
      _polygonPoints.clear();
    });
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawing = !_isDrawing;
      if (_isDrawing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Çizim modu aktif. Haritaya dokunarak nokta ekleyin.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Çizim modu durduruldu.')));
      }
    });
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haritadan Alan Seç'),
        actions: [
          if (_polygonPoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Son Noktayı Geri Al',
              onPressed: _undoLastPoint,
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Tüm Noktaları Temizle',
            onPressed: _clearPoints,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Seçimi Tamamla',
            onPressed: _finishSelection,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController, // Assign controller
              options: MapOptions(
                center: _initialCenter,
                zoom: 13.0,
                onTap: _onMapTap, // Corrected onTap signature
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                  subdomains: const ['0', '1', '2', '3'],
                  userAgentPackageName: 'com.example.app',
                ),
                if (_polygonPoints.isNotEmpty)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _polygonPoints,
                        // strokeWidth: 3.0, // strokeWidth is not a direct property of Polygon in flutter_map
                        // It is part of Polyline, or controlled by borderStrokeWidth for Polygon
                        color: Colors.cyan.withOpacity(0.4),
                        borderColor: Colors.cyanAccent,
                        borderStrokeWidth:
                            3.0, // Use borderStrokeWidth for polygon outline
                        isFilled: true,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers:
                      _polygonPoints.asMap().entries.map((entry) {
                        int idx = entry.key;
                        LatLng point = entry.value;
                        return Marker(
                          width: 80.0,
                          height: 80.0,
                          point: point,
                          builder:
                              (ctx) => Tooltip(
                                message: "Nokta ${idx + 1}",
                                child: Icon(
                                  Icons.location_pin,
                                  color: Colors.redAccent,
                                  size: 30.0,
                                ),
                              ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  'Nokta Sayısı: ${_polygonPoints.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: Icon(
                    _isDrawing
                        ? Icons.pause_circle_filled_outlined
                        : Icons.play_circle_fill_outlined,
                  ),
                  onPressed: _toggleDrawingMode,
                  label: Text(_isDrawing ? 'Çizimi Durdur' : 'Çizime Başla'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isDrawing
                            ? Colors.orangeAccent
                            : Colors.greenAccent.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(
                      double.infinity,
                      48,
                    ), // Make button wider
                    textStyle: const TextStyle(fontSize: 16),
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
