import 'package:flutter/material.dart';
import 'dart:math' as math;

class GlobeWidget extends StatefulWidget {
  final String appLanguage;

  const GlobeWidget({Key? key, required this.appLanguage}) : super(key: key);

  @override
  _GlobeWidgetState createState() => _GlobeWidgetState();
}

class _GlobeWidgetState extends State<GlobeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotationX = 0;
  double _rotationY = 0;
  
  final List<Map<String, dynamic>> _countries = [
    {"id": "col", "lat": 4.5709, "lon": -74.2973},
    {"id": "bra", "lat": -14.2350, "lon": -51.9253},
    {"id": "usa", "lat": 37.0902, "lon": -95.7129},
    {"id": "esp", "lat": 40.4637, "lon": -3.7492},
    {"id": "chn", "lat": 35.8617, "lon": 104.1954},
    {"id": "ind", "lat": 20.5937, "lon": 78.9629},
    {"id": "aus", "lat": -25.2744, "lon": 133.7751},
    {"id": "zaf", "lat": -30.5595, "lon": 22.9375},
    {"id": "rus", "lat": 61.5240, "lon": 105.3188},
    {"id": "mex", "lat": 23.6345, "lon": -102.5528},
    {"id": "fra", "lat": 46.2276, "lon": 2.2137},
  ];

  final Map<String, Map<String, String>> _countryLabels = {
    "col": {"Español": "Colombia", "Inglés": "Colombia", "Wayuunaiki": "Koloompia"},
    "bra": {"Español": "Brasil", "Inglés": "Brazil", "Wayuunaiki": "Würaasiir"},
    "usa": {"Español": "EE.UU.", "Inglés": "USA", "Wayuunaiki": "EE.UU."},
    "esp": {"Español": "España", "Inglés": "Spain", "Wayuunaiki": "Epaaña"},
    "chn": {"Español": "China", "Inglés": "China", "Wayuunaiki": "Chiina"},
    "ind": {"Español": "India", "Inglés": "India", "Wayuunaiki": "Iintia"},
    "aus": {"Español": "Australia", "Inglés": "Australia", "Wayuunaiki": "Oustüraalia"},
    "zaf": {"Español": "Sudáfrica", "Inglés": "South Africa", "Wayuunaiki": "Sütaapürika"},
    "rus": {"Español": "Rusia", "Inglés": "Russia", "Wayuunaiki": "Ruusia"},
    "mex": {"Español": "México", "Inglés": "Mexico", "Wayuunaiki": "Mejiko"},
    "fra": {"Español": "Francia", "Inglés": "France", "Wayuunaiki": "Püransia"},
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _controller.addListener(() {
      setState(() {
        _rotationY += 0.005;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotationY += details.delta.dx * 0.01;
          _rotationX += details.delta.dy * 0.01;
        });
      },
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        height: 300,
        child: CustomPaint(
          painter: GlobePainter(
            rotationX: _rotationX,
            rotationY: _rotationY,
            countries: _countries,
            labels: _countryLabels,
            language: widget.appLanguage,
          ),
        ),
      ),
    );
  }
}

class GlobePainter extends CustomPainter {
  final double rotationX;
  final double rotationY;
  final List<Map<String, dynamic>> countries;
  final Map<String, Map<String, String>> labels;
  final String language;

  final List<List<math.Point<double>>> _continents = [
    // South America
    [math.Point(-55, -70), math.Point(-15, -80), math.Point(12, -72), math.Point(10, -50), math.Point(-35, -35), math.Point(-55, -70)],
    // North America
    [math.Point(15, -100), math.Point(20, -115), math.Point(60, -165), math.Point(70, -100), math.Point(45, -50), math.Point(25, -75), math.Point(15, -100)],
    // Africa
    [math.Point(35, 20), math.Point(30, -10), math.Point(5, -10), math.Point(-35, 20), math.Point(-35, 30), math.Point(10, 50), math.Point(35, 35), math.Point(35, 20)],
    // Eurasia
    [math.Point(10, 120), math.Point(70, 170), math.Point(75, 10), math.Point(40, -10), math.Point(30, 30), math.Point(10, 60), math.Point(10, 120)],
    // Australia
    [math.Point(-10, 115), math.Point(-40, 115), math.Point(-40, 150), math.Point(-10, 150), math.Point(-10, 115)],
  ];

  GlobePainter({
    required this.rotationX,
    required this.rotationY,
    required this.countries,
    required this.labels,
    required this.language,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width < size.height ? size.width * 0.4 : size.height * 0.4;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint bgPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, borderPaint);

    for (int i = 0; i < 12; i++) {
      double angle = i * math.pi / 6;
      Path path = Path();
      for (double theta = -math.pi / 2; theta <= math.pi / 2; theta += 0.1) {
        var p = _project(radius, angle, theta);
        if (theta == -math.pi / 2) {
          path.moveTo(center.dx + p.dx, center.dy + p.dy);
        } else {
          path.lineTo(center.dx + p.dx, center.dy + p.dy);
        }
      }
      canvas.drawPath(path, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.1)..style = PaintingStyle.stroke);
      
      if (i > 0 && i < 6) {
        double latAngle = (i - 3) * math.pi / 6;
        Path latPath = Path();
        bool first = true;
        for (double phi = 0; phi <= 2 * math.pi; phi += 0.1) {
           var p = _project(radius, phi, latAngle);
           if (p.z > 0) {
              if (first) {
                 latPath.moveTo(center.dx + p.dx, center.dy + p.dy);
                 first = false;
              } else {
                 latPath.lineTo(center.dx + p.dx, center.dy + p.dy);
              }
           } else {
              first = true;
           }
        }
        canvas.drawPath(latPath, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.1)..style = PaintingStyle.stroke);
      }
    }

    // Draw continents
    final continentPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var continent in _continents) {
      Path path = Path();
      bool first = true;
      for (var point in continent) {
        double lat = point.x * math.pi / 180.0;
        double lon = point.y * math.pi / 180.0;
        var p = _project(radius, lon, lat);
        if (p.z > -radius * 0.2) { // Show slightly beyond front face
          if (first) {
            path.moveTo(center.dx + p.dx, center.dy + p.dy);
            first = false;
          } else {
            path.lineTo(center.dx + p.dx, center.dy + p.dy);
          }
        } else {
          first = true;
        }
      }
      canvas.drawPath(path, continentPaint);
    }

    for (var country in countries) {
      double lat = country['lat'] * math.pi / 180.0;
      double lon = country['lon'] * math.pi / 180.0;
      var p = _project(radius, lon, lat);

      if (p.z > 0) {
        Path landPath = Path();
        for (int j = 0; j < 6; j++) {
           double angle = j * math.pi / 3;
           double landSize = 12.0; // Size of the "country" landmass
           if (j == 0) {
             landPath.moveTo(center.dx + p.dx + math.cos(angle)*landSize, center.dy + p.dy + math.sin(angle)*landSize);
           } else {
             landPath.lineTo(center.dx + p.dx + math.cos(angle)*landSize, center.dy + p.dy + math.sin(angle)*landSize);
           }
        }
        landPath.close();
        
        canvas.drawPath(landPath, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.25)..style = PaintingStyle.fill);
        canvas.drawPath(landPath, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth=1);

        canvas.drawCircle(
          Offset(center.dx + p.dx, center.dy + p.dy), 
          3, 
          Paint()..color = Colors.white
        );

        String name = labels[country['id']]?[language] ?? labels[country['id']]?["Español"] ?? "";
        final textSpan = TextSpan(
          text: name,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, shadows: [
            Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 2),
          ]),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas, 
          Offset(center.dx + p.dx + 6, center.dy + p.dy - 6)
        );
      }
    }
  }

  ({double dx, double dy, double z}) _project(double r, double lon, double lat) {
    double x = r * math.cos(lat) * math.cos(lon);
    double y = r * math.sin(lat);
    double z = r * math.cos(lat) * math.sin(lon);

    double x1 = x * math.cos(rotationY) - z * math.sin(rotationY);
    double z1 = x * math.sin(rotationY) + z * math.cos(rotationY);

    double y2 = y * math.cos(rotationX) - z1 * math.sin(rotationX);
    double z2 = y * math.sin(rotationX) + z1 * math.cos(rotationX);

    return (dx: x1, dy: -y2, z: z2);
  }

  @override
  bool shouldRepaint(covariant GlobePainter old) => true;
}
