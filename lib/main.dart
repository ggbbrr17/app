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
    final rnd = math.Random(seed);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    const int count = 96;
    final palette = [
      Color(0xFF00FF9F),
      Color(0xFF00E5FF),
      Color(0xFFFF00D6),
      Color(0xFF7C4DFF),
      Color(0xFF1E88E5),
      Color(0xFFFF6D00),
    ];

    for (int i = 0; i < count; i++) {
      final ang = (i * 2 * math.pi / count) + (rnd.nextDouble() - 0.5);
      final r = radius * (0.12 + rnd.nextDouble() * 0.78);
      final pos = Offset(center.dx + math.cos(ang) * r, center.dy + math.sin(ang) * r);
      if ((pos - center).distance > radius) continue;

      final phase = t * 2 * math.pi + i * 0.23;
      final alpha = ((math.sin(phase * 1.6) * 0.5 + 0.5) * intensity * 255).clamp(0, 255).toInt();
      if (alpha < 8) continue;

      final base = palette[i % palette.length];
      final alt = palette[(i + 3) % palette.length];
      final mix = (math.sin(phase * 2.2 + rnd.nextDouble()) * 0.5 + 0.5).clamp(0.0, 1.0);
      final color = Color.lerp(base, alt, mix)!.withAlpha(alpha);

      final sizePx = 3.0 + (rnd.nextDouble() * 5.0);
      final rect = Rect.fromCenter(center: pos, width: sizePx, height: sizePx);
      final paint = Paint()..color = color;
      canvas.drawRect(rect, paint);
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
                alignment: Alignment(-0.85 + math.sin(a * 2 * math.pi) * 0.25, -0.25 + math.cos(a * 2 * math.pi) * 0.12),
                child: Container(
                  width: 700,
                  height: 700,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF004D40).withAlpha((0.65 * 255).round()), Color(0xFF004D40).withAlpha(0)],
                    ),
                  ),
                ),
              ),

              // Luz Ocre Cálido (derecha)
              Align(
                alignment: Alignment(0.75 + math.cos(a * 2 * math.pi * 0.9) * 0.18, 0.35 + math.sin(a * 2 * math.pi * 0.7) * 0.12),
                child: Container(
                  width: 900,
                  height: 900,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF827717).withAlpha((0.45 * 255).round()), Color(0xFF827717).withAlpha(0)],
                    ),
                  ),
                ),
              ),

              // Luz Carmesí Oscuro (inferior-centro)
              Align(
                alignment: Alignment(0.0 + math.sin(a * 2 * math.pi * 0.6) * 0.08, 0.8 + math.cos(a * 2 * math.pi * 0.5) * 0.12),
                child: Container(
                  width: 1000,
                  height: 1000,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF310000).withAlpha((0.7 * 255).round()), Color(0xFF310000).withAlpha(0)],
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

  final String apiUrl = "http://192.168.1.7:5000/api/v1/ask";
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
    setState(() => _messages.add({"role": "glyph", "text": '⚠️ $err'}));
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
                          decoration: BoxDecoration(color: Colors.black.withAlpha((0.06 * 255).round()), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withAlpha((0.06 * 255).round()), width: 0.5)),
                          child: Text(
                            _lastResponse,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withAlpha((0.9 * 255).round()), fontSize: 17, fontWeight: FontWeight.w400),
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
                            width: _isExpanded ? screenWidth * 0.85 : 85,
                            height: _isExpanded ? 60 : 85,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(_isExpanded ? 20 : 42.5), color: _isExpanded ? Colors.black.withAlpha((0.45 * 255).round()) : Colors.black.withAlpha((0.06 * 255).round()), boxShadow: [if (!_isExpanded) BoxShadow(color: Colors.white.withAlpha(15), blurRadius: 15, spreadRadius: pulse * 2), if (_isExpanded) BoxShadow(color: Colors.black.withAlpha((0.1 * 255).round()), blurRadius: 10)]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(_isExpanded ? 20 : 42.5),
                              child: Stack(
                                children: [
                                  if (!_isExpanded)
                                    Align(
                                      alignment: Alignment(math.sin(_rotationController.value * 2 * math.pi) * 0.9, 0.2),
                                      child: SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: Stack(
                                          children: [
                                            Positioned.fill(child: CustomPaint(painter: MorphingBlobPainter(_waveController.value, _isThinking ? Colors.white.withAlpha((0.5 * 255).round()) : Colors.white.withAlpha((0.2 * 255).round()), _isThinking))),
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
