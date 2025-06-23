import 'package:field_ar/data/models/field.dart';
import 'package:field_ar/data/services/field_service.dart';
import 'package:field_ar/data/services/user_service.dart';
import 'package:field_ar/features/field/field_create.dart';
import 'package:field_ar/features/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Import for LatLng support
// import 'package:flutter_localizations/flutter_localizations.dart'; // Not directly used here
import 'package:field_ar/features/field/field_screen.dart';

class FieldsScreen extends StatefulWidget {
  const FieldsScreen({super.key});

  @override
  _FieldsScreenState createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  final fieldService = FieldService();
  Future<void> _logout() async {
    final userService = UserService();
    await userService.logoutUser();
    // Navigate to the login screen or show a message
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _createField() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FieldCreateScreen()),
    ).then((_) {
      // Refresh the list when returning from create screen
      setState(() {});
    });
  }

  Future<List<Field>?> _fetchFields() async {
    return await fieldService.fetchFields();
  }

  Future<void> _deleteField(String fieldId) async {
    try {
      await fieldService.deleteField(fieldId);
      setState(() {}); // Refresh the list
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarla başarıyla silindi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tarla silinemedi: $e')));
    }
  }

  Future<Map<String, double>> _calculateCenter(
    List<List<List<List<double>>>> coordinates,
  ) async {
    double latSum = 0;
    double lngSum = 0;
    int count = 0;

    if (coordinates.isEmpty || coordinates.first.isEmpty || coordinates.first.first.isEmpty) {
      return {'latitude': 0, 'longitude': 0}; // Default or error case
    }

    for (var polygon in coordinates) {
      for (var ring in polygon) {
        for (var point in ring) {
          if (point.length >= 2) { // Ensure point has lat and lng
            latSum += point[1];
            lngSum += point[0];
            count++;
          }
        }
      }
    }
    if (count == 0) return {'latitude': 0, 'longitude': 0}; // Avoid division by zero
    return {'latitude': latSum / count, 'longitude': lngSum / count};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tarlalarım"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0), // Reduced padding for more space
        child: FutureBuilder<List<Field>?>(
          future: _fetchFields(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Hata: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco_outlined, size: 80, color: Colors.grey.shade400),
                    SizedBox(height: 16),
                    Text('Henüz tarla eklenmemiş.', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                    SizedBox(height: 8),
                    Text('Yeni tarla eklemek için + butonuna dokunun.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              );
            } else {
              final fields = snapshot.data!;
              return ListView.builder(
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  final field = fields[index];
                  return Card(
                    elevation: 3.0,
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FieldScreen(field: field),
                          ),
                        ).then((_) {
                           // Optional: refresh if details screen could change data shown here
                           setState(() {});
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Text(
                              field.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Text(
                              field.crop?.name ?? 'Ürün atanmamış',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                              tooltip: 'Tarlayı Sil',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Tarlayı Sil'),
                                      content: Text(
                                        '${field.name} adlı tarlayı silmek istediğinizden emin misiniz?',
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('İptal'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: const Text('Sil'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _deleteField(field.id);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          if (field.geom.coordinates.isNotEmpty && field.geom.coordinates.first.isNotEmpty && field.geom.coordinates.first.first.isNotEmpty)
                            SizedBox(
                              height: 180, // Slightly reduced height
                              child: ClipRRect( // Clip the map for rounded corners
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12.0),
                                  bottomRight: Radius.circular(12.0),
                                ),
                                child: FutureBuilder<Map<String, double>>(
                                  future: _calculateCenter(field.geom.coordinates),
                                  builder: (context, centerSnapshot) {
                                    if (centerSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    } else if (centerSnapshot.hasError || !centerSnapshot.hasData || (centerSnapshot.data!['latitude'] == 0 && centerSnapshot.data!['longitude'] == 0) ) {
                                      return Center(
                                        child: Text('Harita merkezi hesaplanamadı.', style: TextStyle(color: Colors.grey.shade600)),
                                      );
                                    } else {
                                      final center = centerSnapshot.data!;
                                      final points = field.geom.coordinates
                                          .expand((polygon) => polygon.expand((ring) => ring.map((point) => LatLng(point[1], point[0]))))
                                          .toList();
                                      if (points.isEmpty) {
                                        return Center(
                                          child: Text('Geometri noktası bulunamadı.', style: TextStyle(color: Colors.grey.shade600)),
                                        );
                                      }
                                      return FlutterMap(
                                        options: MapOptions(
                                          center: LatLng(center['latitude']!, center['longitude']!),
                                          zoom: 15.0, // Adjusted zoom
                                          interactiveFlags: InteractiveFlag.none, // Disable map interaction in list view
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate: 'https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
                                            subdomains: const ['0', '1', '2', '3'],
                                            userAgentPackageName: 'com.example.app',
                                          ),
                                          if (points.isNotEmpty)
                                            PolygonLayer(
                                              polygons: [
                                                Polygon(
                                                  points: points,
                                                  color: Colors.blue.withOpacity(0.5),
                                                  borderColor: Colors.blueAccent,
                                                  borderStrokeWidth: 2.5,
                                                  isFilled: true,
                                                ),
                                              ],
                                            ),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ),
                            )
                          else 
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(child: Text("Bu tarla için harita verisi yok.", style: TextStyle(color: Colors.grey.shade600))),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createField,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Yeni Tarla Ekle", style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Centered FAB
      // Removed BottomAppBar as logout is in AppBar and FAB is more prominent
    );
  }
}
