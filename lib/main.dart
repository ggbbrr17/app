import 'dart:ui'; // Import for ImageFilter
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math;

void main() => runApp(const GlyphMobileApp());

class GlyphMobileApp extends StatelessWidget {
  const GlyphMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glyph',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        primaryColor: Colors.black,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
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
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();

    // Creamos una forma de gota líquida usando 8 puntos de control
    const int points = 8;
    for (int i = 0; i <= points; i++) {
      final angle = (i * 2 * math.pi) / points;
      // La deformación varía según el seno del tiempo y el ángulo del punto
      final amp = isThinking ? 18.0 : 6.0;
      // Aceleramos la oscilación cuando está pensando para dar feedback de actividad
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
    
    // Suavizamos la gota con un ligero desenfoque interno
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MorphingBlobPainter oldDelegate) => true;
}

class WaterWavePainter extends CustomPainter {
  final double waveValue;
  final Color color;

  WaterWavePainter(this.waveValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final yOffset = size.height * 0.7; // El agua llena la parte inferior de la barra
    final waveHeight = 6.0;

    path.moveTo(0, size.height);
    path.lineTo(0, yOffset);
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        yOffset + math.sin((i / size.width * 2 * math.pi) + (waveValue * 2 * math.pi)) * waveHeight,
      );
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaterWavePainter oldDelegate) => true;
}

class PixelFieldPainter extends CustomPainter {
  final double t;
  final double intensity; // 0.0 - 1.0
  final int seed;

  PixelFieldPainter(this.t, this.intensity, {this.seed = 1337});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    const int count = 96; // más densidad para efecto gamer
    final palette = [
      Color(0xFF00FF9F), // neon mint
      Color(0xFF00E5FF), // electric cyan
      Color(0xFFFF00D6), // neon magenta
      Color(0xFF7C4DFF), // violet neon
      Color(0xFF1E88E5), // strong blue
      Color(0xFFFF6D00), // neon orange
    ];

    for (int i = 0; i < count; i++) {
      // deterministic pseudo-random position per pixel
      final ang = (i * 2 * math.pi / count) + (rnd.nextDouble() - 0.5);
      final r = radius * (0.12 + rnd.nextDouble() * 0.78);
      final pos = Offset(center.dx + math.cos(ang) * r, center.dy + math.sin(ang) * r);

      // only draw if inside main circle
      if ((pos - center).distance > radius) continue;

      final phase = t * 2 * math.pi + i * 0.23;
      final alpha = ((math.sin(phase * 1.6) * 0.5 + 0.5) * intensity * 255).clamp(0, 255).toInt();
      if (alpha < 8) continue;

      // neon cycling: mezcla entre dos colores de la paleta para efecto vibrante
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
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Fondo Negro Base
            Container(color: const Color(0xFF000000)),
            
            // Luz Verde Esmeralda
            _buildNebula(
              alignment: Alignment(-0.8, -0.2 + math.sin(animation.value * 2 * math.pi) * 0.2), // cite: 1
              color: Color(0xFF004D40).withAlpha((0.6 * 255).round()),
              size: 400,
            ),
            
            // Luz Ocre Cálido
            _buildNebula(
              alignment: Alignment(0.7, 0.4 + math.cos(animation.value * 2 * math.pi) * 0.3), // cite: 1
              color: Color(0xFF827717).withAlpha((0.4 * 255).round()),
              size: 500,
            ),
            
            // Luz Carmesí Oscuro
            _buildNebula(
              alignment: Alignment(0.0, 0.9 + math.sin(animation.value * 2 * math.pi) * 0.1), // cite: 1
              color: Color(0xFF310000).withAlpha((0.7 * 255).round()),
              size: 600,
            ),
            
            // Blur Gaussiano de alta intensidad para efecto gaseoso
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), // Reducido ligeramente para mejor rendimiento en iPhone
              child: Container(color: Colors.transparent),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNebula({required Alignment alignment, required Color color, required double size}) {
    return Align(
      alignment: alignment,
            child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withAlpha(0)],
          ),
        ),
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
  late FlutterTts flutterTts;
  bool _barDisintegrating = false;
  bool _bubbleAlive = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Más lento para efecto aurora
    )..repeat();

    _disintegrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _entryScale = CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    );

    _entryController.forward();

    // TTS
    flutterTts = FlutterTts();
    Future.delayed(const Duration(milliseconds: 300), () async {
      await flutterTts.setLanguage("es-ES");
      await flutterTts.setSpeechRate(0.45);
      await flutterTts.speak("Bienvenido Gabriel");
    });
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    ).catchError((e) {
      debugPrint("Notification init error: $e");
      return false;
    });
  }

  Future<void> _showNotification(String title, String body) async {
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
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

  final String apiUrl = "http://192.168.1.7:5000/api/v1/ask";
  final String secret = "glyph123";

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Cerrar el teclado inmediatamente para evitar que tape la respuesta
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
          .post(
            Uri.parse(apiUrl),
            headers: {
              "Content-Type": "application/json",
              "X-Glyph-Secret": secret,
            },
            body: jsonEncode({"question": text}),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          if (data.containsKey('error')) {
            _showError(data['error'] ?? "Error desconocido del servidor");
          } else {
            setState(() {
              _messages.add({
                "role": "glyph",
                "text": data['message'] ?? "Sin respuesta de texto.",
                "model": data['active_model'] ?? "GLYPH",
              });
              _lastResponse = data['message'] ?? "";
              _showNotification("Glyph", _lastResponse);
            });
          }
        } else {
          _showError("Respuesta vacía del servidor");
        }
      } else {
        _showError("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Enlace fallido: $e");
    } finally {
      setState(() => _isThinking = false);
    }
  }

  void _showError(String err) {
    setState(() {
      _messages.add({"role": "glyph", "text": "⚠️ $err"});
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Mesh Gradient Background
          MeshGradientBackground(animation: _waveController),
          
          
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_lastResponse.isNotEmpty && !_isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 30,
                      left: 30,
                      right: 30,
                    ),
                    child: AnimatedOpacity(
                      opacity: _isThinking ? 0.4 : 1.0,
                      duration: const Duration(milliseconds: 600),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha((0.06 * 255).round()),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withAlpha((0.06 * 255).round()),
                                width: 0.5,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(child: Container()),
                                Text(
                                  _lastResponse,
                                  textAlign: TextAlign.center,
                                    style: TextStyle(
                                    color: Colors.white.withAlpha((0.9 * 255).round()),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.5,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 12,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = true),
                  onDoubleTap: () => setState(() => _bubbleAlive = !_bubbleAlive),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _pulseController,
                      _rotationController,
                      _waveController,
                      _entryController,
                    ]),
                    builder: (context, child) {
                      double pulse = _pulseController.value;
                      double scale = _isExpanded
                          ? 1.0
                          : (1.0 + (pulse * 0.08)) * _entryScale.value;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: scale,
                            child: AnimatedBuilder(
                              animation: _disintegrateController,
                              builder: (context, child) {
                                final v = _disintegrateController.value;
                                return Opacity(
                                  opacity: 1.0 - v,
                                  child: Transform.scale(
                                    scale: 1.0 - 0.65 * v,
                                    child: child,
                                  ),
                                );
                              },
                              child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutBack,
                              width: _isExpanded ? screenWidth * 0.85 : 85,
                              height: _isExpanded ? 60 : 85,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  _isExpanded ? 20 : 42.5,
                                ),
                                    color: _isExpanded
                                      ? Colors.black.withAlpha((0.45 * 255).round())
                                      : Colors.black.withAlpha((0.06 * 255).round()),
                                boxShadow: [
                                  if (!_isExpanded)
                                    BoxShadow(
                                      color: Colors.white.withAlpha(15), // cite: 1
                                      blurRadius: 15,
                                      spreadRadius: pulse * 2,
                                    ),
                                  if (_isExpanded)
                                    BoxShadow(
                                      color: Colors.black.withAlpha((0.1 * 255).round()), // cite: 1
                                      blurRadius: 10,
                                    ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(_isExpanded ? 20 : 42.5),
                                child: Stack(
                                  children: [
                                    if (_isExpanded)
                                      Positioned.fill(
                                        child: Container(),
                                      ),
                                    if (!_isExpanded)
                                      Align(
                                        alignment: Alignment(
                                          math.sin(_rotationController.value * 2 * math.pi) * 0.9,
                                          0.2,
                                        ),
                                        child: SizedBox(
                                          width: 120,
                                          height: 120,
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: CustomPaint(
                                                  painter: MorphingBlobPainter(
                                                    _waveController.value,
                                                    _isThinking
                                                      ? Colors.white.withAlpha((0.5 * 255).round())
                                                      : Colors.white.withAlpha((0.2 * 255).round()),
                                                    _isThinking,
                                                  ),
                                                ),
                                              ),
                                              Positioned.fill(
                                                child: CustomPaint(
                                                  painter: PixelFieldPainter(
                                                    (_pulseController.value + _rotationController.value + _waveController.value) / 3.0,
                                                    (_bubbleAlive ? 1.0 : 0.12) * (_isThinking ? 1.6 : 1.0),
                                                    seed: 1001,
                                                  ),
                                                ),
                                              ),
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
                                            style: const TextStyle(
                                              color: Colors.white, // Letras blancas sobre fondo translucent
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: "",
                                              border: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                            ),
                                            onSubmitted: (_) async {
                                              // play disintegration animation
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
                        ],
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
