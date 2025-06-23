import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:field_ar/data/models/field.dart';
import 'package:field_ar/data/models/weather.dart';
import 'package:field_ar/data/models/waterStress.dart';
import 'package:field_ar/data/services/field_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';

class FieldScreen extends StatefulWidget {
  final Field field;
  const FieldScreen({super.key, required this.field});

  @override
  _FieldScreenState createState() => _FieldScreenState();
}

class _FieldScreenState extends State<FieldScreen> {
  final FieldService fieldService = FieldService();
  late Field _currentField;
  String? _modelUrl;
  bool _isLoading = true;
  String? _error;
  double _xScale = 0.10;
  double _yScale = 0.10;
  double _zScale = 0.10;
  double _stepSize = 0.15;

  final List<String> _styleEnums = [
    'Image_WaterStress_Sentinel-2',
    'Image_Nitrogen_Sentinel-2',
    'Image_CloudStatus_Sentinel-2',
    'Image_TrueColor_Sentinel-2',
    'Image_FalseColor_Sentinel-2',
  ];
  late String _selectedStyle;

  DateTime _selectedDate = DateTime.now();
  bool _showAdvancedSettings = false;

  Weather? _weatherData;
  WaterStressForecast? _waterStressForecast;
  DateTime _predictionDate = DateTime.now();
  bool _isPredictionLoading = true;
  String? _predictionError;
  DateTime? _plantedDate;
  DateTime? _harvestedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentField = widget.field;
    _plantedDate =
        _currentField.plantedDate != null
            ? DateTime.parse(_currentField.plantedDate!)
            : null;
    _harvestedDate =
        _currentField.harvestedDate != null
            ? DateTime.parse(_currentField.harvestedDate!)
            : null;
    _selectedStyle = _styleEnums.first; // Başlangıç değerini atıyoruz.
    _fetchInitialData();
    _fetchWaterStressForecast();
  }

  // Enum değerlerini kullanıcı dostu metinlere çeviren fonksiyon.
  String styleEnumToText(String value) {
    switch (value) {
      case 'Image_WaterStress_Sentinel-2':
        return 'Su Stresi (Sentinel-2)';
      case 'Image_Nitrogen_Sentinel-2':
        return 'Nitrojen (Sentinel-2)';
      case 'Image_CloudStatus_Sentinel-2':
        return 'Bulut Durumu (Sentinel-2)';
      case 'Image_TrueColor_Sentinel-2':
        return 'Gerçek Renk (Sentinel-2)';
      case 'Image_FalseColor_Sentinel-2':
        return 'Yanlış Renk (Sentinel-2)';
      default:
        return value;
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await _fetchWeather();
    await _fetchModel();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWaterStressForecast() async {
    if (!mounted) return;
    setState(() {
      _isPredictionLoading = true;
      _predictionError = null;
    });
    try {
      final forecast = await fieldService.getWaterStressForecast(
        widget.field.id,
        date: DateFormat('yyyy-MM-dd').format(_predictionDate),
      );
      if (mounted) {
        setState(() {
          _waterStressForecast = forecast;
          if (forecast == null) {
            _predictionError = 'Bu tarih için tahmin verisi bulunamadı.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _predictionError = 'Su stresi tahmini alınamadı: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPredictionLoading = false;
        });
      }
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final weather = await fieldService.getWeather(widget.field.id);
      if (mounted) {
        setState(() {
          _weatherData = weather;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Hava durumu verileri alınamadı: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _fetchModel() async {
    try {
      final modelBase64 = await fieldService.getGlbModel(
        widget.field.id,
        xScale: _xScale,
        yScale: _yScale,
        zScale: _zScale,
        stepSize: _stepSize,
        style: _selectedStyle,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );

      if (modelBase64 != null && mounted) {
        final Uint8List modelBytes = base64Decode(modelBase64);
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/model.glb');
        await file.writeAsBytes(modelBytes);
        setState(() {
          _modelUrl = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Model yüklenemedi: ${e.toString()}';
        });
      }
    }
  }

  void _updateModel() {
    setState(() {
      _isLoading = true;
    });
    _fetchModel().whenComplete(() {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _updateFieldDates() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await fieldService.updateField(
        _currentField.id,
        _currentField.name, // pass current name
        _currentField.geom, // pass current geometry
        _currentField.crop?.id, // pass current crop id
        _plantedDate,
        _harvestedDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Tarihler başarıyla güncellendi!'
                  : 'Tarihler güncellenemedi.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.field.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildDateManagementSection(),
            const SizedBox(height: 20),
            _buildWeatherDisplay(),
            const SizedBox(height: 20),
            _buildWaterStressSection(),
            const SizedBox(height: 20),
            _buildModelSettings(),
            const SizedBox(height: 20),
            _buildModelViewer(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDisplay() {
    if (_isLoading && _weatherData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_weatherData != null) {
      return _buildWeatherSection(_weatherData!);
    }
    // Show error only if weather data is null and there is an error message
    if (_error != null && _weatherData == null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    return const Center(child: Text('Hava durumu verisi bulunamadı.'));
  }

  Widget _buildDateManagementSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarih Yönetimi',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving ? 'Kaydediliyor...' : 'Tarihleri Güncelle',
                ),
                onPressed: _isSaving ? null : _updateFieldDates,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () => _selectDateForField(context, onDateSelected, selectedDate),
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

  Future<void> _selectDateForField(
    BuildContext context,
    Function(DateTime) onDateSelected,
    DateTime? initialDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Widget _buildWaterStressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Su Stresi Tahmini',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildPredictionDateSelector(),
        const SizedBox(height: 16),
        if (_isPredictionLoading)
          const Center(child: CircularProgressIndicator())
        else if (_predictionError != null)
          Center(
            child: Text(
              _predictionError!,
              style: const TextStyle(color: Colors.red),
            ),
          )
        else if (_waterStressForecast == null ||
            _waterStressForecast!.dailyForecast.isEmpty)
          const Center(child: Text('Bu tarih için tahmin verisi bulunamadı.'))
        else
          _buildWaterStressDisplay(_waterStressForecast!),
      ],
    );
  }

  Widget _buildPredictionDateSelector() {
    return InkWell(
      onTap: () => _selectPredictionDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tahmin Tarihi Seç',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(DateFormat.yMd('tr_TR').format(_predictionDate)),
      ),
    );
  }

  Future<void> _selectPredictionDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _predictionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Can only select past or today
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && picked != _predictionDate) {
      setState(() {
        _predictionDate = picked;
      });
      _fetchWaterStressForecast();
    }
  }

  Widget _buildWaterStressDisplay(WaterStressForecast forecast) {
    final forecasts = forecast.dailyForecast.values.toList();
    forecasts.sort((a, b) => a.date.compareTo(b.date));

    return SizedBox(
      height: 150, // Increased height for better spacing
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: forecasts.length,
        itemBuilder: (context, index) {
          return _buildWaterStressCard(forecasts[index]);
        },
      ),
    );
  }

  Widget _buildWaterStressCard(DailyForecast dailyForecast) {
    final date = DateTime.parse(dailyForecast.date);
    final dayName = _getDayName(date);
    final stressValue = dailyForecast.predictedWaterStress;
    final stressLabel = _translateStressCategory(dailyForecast.stressCategory);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  dayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.Md('tr_TR').format(date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            _getWaterStressIcon(stressValue),
            Text(
              '${(stressValue * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              stressLabel,
              style: TextStyle(
                fontSize: 12,
                color: _getWaterStressColor(stressValue),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _translateStressCategory(String category) {
    switch (category) {
      case "No Stress":
        return "Stres Yok";
      case "Low Stress":
        return "Düşük Stres";
      case "Moderate Stress":
        return "Orta Stres";
      case "High Stress":
        return "Yüksek Stres";
      default:
        return category;
    }
  }

  Icon _getWaterStressIcon(double value) {
    if (value > 0.75) {
      return Icon(Icons.error_outline, color: Colors.red[700], size: 32);
    } else if (value > 0.5) {
      return Icon(
        Icons.warning_amber_outlined,
        color: Colors.orange[700],
        size: 32,
      );
    } else if (value > 0.25) {
      return Icon(Icons.info_outline, color: Colors.yellow[800], size: 32);
    } else {
      return Icon(
        Icons.check_circle_outline,
        color: Colors.green[700],
        size: 32,
      );
    }
  }

  Color _getWaterStressColor(double value) {
    if (value > 0.75) {
      return Colors.red[700]!;
    } else if (value > 0.5) {
      return Colors.orange[700]!;
    } else if (value > 0.25) {
      return Colors.yellow[800]!;
    } else {
      return Colors.green[700]!;
    }
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.eco_outlined,
              color: Theme.of(context).primaryColor,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.field.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.field.crop?.name ?? 'Bilinmiyor',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSection(Weather weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haftalık Hava Durumu',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weather.daily.time.length,
            itemBuilder: (context, index) {
              return _buildWeatherCard(weather.daily, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard(Daily daily, int index) {
    final date = DateTime.parse(daily.time[index]);
    final dayName = _getDayName(date);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold)),
            _getWeatherIcon(daily.precipitationSum[index]),
            Text(
              '${daily.temperature2mMax[index].toStringAsFixed(0)}° / ${daily.temperature2mMin[index].toStringAsFixed(0)}°',
              style: const TextStyle(fontSize: 16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                Text('${daily.relativeHumidity2mMean[index]}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Icon _getWeatherIcon(double precipitation) {
    if (precipitation > 0.5) {
      return const Icon(Icons.beach_access, color: Colors.blue, size: 32);
    } else if (precipitation > 0.1) {
      return const Icon(Icons.grain, color: Colors.lightBlue, size: 32);
    } else {
      return const Icon(Icons.wb_sunny, color: Colors.orange, size: 32);
    }
  }

  String _getDayName(DateTime date) {
    if (date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day) {
      return 'Bugün';
    }
    return DateFormat.E('tr_TR').format(date);
  }

  Widget _buildModelSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3D Model Ayarları',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDateSelector()),
            const SizedBox(width: 16),
            Expanded(child: _buildStyleSelector()),
          ],
        ),
        Center(
          child: IconButton(
            icon: Icon(
              _showAdvancedSettings ? Icons.expand_less : Icons.expand_more,
            ),
            tooltip: 'Gelişmiş Ayarlar',
            onPressed: () {
              setState(() {
                _showAdvancedSettings = !_showAdvancedSettings;
              });
            },
          ),
        ),
        if (_showAdvancedSettings)
          Column(
            children: [
              _buildSlider('X Ekseni Ölçeği', _xScale, (val) {
                setState(() => _xScale = val);
              }),
              _buildSlider('Y Ekseni Ölçeği', _yScale, (val) {
                setState(() => _yScale = val);
              }),
              _buildSlider('Z Ekseni Ölçeği', _zScale, (val) {
                setState(() => _zScale = val);
              }),
              _buildSlider(
                'Adım Büyüklüğü',
                _stepSize,
                (val) {
                  setState(() => _stepSize = val);
                },
                min: 0.01,
                max: 1.0,
                divisions: 99,
              ),
            ],
          ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.threed_rotation_sharp),
            label: const Text('Modeli Güncelle'),
            onPressed: _isLoading ? null : _updateModel,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    ValueChanged<double> onChanged, {
    double min = 0.1,
    double max = 5.0,
    int? divisions,
  }) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ),
        Text(value.toStringAsFixed(2)),
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tarih Seç',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(DateFormat.yMd('tr_TR').format(_selectedDate)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildStyleSelector() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Görünüm Stili',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.style_outlined),
      ),
      value: _selectedStyle,
      isExpanded: true, // Yazıların sığması için
      items:
          _styleEnums.map((String style) {
            return DropdownMenuItem<String>(
              value: style,
              child: Text(
                styleEnumToText(style),
                overflow: TextOverflow.ellipsis, // Uzun metinler için...
              ),
            );
          }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedStyle = newValue;
          });
        }
      },
    );
  }

  Widget _buildModelViewer() {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_modelUrl == null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(
            _error ?? '3D model oluşturulamadı.',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    return SizedBox(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ModelViewer(
          backgroundColor: Colors.grey[200]!,
          src: 'file://$_modelUrl',
          alt: widget.field.name,
          ar: true,
          autoRotate: true,
          cameraControls: true,
        ),
      ),
    );
  }
}
