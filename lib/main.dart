import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math' as math;

void main() => runApp(const GlyphMobileApp());

class GlyphMobileApp extends StatelessWidget {
  const GlyphMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glyph',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: false),
      home: const ChatScreen(),
    );
  }
}

class MorphingBlobPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final bool isThinking;

  MorphingBlobPainter(this.animationValue, this.color, this.isThinking);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();

    const int points = 8;
    for (int i = 0; i <= points; i++) {
      final angle = (i * 2 * math.pi) / points;
      final amp = isThinking ? 18.0 : 6.0;
      final speedMultiplier = isThinking ? 2.0 : 1.0;
      final deformation = math.sin(animationValue * 2 * math.pi * speedMultiplier + i) * amp;
      final currentRadius = radius + deformation;
      final x = center.dx + math.cos(angle) * currentRadius;
      final y = center.dy + math.sin(angle) * currentRadius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MorphingBlobPainter oldDelegate) => true;
}

class PixelFieldPainter extends CustomPainter {
  final double t;
  final double intensity;
  final int seed;

  PixelFieldPainter(this.t, this.intensity, {this.seed = 1337});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final palette = [
      const Color(0xFF00FF9F), // Cyan futurista
      const Color(0xFF00E5FF), // Azul neón
      const Color(0xFF7C4DFF), // Violeta profundo
    ];

    const double spacing = 7.0; // Espaciado uniforme para el grid
    const double pixelSize = 3.5;

    for (double x = -radius; x <= radius; x += spacing) {
      for (double y = -radius; y <= radius; y += spacing) {
        final pos = Offset(center.dx + x, center.dy + y);
        final dist = (pos - center).distance;
        
        if (dist > radius) continue;

        // Efecto de onda coordinada desde el centro
        final normalizedDist = dist / radius;
        final wave = math.sin(t * 2 * math.pi - normalizedDist * 3.5);
        final alphaFactor = ((wave * 0.5 + 0.5) * intensity).clamp(0.0, 1.0);
        
        if (alphaFactor < 0.1) continue;

        // Selección de color basada en posición para degradado uniforme
        final colorIndex = ((x + radius) + (y + radius)).toInt();
        final color = palette[colorIndex % palette.length].withValues(alpha: alphaFactor);

        // Dibujar píxel con escala basada en la intensidad de la onda
        final currentPixelSize = pixelSize * (0.5 + alphaFactor * 0.5);
        canvas.drawRect(
          Rect.fromCenter(center: pos, width: currentPixelSize, height: currentPixelSize),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelFieldPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.intensity != intensity || oldDelegate.seed != seed;
  }
}

class MeshGradientBackground extends StatelessWidget {
  final Animation<double> animation;
  const MeshGradientBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          // movimiento ralentizado y orgánico
          final a = animation.value;
          return Stack(
            children: [
              // Fondo Negro Azabache
              Container(color: const Color(0xFF000000)),

              // Luz Verde Esmeralda (grande, a la izquierda)
              Align(
                alignment: Alignment(
                  math.sin(a * 2 * math.pi), 
                  math.cos(a * 2 * math.pi * 0.7),
                ),
                child: Container(
                  width: 700,
                  height: 700,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF004D40).withValues(alpha: 0.65), const Color(0xFF004D40).withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),

              // Luz Ocre Cálido (derecha)
              Align(
                alignment: Alignment(
                  math.cos(a * 2 * math.pi * 0.8), 
                  math.sin(a * 2 * math.pi * 1.2),
                ),
                child: Container(
                  width: 900,
                  height: 900,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF827717).withValues(alpha: 0.45), const Color(0xFF827717).withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),

              // Luz Carmesí Oscuro (inferior-centro)
              Align(
                alignment: Alignment(
                  math.sin(a * 2 * math.pi * 1.5), 
                  math.cos(a * 2 * math.pi * 0.9),
                ),
                child: Container(
                  width: 1000,
                  height: 1000,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF310000).withValues(alpha: 0.7), const Color(0xFF310000).withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),

              // Blur Gaussiano intenso para desenfocar las luces y obtener apariencia gaseosa
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ],
          );
        },
      ),
    );
  }

}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isThinking = false;
  bool _isExpanded = false;
  String _lastResponse = "";
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  late AnimationController _disintegrateController;
  late AnimationController _entryController;
  late Animation<double> _entryScale;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _bubbleAlive = true;

  final String apiUrl = "https://service-cv3f.onrender.com/api/v1/ask";
  final String secret = "glyph123";

  @override
  void initState() {
    super.initState();
    _initializeNotifications();

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _disintegrateController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _entryScale = CurvedAnimation(parent: _entryController, curve: Curves.elasticOut);
    _entryController.forward();
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(iOS: initializationSettingsDarwin);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings).catchError((e) {
      debugPrint('Notification init error: $e');
      return false;
    });
  }

  Future<void> _showNotification(String title, String body) async {
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
    const NotificationDetails platformDetails = NotificationDetails(iOS: iosDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    _disintegrateController.dispose();
    _entryController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    _controller.clear();
    setState(() {
      _isExpanded = false;
      _lastResponse = "";
      _messages.add({"role": "user", "text": text});
      _isThinking = true;
    });

    try {
      final response = await http
          .post(Uri.parse(apiUrl), headers: {"Content-Type": "application/json", "X-Glyph-Secret": secret}, body: jsonEncode({"question": text})).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data.containsKey('error')) {
          _showError(data['error'] ?? 'Error servidor');
        } else {
          setState(() {
            _messages.add({"role": "glyph", "text": data['message'] ?? "Sin respuesta."});
            _lastResponse = data['message'] ?? "";
            _showNotification('Glyph', _lastResponse);
          });
        }
      } else {
        _showError('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Enlace fallido: $e');
    } finally {
      setState(() => _isThinking = false);
    }
  }

  void _showError(String err) {
    setState(() {
      _messages.add({"role": "glyph", "text": '⚠️ $err'});
      _lastResponse = 'Error: $err'; // Ahora el usuario podrá verlo en la burbuja
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          MeshGradientBackground(animation: _waveController),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_lastResponse.isNotEmpty && !_isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30, left: 30, right: 30),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5)),
                          child: Text(
                            _lastResponse,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 17, fontWeight: FontWeight.w400),
                          ),
                        ),
                      ),
                    ),
                  ),

                GestureDetector(
                  onTap: () => setState(() => _isExpanded = true),
                  onDoubleTap: () => setState(() => _bubbleAlive = !_bubbleAlive),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pulseController, _rotationController, _waveController, _entryController, _disintegrateController]),
                    builder: (context, _) {
                      final pulse = _pulseController.value;
                      final scale = _isExpanded ? 1.0 : (1.0 + (pulse * 0.08)) * _entryScale.value;
                      final dis = _disintegrateController.value;
                      return Transform.scale(
                        scale: scale * (1.0 - 0.65 * dis),
                        child: Opacity(
                          opacity: 1.0 - dis,
                          child: Container(
                            width: _isExpanded ? screenWidth * 0.92 : 120,
                            height: _isExpanded ? 75 : 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(_isExpanded ? 24 : 60),
                                color: _isExpanded ? Colors.black.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.06),
                              boxShadow: [
                                  if (!_isExpanded) BoxShadow(color: Colors.white.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: pulse * 3),
                                  if (_isExpanded) BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(_isExpanded ? 24 : 60),
                              child: Stack(
                                children: [
                                  if (!_isExpanded)
                                    Align(
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: Stack(
                                          children: [
                                            Positioned.fill(child: CustomPaint(painter: MorphingBlobPainter(_waveController.value, _isThinking ? Colors.white.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.2), _isThinking))),
                                            Positioned.fill(child: CustomPaint(painter: PixelFieldPainter((_pulseController.value + _rotationController.value + _waveController.value) / 3.0, (_bubbleAlive ? 1.0 : 0.12) * (_isThinking ? 1.6 : 1.0), seed: 1001))),
                                          ],
                                        ),
                                      ),
                                    ),

                                  if (_isExpanded)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Center(
                                        child: TextField(
                                          controller: _controller,
                                          autofocus: true,
                                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                                          decoration: const InputDecoration(hintText: '', border: InputBorder.none, focusedBorder: InputBorder.none, enabledBorder: InputBorder.none),
                                          onSubmitted: (_) async {
                                            await _disintegrateController.forward();
                                            await _handleSend();
                                            _disintegrateController.reset();
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
