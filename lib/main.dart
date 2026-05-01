import 'dart:ui'; // Import for ImageFilter
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
      final amp = isThinking ? 12.0 : 6.0;
      final deformation = math.sin(animationValue * 2 * math.pi + i) * amp;
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
              alignment: Alignment(-0.8, -0.2 + math.sin(animation.value * math.pi) * 0.2),
              color: const Color(0xFF004D40).withOpacity(0.6),
              size: 400,
            ),
            
            // Luz Ocre Cálido
            _buildNebula(
              alignment: Alignment(0.7, 0.4 + math.cos(animation.value * math.pi) * 0.3),
              color: const Color(0xFF827717).withOpacity(0.4),
              size: 500,
            ),
            
            // Luz Carmesí Oscuro
            _buildNebula(
              alignment: Alignment(0.0, 0.9 + math.sin(animation.value * 1.5) * 0.1),
              color: const Color(0xFF310000).withOpacity(0.7),
              size: 600,
            ),
            
            // Blur Gaussiano de alta intensidad para efecto gaseoso
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
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
            colors: [color, color.withOpacity(0)],
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
  late Animation<double> _rotationCurve;
  late AnimationController _waveController;
  late AnimationController _entryController;
  late Animation<double> _entryScale;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _rotationCurve = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOutSine,
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _entryScale = CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    );

    _entryController.forward();

    // Inicialización de notificaciones locales
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Icono por defecto de Android
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Manejar la interacción con la notificación si es necesario
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    _entryController.dispose();
    _controller.dispose();
    super.dispose();
  }

  final String apiUrl = "http://192.168.1.7:5000/api/v1/ask";
  final String secret = "glyph123";

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'glyph_channel_id', // ID del canal
      'Glyph Responses', // Nombre del canal
      channelDescription: 'Notificaciones de respuestas de Glyph',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails();
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      0, // ID de la notificación
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

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
              _showNotification("Glyph", _lastResponse); // Mostrar notificación
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
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 0.5,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: WaterWavePainter(
                                      _waveController.value,
                                      const Color(0xFF004D40).withOpacity(0.2), // Onda esmeralda sutil
                                    ),
                                  ),
                                ),
                                Text(
                                  _lastResponse,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = true),
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
                                    ? Colors.white.withOpacity(0.85) // Barra clara para texto negro
                                    : Colors.white.withOpacity(0.1),
                                boxShadow: [
                                  if (!_isExpanded)
                                    BoxShadow(
                                      color: Colors.white.withAlpha(15),
                                      blurRadius: 15,
                                      spreadRadius: pulse * 2,
                                    ),
                                  if (_isExpanded)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
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
                                        child: CustomPaint(
                                          painter: WaterWavePainter(
                                            _waveController.value,
                                            Colors.black.withOpacity(0.05),
                                          ),
                                        ),
                                      ),
                                    if (!_isExpanded)
                                      Center(
                                        child: CustomPaint(
                                          painter: MorphingBlobPainter(
                                            _waveController.value,
                                          _isThinking ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.2),
                                          _isThinking,
                                          ),
                                          size: const Size(40, 40),
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
                                              color: Colors.black, // Letras negras elegantes
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: "",
                                              border: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                            ),
                                            onSubmitted: (_) => _handleSend(),
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
