import 'dart:io';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart' hide ModelManager;

import 'anthro_service.dart';
import 'anthro_chart_widget.dart';
import 'database_helper.dart';
import 'model_manager.dart';
import 'wayuu_dictionary.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wake_on_lan/wake_on_lan.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          "🚨 ERROR:\n${details.exception}",
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  };

  runZonedGuarded(() {
    runApp(const GlyphMobileApp());
  }, (error, stack) {
    debugPrint("🚨 ERROR ZONED: $error");
  });
}

class GlyphMobileApp extends StatelessWidget {
  const GlyphMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glyph',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        textTheme: ThemeData.dark(useMaterial3: true).textTheme.apply(
              fontFamily: 'serif',
            ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── SPLASH SCREEN ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    Future.delayed(const Duration(milliseconds: 1800), () async {
      await _ctrl.forward();
      if (mounted)
        Navigator.of(context).pushReplacement(PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ChatScreen(),
            transitionDuration: Duration.zero));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: CustomPaint(
            painter: FragmentedTrianglePainter(
                animationValue: 0.0,
                isThinking: false,
                isRecording: false,
                opacity: 0.18),
            size: const Size(120, 120),
          ),
        ),
      ),
    );
  }
}

// ─── TRIÁNGULO FRAGMENTADO ─────────────────────────────────────────────────────
class FragmentedTrianglePainter extends CustomPainter {
  final double animationValue;
  final bool isThinking;
  final bool isRecording;
  final double opacity;

  FragmentedTrianglePainter({
    required this.animationValue,
    this.isThinking = false,
    this.isRecording = false,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Triángulo (padding ajustable para el tamaño interno)
    double padding = size.width * 0.20; // Un poco más grande
    Offset v1 = Offset(size.width / 2, padding);
    Offset v2 = Offset(padding, size.height - padding);
    Offset v3 = Offset(size.width - padding, size.height - padding);

    Path trianglePath = Path()
      ..moveTo(v1.dx, v1.dy)
      ..lineTo(v2.dx, v2.dy)
      ..lineTo(v3.dx, v3.dy)
      ..close();

    if (isRecording) {
      // Animación minimalista para grabación
      double scale = 1.0 + math.sin(animationValue * math.pi * 40) * 0.08;
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(scale);
      canvas.translate(-size.width / 2, -size.height / 2);

      final recPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.8 * opacity)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(trianglePath, recPaint);
      canvas.restore();
    } else if (isThinking) {
      // El triángulo está quieto, pero las líneas cambian de posición a lo largo del perímetro
      for (PathMetric measure in trianglePath.computeMetrics()) {
        double length = measure.length;
        double segmentLength = length / 3.0; // 3 lados
        double gap = length * 0.2; // espacio entre líneas
        double lineLength = segmentLength - gap;

        // Movimiento continuo a lo largo del perímetro
        double offset = (animationValue * 10 * length) % length;

        for (int i = 0; i < 3; i++) {
          double start = (offset + i * segmentLength) % length;
          double end = start + lineLength;
          if (end > length) {
            Path extract1 = measure.extractPath(start, length);
            Path extract2 = measure.extractPath(0, end - length);
            canvas.drawPath(extract1, paint);
            canvas.drawPath(extract2, paint);
          } else {
            Path extract = measure.extractPath(start, end);
            canvas.drawPath(extract, paint);
          }
        }
      }
    } else {
      // Estado normal: Triángulo extendido
      canvas.drawPath(trianglePath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FragmentedTrianglePainter old) => true;
}

class AnimatedHamburger extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;
  const AnimatedHamburger(
      {super.key, required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: isOpen ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutBack,
        builder: (context, t, _) {
          return SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top bar — moves to center and rotates +45° forming X
                Positioned(
                  top: lerpDouble(14.0, 23.0, t),
                  child: Transform.rotate(
                    angle: t * math.pi * 0.25,
                    child: Transform.scale(
                      scale: 1.0 + (t * 0.1),
                      child: Container(
                        width: 26, height: 2.5,
                        decoration: BoxDecoration(
                          color: Color.lerp(Colors.white, Colors.cyanAccent, t),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                // Middle bar — fades out
                Opacity(
                  opacity: (1.0 - t * 2).clamp(0.0, 1.0),
                  child: Container(
                    width: 16, height: 2.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Bottom bar — moves to center and rotates -45°
                Positioned(
                  bottom: lerpDouble(14.0, 23.0, t),
                  child: Transform.rotate(
                    angle: -t * math.pi * 0.25,
                    child: Transform.scale(
                      scale: 1.0 + (t * 0.1),
                      child: Container(
                        width: 26, height: 2.5,
                        decoration: BoxDecoration(
                          color: Color.lerp(Colors.white, Colors.cyanAccent, t),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MeshGradientBackground extends StatelessWidget {
  final Animation<double> animation;
  const MeshGradientBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value * 2 * math.pi;
        return Container(
          decoration: const BoxDecoration(color: Color(0xFF020204)),
          child: Stack(
            children: [
              _buildAurora(context, const Color(0xFF00E5FF), 0.1, 0.2, t, 1.4),
              _buildAurora(
                  context, const Color(0xFFD4FF00), 0.9, 0.5, t + 2.0, 1.6),
              _buildAurora(
                  context, const Color(0xFF9C27B0), 0.4, 0.8, t + 4.0, 1.5),
              // Reflejo Acuático
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.3,
                child: Opacity(
                  opacity: 0.3,
                  child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                            Colors.transparent,
                            Colors.cyanAccent.withValues(alpha: 0.1)
                          ])))),
                ),
              ),
              BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child:
                      Container(color: Colors.black.withValues(alpha: 0.45))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAurora(BuildContext context, Color color, double x, double y,
      double t, double sizeMult) {
    final size = MediaQuery.of(context).size;
    final dx = math.sin(t) * 150;
    final dy = math.cos(t) * 150;
    return Positioned(
      left: (x * size.width) + dx - (250 * sizeMult),
      top: (y * size.height) + dy - (250 * sizeMult),
      child: Container(
        width: 500 * sizeMult,
        height: 500 * sizeMult,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.25), Colors.transparent],
                stops: const [0.2, 1.0])),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, dynamic>> _messages = [];
  bool _isThinking = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController,
      _waveController,
      _menuAnimationController;
  late Animation<Offset> _menuOffsetAnimation;
  late fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  AppLifecycleState _notificationState = AppLifecycleState.resumed;
  bool _isMenuOpen = false,
      _isRecording = false,
      _showTextField = false,
      _showHistory = false;
  Timer? _notificationPollingTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListeningSTT = false;
  String? _pendingImageBase64, _pendingImageName;
  final List<List<Map<String, dynamic>>> _chatSessions = [];

  bool _isOfflineMode = false;
  InferenceModel? _gemmaModel;
  InferenceChat? _gemmaChat;
  bool _isTutorMode = false;
  String _tutorLanguage = "Bilingüe";
  String? _lastManualDiagnosis;
  int _offlineInteractionCount = 0;
  String _appLanguage = "";
  bool _isHealthProfessional = true;
  bool _isRiskAssessmentMode = false;
  String? _pendingRiskName;
  bool _isInteractiveAnthroFlow = false;
  String? _interactiveGender;
  DateTime? _interactiveDob;
  double? _interactiveWeight;
  double? _interactiveHeight;
  String? _interactiveName;
  bool _isTranslatorSubMenuOpen = false;
  bool _isTranslatorAudioMode = false;
  final WayuuDictionary _wayuuDict = WayuuDictionary();
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  final StreamController<double> _downloadProgressController =
      StreamController<double>.broadcast();
  Stream<double> get _downloadProgressStream =>
      _downloadProgressController.stream;

  final String apiUrl = "https://service-cv3f.onrender.com/api/v1/ask";
  final String notificationUrl =
      "https://service-cv3f.onrender.com/api/v1/notifications";
  final String secret = "glyph123";
  int? _currentSessionId;
  List<int> _sessionIds = [];

  @override
  void initState() {
    super.initState();
    _initTts();
    _wayuuDict.init();
    WidgetsBinding.instance.addObserver(this);
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _waveController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();
    _menuAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _menuOffsetAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _menuAnimationController, curve: Curves.easeOut));
    _initializeNotifications();
    _startNotificationPolling();

    // First load the model, THEN show the interactive greeting
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPersistedHistory();
      if (mounted) _loadGemmaModel();
    });
  }

  Future<void> _loadPersistedHistory() async {
    try {
      final sessions = await DatabaseHelper.instance.getSessions();
      if (sessions.isEmpty) {
        // New user: just create the session. Language selector shown after model loads.
        _currentSessionId = await DatabaseHelper.instance.createSession();
      } else {
        _currentSessionId = sessions.first['id'];
        final msgs =
            await DatabaseHelper.instance.getSessionMessages(_currentSessionId!);
        if (!mounted) return;
        setState(() {
          _messages.clear();
          _messages.addAll(msgs.map((m) {
            dynamic data;
            try {
              data = m['data'] != null ? jsonDecode(m['data']) : null;
            } catch (_) {
              data = null;
            }
            return {
              "role": m['role'],
              "text": m['text'],
              "type": m['type'],
              "data": data,
              "isThought": m['isThought'] == 1,
            };
          }));
        });

        _chatSessions.clear();
        _sessionIds.clear();
        for (var session in sessions) {
          _sessionIds.add(session['id']);
          final sMsgs =
              await DatabaseHelper.instance.getSessionMessages(session['id']);
          _chatSessions.add(sMsgs
              .map((m) {
                dynamic data;
                try {
                  data = m['data'] != null ? jsonDecode(m['data']) : null;
                } catch (_) {
                  data = null;
                }
                return {
                  "role": m['role'],
                  "text": m['text'],
                  "type": m['type'],
                  "data": data,
                  "isThought": m['isThought'] == 1,
                };
              })
              .toList());
        }
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
    if (mounted) _scrollToBottom();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _startNotificationPolling() {
    _notificationPollingTimer = Timer.periodic(
        const Duration(seconds: 15), (timer) => _checkForNotifications());
  }

  Future<void> _checkForNotifications() async {
    try {
      final r = await http
          .get(Uri.parse(notificationUrl), headers: {"X-Glyph-Secret": secret});
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        for (var note in (data['notifications'] ?? [])) {
          _addMessage({
            "role": "glyph",
            "text": note['message'] ?? "",
            "isThought": note['type'] == "autonomous_thought"
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = fln.FlutterLocalNotificationsPlugin();
    var initializationSettings = fln.InitializationSettings(
        android: fln.AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: fln.DarwinInitializationSettings());
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    var notificationDetails =
        fln.NotificationDetails(iOS: fln.DarwinNotificationDetails());
    await flutterLocalNotificationsPlugin.show(
        0, title, body, notificationDetails);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _notificationPollingTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _menuAnimationController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _flutterTts.stop();
    _downloadProgressController.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients)
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _addMessage(Map<String, dynamic> msg) {
    if (!mounted) return;
    setState(() {
      _messages.add(msg);
    });
    if (_currentSessionId != null) {
      DatabaseHelper.instance.insertMessage(_currentSessionId!, msg);
    }
    _scrollToBottom();
  }

  Future<void> _playWaterSound() async {
    try {
      await _audioPlayer.play(AssetSource('water_click.mp3'));
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    try {
      _playWaterSound();
      FilePickerResult? res =
          await FilePicker.platform.pickFiles(type: FileType.image);
      if (res != null && res.files.single.path != null) {
        final bytes = await File(res.files.single.path!).readAsBytes();
        if (!mounted) return;
        setState(() {
          _isMenuOpen = false;
          _showTextField = true;
          _pendingImageBase64 = base64Encode(bytes);
          _pendingImageName = res.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('pickImage error: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? res =
          await FilePicker.platform.pickFiles(type: FileType.any);
      if (res != null && res.files.single.path != null) {
        final bytes = await File(res.files.single.path!).readAsBytes();
        if (!mounted) return;
        setState(() {
          _isMenuOpen = false;
          _menuAnimationController.reverse();
          _showTextField = true;
          _pendingImageBase64 = base64Encode(bytes);
          _pendingImageName = res.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('pickFile error: $e');
    }
  }

  Future<void> _startRecording({bool forceSTT = false}) async {
    try {
      if (_isOfflineMode || forceSTT) {
        bool available = false;
        try { available = await _speech.initialize(); } catch (_) {}
        if (available) {
          if (!mounted) return;
          setState(() {
            _isRecording = true;
            _isListeningSTT = true;
          });
          _speech.listen(
            onResult: (result) {
              if (mounted) {
                setState(() {
                  _controller.text = result.recognizedWords;
                });
              }
            },
            localeId: _appLanguage == "Inglés" ? "en_US" : "es_CO",
          );
        } else {
          _addMessage({"role": "glyph", "text": "Error: El reconocimiento de voz offline no está disponible en este dispositivo."});
        }
        return;
      }

      if (await _audioRecorder.hasPermission()) {
        final path = p.join((await getTemporaryDirectory()).path,
            'audio_${DateTime.now().ms}.m4a');
        await _audioRecorder.start(const RecordConfig(), path: path);
        if (!mounted) return;
        setState(() => _isRecording = true);
      }
    } catch (e) {
      if (!mounted) return;
      _addMessage({"role": "glyph", "text": "Error al iniciar grabación: $e"});
      setState(() {
        _isRecording = false;
        _isListeningSTT = false;
        _isTranslatorAudioMode = false;
      });
    }
  }

  Future<String?> _stopRecording({bool autoSend = true}) async {
    try {
      if (_isOfflineMode || _isListeningSTT) {
        if (_isListeningSTT) {
          try { await _speech.stop(); } catch (_) {}
          // Dar un breve momento para que llegue el último onResult de STT
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) setState(() {
            _isRecording = false;
            _isListeningSTT = false;
          });
          if (autoSend && _controller.text.isNotEmpty) {
            _handleSend();
          }
        }
        return null;
      }

      final path = await _audioRecorder.stop();
      if (mounted) setState(() => _isRecording = false);
      return path != null ? base64Encode(await File(path).readAsBytes()) : null;
    } catch (e) {
      if (mounted) setState(() {
        _isRecording = false;
        _isListeningSTT = false;
      });
      return null;
    }
  }

  Future<void> _initGemmaChat() async {
    // 1. Limpieza de memoria (Prevenir Out Of Memory en refrescos)
    if (_gemmaChat != null) {
      try { await _gemmaChat!.close(); } catch (_) {}
      _gemmaChat = null;
    }
    if (_gemmaModel != null) {
      try { await _gemmaModel!.close(); } catch (_) {}
      _gemmaModel = null;
    }

    final manager = ModelManager();
    await manager.initializeGemma();

    _gemmaModel = await FlutterGemma.getActiveModel(maxTokens: 1024);
    _gemmaChat = await _gemmaModel!.createChat(
        supportsFunctionCalls: true,
        toolChoice: ToolChoice.auto,
        tools: [
          Tool(
              name: "registrar_medicion_pediatrica",
              description:
                  "IMPORTANT: Use this tool ALWAYS when the user provides pediatric data (name, age, weight, height, gender) to calculate the nutritional diagnosis. Data: Pedro, 12 months, 0kg, 60cm, male.",
              parameters: {
                "type": "object",
                "properties": {
                  "nombre": {
                    "type": "string",
                    "description": "Nombre del niño"
                  },
                  "edad_meses": {
                    "type": "integer",
                    "description": "Edad total en MESES. IMPORTANTE: Si el usuario dice 'años', debes multiplicar por 12. Ejemplo: 5 años = 60 meses, 12 años = 144 meses."
                  },
                  "peso_kg": {
                    "type": "number",
                    "description": "Peso en kilogramos"
                  },
                  "talla_cm": {
                    "type": "number",
                    "description": "Talla total en centímetros. IMPORTANTE: Si el usuario dice 'un metro cuarenta', envía 140. Ejemplo: 1.40m = 140, 60cm = 60."
                  },
                  "genero": {"type": "string", "description": "Género (m o f)"},
                  "muac_cm": {
                    "type": "number",
                    "description":
                        "Perímetro Braquial o MUAC en centímetros (opcional)"
                  }
                },
                "required": [
                  "nombre",
                  "edad_meses",
                  "peso_kg",
                  "talla_cm",
                  "genero"
                ]
              }),
          Tool(
              name: "registrar_medicion_gestante",
              description:
                  "Use this tool when the user provides pregnancy data (name, gestational weeks, weight, height) to calculate the gestational BMI diagnosis.",
              parameters: {
                "type": "object",
                "properties": {
                  "nombre": {
                    "type": "string",
                    "description": "Nombre de la gestante"
                  },
                  "semanas_gestacion": {
                    "type": "integer",
                    "description": "Semanas de gestación (EG)"
                  },
                  "peso_kg": {
                    "type": "number",
                    "description": "Peso actual en kilogramos"
                  },
                  "talla_cm": {
                    "type": "number",
                    "description": "Talla en centímetros"
                  }
                },
                "required": [
                  "nombre",
                  "semanas_gestacion",
                  "peso_kg",
                  "talla_cm"
                ]
              }),
          Tool(
              name: "exportar_base_datos",
              description:
                  "Exporta y descarga la base de datos completa de pacientes pediátricos en formato CSV.",
              parameters: {"type": "object", "properties": {}}),
          Tool(
              name: "traducir_wayuunaiki",
              description:
                  "Traduce texto entre Wayuunaiki y Español usando el diccionario offline integrado. Detecta el idioma automáticamente.",
              parameters: {
                "type": "object",
                "properties": {
                  "texto": {
                    "type": "string",
                    "description": "Texto a traducir"
                  }
                },
                "required": ["texto"]
              }),
          Tool(
              name: "buscar_diccionario_wayuu",
              description:
                  "Busca una palabra en el diccionario Wayuunaiki-Español. Devuelve definición y palabras relacionadas.",
              parameters: {
                "type": "object",
                "properties": {
                  "palabra": {
                    "type": "string",
                    "description": "Palabra a buscar (en Wayuunaiki o Español)"
                  }
                },
                "required": ["palabra"]
              }),
          Tool(
              name: "encender_computadora",
              description:
                  "Enciende la computadora Acer del usuario mediante un paquete Wake-on-LAN (Magic Packet).",
              parameters: {"type": "object", "properties": {}})
        ]);

    await _gemmaChat!.addQuery(Message(
        text:
            "Eres experto en salud pediátrica, agricultura y Wayuunaiki. Usa herramientas para mediciones, traducción y búsqueda. Responde siempre en $_appLanguage. IMPORTANTE: No uses asteriscos (*) en tus respuestas, usa texto plano.",
        isUser: false));
  }

  Future<void> _loadGemmaModel() async {
    setState(() {
      _isMenuOpen = false;
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
    _menuAnimationController.reverse();

    final manager = ModelManager();

    // Si ya está descargado, inicializar directo
    if (await manager.isModelDownloaded()) {
      setState(() => _isThinking = true);
      try {
        await _initGemmaChat();
        setState(() => _isOfflineMode = true);
        // Model ready: show interactive greeting
        _addMessage({
          "role": "glyph",
          "type": "check_animation",
          "text": ""
        });
        await Future.delayed(const Duration(milliseconds: 800));
        _showLanguageSelectorIfNeeded();
      } catch (e) {
        _addMessage({
          "role": "glyph",
          "text":
              "⚠️ El archivo del modelo local no se encontró o está corrupto. Descargando de nuevo..."
        });
      } finally {
        setState(() => _isThinking = false);
        _scrollToBottom();
      }

      if (_isOfflineMode) return;
    }

    // Mostrar diálogo de descarga
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0D0D1A),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Descargando Gemma 4 E2B",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1)),
            content: StatefulBuilder(
              builder: (_, __) => StreamBuilder<double>(
                stream: _downloadProgressStream,
                builder: (_, snap) {
                  final p = snap.data ?? 0.0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "El modelo pesa ~2 GB.\nAsegúrate de tener buena conexión.",
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: p > 0 ? p : null,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.cyanAccent),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                          p > 0
                              ? "${(p * 100).toStringAsFixed(1)}%"
                              : "Iniciando...",
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );

    await manager.downloadModel(
      onProgress: (p) {
        _downloadProgressController.add(p);
      },
      onCompleted: () async {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isThinking = true);
        try {
          await _initGemmaChat();
          setState(() => _isOfflineMode = true);
          _addMessage({
            "role": "glyph",
            "type": "check_animation",
            "text": ""
          });
          await Future.delayed(const Duration(milliseconds: 800));
          _showLanguageSelectorIfNeeded();
        } catch (e) {
          _addMessage({
            "role": "glyph",
            "text": "❌ Error al inicializar el modelo: $e"
          });
          _showLanguageSelectorIfNeeded();
        } finally {
          setState(() => _isThinking = false);
          _scrollToBottom();
        }
      },
      onError: (err) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        _addMessage(
            {"role": "glyph", "text": "❌ Error al descargar el modelo: $err"});
        _scrollToBottom();
      },
    );
  }

  /// Shows the language selector bubble only when the chat is empty
  /// (new session). This is called AFTER the model finishes loading.
  void _showLanguageSelectorIfNeeded() {
    if (!mounted) return;
    final hasContent = _messages.any((m) =>
        m['type'] != 'check_animation' && (m['text'] as String?)?.isNotEmpty == true);
    if (hasContent) return; // Returning user with history — skip
    final langMsg = {
      "role": "glyph",
      "type": "language_selector",
      "text": ""
    };
    if (_currentSessionId != null) {
      DatabaseHelper.instance.insertMessage(_currentSessionId!, langMsg);
    }
    setState(() => _messages.add(langMsg));
    _scrollToBottom();
  }

  Future<void> _sendMultimodalData(
      {String question = "", String? base64Image, String? base64Audio}) async {
    if (!mounted) return;
    setState(() => _isThinking = true);

    String finalQuestion = question;
    if (base64Image != null) {
      // Prompt multimodal reforzado para evitar falsos negativos de imagen
      finalQuestion =
          "CONTEXTO VISUAL: Se ha adjuntado una imagen codificada en este mensaje. " +
          "TAREA: Analiza detalladamente la imagen adjunta. Identifica personas, alimentos, objetos o signos de salud. " +
          "Si es un niño, observa su estado general. Si hay alimentos, describe su valor nutricional. " +
          "INSTRUCCIÓN DE IDIOMA: Responde en el idioma solicitado. \n\n" +
          "PREGUNTA DEL USUARIO: " + question;
    }

    // Lógica de idioma global
    String langInstruction = "";
    if (_appLanguage.isNotEmpty) {
      if (_appLanguage == "Wayuunaiki") {
        langInstruction = "OBLIGATORIO: Responde solo en WAYUUNAIKI. Prohibido español. Glosario: anasü (salud), ayuulii (enfermo), tepichi (niño), eküülü (comida).";
      } else if (_appLanguage == "Español") {
        langInstruction = "Responde en Español.";
      } else if (_appLanguage == "Inglés") {
        langInstruction = "STRICT: Respond only in English.";
      }
    }

    if (_lastManualDiagnosis != null) {
      finalQuestion =
          "ROL: Eres un EXPERTO EN AGRICULTURA GUAJIRA. El diagnóstico nutricional del niño es: $_lastManualDiagnosis. "
          "TU TAREA: No des consejos médicos. Enseña cómo cultivar Frijol Guajirito o Moringa como solución de seguridad alimentaria. "
          "INSTRUCCIÓN DE IDIOMA: $langInstruction "
          "PREGUNTA: $finalQuestion";
      _lastManualDiagnosis = null;
    } else if (_isTutorMode) {
      if (_tutorLanguage == "Bilingüe") {
        langInstruction = "Responde de forma BILINGÜE: Un párrafo en Español y su traducción al Wayuunaiki.";
      }
      finalQuestion = "ROL: PROFESOR AGRICULTURA.\n"
          "CONTENIDO: Siembra de Frijol Guajirito y Moringa.\n"
          "PREGUNTA: $finalQuestion\n\n"
          "INSTRUCCIÓN: $langInstruction. Responde en texto plano, sin asteriscos (*).";
    } else {
      if (!_isHealthProfessional) {
        if (_appLanguage == "Inglés") {
          langInstruction += " User is NOT a medic. Talk simple, no technical terms. Give home tips and warning signs.";
        } else {
          langInstruction += " Usuario NO es médico. Habla simple, sin términos técnicos. Da consejos de casa y signos de alarma básicos.";
        }
      }
      finalQuestion = "$finalQuestion\n\nINSTRUCCIÓN FINAL: $langInstruction. IMPORTANTE: Responde en texto plano, sin usar asteriscos (*).";
    }

    if (_isOfflineMode && _gemmaChat != null) {
      _offlineInteractionCount++;
      // Limitamos a 1 interacción para evitar Memory Leaks / OOM (Gemma consume mucha RAM)
      if (_offlineInteractionCount >= 1) {
        try {
          await _initGemmaChat();
        } catch (e) {
          debugPrint("Error flushing gemma context: $e");
        }
        _offlineInteractionCount = 0;
      }
      try {
        if (base64Audio != null) {
          setState(() {
            _messages.add({
              "role": "glyph",
              "text":
                  "El modo offline local actualmente no soporta audio. Ignorándolo."
            });
          });
          _scrollToBottom();
        }

        if (base64Image != null) {
          setState(() => _isThinking = true);
          final imageDescription = await _analyzeImageOffline(base64Image);
          finalQuestion = "ROL: Eres un asistente que PUEDE VER imágenes a través de un procesador de visión local. "
              "DATOS DE VISIÓN: El procesador ha identificado que la imagen es $imageDescription. "
              "BASADO EN ESTO: $finalQuestion";
          
          _scrollToBottom();
        }

        // La construcción de finalQuestion se movió arriba para ser compartida.

        await _gemmaChat!.addQuery(Message(
            text: finalQuestion,
            isUser: true));

        // _tryManualExtraction movido arriba para ser compartido.

        final response = await _gemmaChat!.generateChatResponse();

        if (response is TextResponse) {
          // Solo intentar extraer datos si NO estamos en Modo Tutor (Agricultura)
          if (!_isTutorMode) {
            final hasCalcData = RegExp(r"\d+\s*(m[ea]s|año|kg|cm|kilos)")
                .hasMatch(question.toLowerCase());
            if (!hasCalcData) {
              _addMessage({"role": "glyph", "text": response.token});
            } else {
              // Fallback si Gemma no usó la herramienta pero detectamos datos
              _tryManualExtraction(question);
            }
          } else {
            // En Modo Tutor, solo mostramos la enseñanza agrícola
            _addMessage({"role": "glyph", "text": response.token});
          }
        } else if (response is FunctionCallResponse) {
          if (response.name == "registrar_medicion_pediatrica") {
            _performAnthroCalculation(
                response.args['nombre'] ?? "Niño",
                (response.args['edad_meses'] as num?)?.toInt() ?? 0,
                (response.args['peso_kg'] as num?)?.toDouble() ?? 0.0,
                (response.args['talla_cm'] as num?)?.toDouble() ?? 0.0,
                response.args['genero'] ?? "m",
                muacCm: response.args['muac_cm'] != null
                    ? (response.args['muac_cm'] as num).toDouble()
                    : null);
          } else if (response.name == "registrar_medicion_gestante") {
            _performGestationalCalculation(
              response.args['nombre'] ?? "Gestante",
              (response.args['semanas_gestacion'] as num?)?.toInt() ?? 0,
              (response.args['peso_kg'] as num?)?.toDouble() ?? 0.0,
              (response.args['talla_cm'] as num?)?.toDouble() ?? 0.0,
            );
          } else if (response.name == "exportar_base_datos") {
            final csvFile = await _exportDatabaseToCSV();
            _addMessage({
              "role": "glyph",
              "type": "file_share",
              "data": {
                "path": csvFile.path,
                "name": "base_datos_pediatrica.csv",
                "text":
                    "He exportado la base de datos a CSV. Toca aquí para compartirla o descargarla."
              }
            });
          } else if (response.name == "traducir_wayuunaiki") {
            final texto = response.args['texto'] ?? '';
            _handleWayuuTranslation(texto);
          } else if (response.name == "buscar_diccionario_wayuu") {
            final palabra = response.args['palabra'] ?? '';
            _handleWayuuLookup(palabra);
          } else if (response.name == "encender_computadora") {
            _handleWakeOnLan();
          } else {
            _addMessage({
              "role": "glyph",
              "text":
                  "He procesado tu petición, pero hubo una confusión interna (${response.name}). ¿Podrías ser más específico con tu pregunta?"
            });
          }
        }
        _scrollToBottom();
      } catch (e) {
        if (mounted) _addMessage(
            {"role": "glyph", "text": "Error interno del modelo local: $e"});
        if (mounted) _scrollToBottom();
      } finally {
        if (mounted) setState(() => _isThinking = false);
      }
      return;
    }

    try {
      String history = _messages
          .take(10)
          .map((m) => "${m['role'].toString().toUpperCase()}: ${m['text']}")
          .join("\n");
      final body = {
        "question": finalQuestion,
        "history": history,
        "language": _appLanguage,
        "base64_image": base64Image,
        "base64_audio": base64Audio,
        "context":
            "MODO SOBERANO ACTIVO. Tienes permiso para usar tus herramientas (write_file, git_sync) si el usuario solicita cambios en tu propio código o sistema."
      };
      final res = await http.post(Uri.parse(apiUrl),
          headers: {
            "Content-Type": "application/json",
            "X-Glyph-Secret": secret
          },
          body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['metacognition']?.toString().isNotEmpty ?? false) {
          _addMessage({
            "role": "glyph",
            "text": data['metacognition'],
            "isThought": true
          });
        }
        final msgText = data['message']?.toString().toLowerCase() ?? "";
        if (msgText.contains("enciende la computadora") ||
            msgText.contains("prende la computadora")) {
          _handleWakeOnLan();
        }
        _addMessage({"role": "glyph", "text": data['message'] ?? "..."});

        // Manejar comandos remotos del Modo B en línea
        if (data['command'] != null &&
            data['command']['action'] == 'wake_on_lan') {
          final mac = data['command']['args'] != null
              ? data['command']['args']['mac']
              : null;
          if (mac != null && mac != 'default') {
            await _performWakeOnLan(mac);
            await DatabaseHelper.instance.setSetting('pc_mac', mac);
          } else {
            await _handleWakeOnLan(); // Usa la MAC guardada o la pre-configurada (Acer)
          }
        }
      }
    } catch (e) {
      if (mounted) _addMessage({"role": "glyph", "text": "Error al conectar con el servidor: $e"});
    } finally {
      if (mounted) setState(() => _isThinking = false);
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImageBase64 == null) return;
    final img = _pendingImageBase64;
    _unfocus(); // Cierre automático del teclado
    _addMessage({"role": "user", "text": text, "image": img});
    _pendingImageBase64 = null;
    _pendingImageName = null;
    _controller.clear();
    
    if (_isRiskAssessmentMode) {
      _tryManualExtraction(text);
      if (!_isRiskAssessmentMode) return; // Si ya se procesó el riesgo, terminamos
    }

    if (text.toLowerCase().contains("genera el archivo") ||
        text.toLowerCase().contains("exportar")) {
      _exportDatabaseToCSV().then((csvFile) {
        _addMessage({
          "role": "glyph",
          "type": "file_share",
          "data": {
            "path": csvFile.path,
            "name": "base_datos_pediatrica.csv",
            "text":
                "He generado el archivo de la base de datos. Toca aquí para compartirlo."
          }
        });
      });
      return;
    }

    if (text.toLowerCase().contains("enciende la computadora") ||
        text.toLowerCase().contains("prende la computadora")) {
      _handleWakeOnLan();
      return;
    }

    // --- NUEVA LÓGICA SOBERANA ---
    if (text.toLowerCase().contains("modifica tu código") ||
        text.toLowerCase().contains("edita tu código") ||
        text.toLowerCase().contains("soberanía")) {
      _addMessage({
        "role": "glyph",
        "text":
            "🛡️ Activando protocolo de auto-modificación. Contactando con el núcleo en la nube..."
      });
      // El servidor ya tiene los permisos en el Modo Soberano, solo necesitamos enviar la petición
    }

    final macRegex = RegExp(r"([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})");
    if (macRegex.hasMatch(text)) {
      final mac = macRegex.stringMatch(text)!;
      DatabaseHelper.instance.setSetting('pc_mac', mac);
      _addMessage({
        "role": "glyph",
        "text":
            "✅ He guardado la dirección MAC: $mac. Ahora ya puedo encender tu computadora cuando me lo pidas."
      });
      return;
    }

    // --- TRADUCCIÓN DIRECTA OFFLINE ---
    if (text.toLowerCase().startsWith("traducir ") ||
        text.toLowerCase().startsWith("traduce ") ||
        text.toLowerCase().startsWith("translate ")) {
      
      if (img != null) {
        // Si hay una imagen, debemos enviarla al modelo multimodal
        _sendMultimodalData(question: text, base64Image: img);
        return;
      }

      // Si es solo texto, usamos el diccionario rápido
      setState(() => _isThinking = true);
      _scrollToBottom();
      
      Future.delayed(const Duration(milliseconds: 800), () {
        final query = text.replaceFirst(RegExp(r'^(traducir|traduce|translate)\s*', caseSensitive: false), '').trim();
        if (query.isEmpty) {
          _addMessage({
            "role": "glyph", 
            "text": _appLanguage == "Inglés" ? "What do you want me to translate?" : "¿Qué pütchi quieres que traduzca?"
          });
        } else {
          _handleWayuuTranslation(query);
        }
        if (mounted) setState(() => _isThinking = false);
      });
      return;
    }
    
    if (text.toLowerCase().startsWith("buscar ") && text.toLowerCase().contains("wayuu")) {
      final query = text.replaceFirst(RegExp(r'^buscar\s+', caseSensitive: false), '').replaceAll(RegExp(r'wayuu(naiki)?', caseSensitive: false), '').trim();
      _handleWayuuLookup(query);
      return;
    }

    if (text.toLowerCase().contains("modo tutor")) {
      setState(() {
        _isTutorMode = true;
        _tutorLanguage = "Bilingüe";
      });
      _addMessage({
        "role": "glyph",
        "text":
            "¡Hola! He activado el Modo Tutor. 🌵\n\n¿En qué idioma prefieres que hablemos?\n1. Español\n2. Wayuunaiki\n3. Bilingüe (Ambos)\n\n🌵 Wayuunaiki: ¿Kasa püküjüinka süpüla pükirajüin? (1. Español, 2. Wayuunaiki, 3. Bilingüe)"
      });
      return;
    }

    if (_isTutorMode && (text == "1" || text.toLowerCase() == "español")) {
      setState(() => _tutorLanguage = "Español");
      final reply =
          "Entendido, hablaremos en Español. ¿Qué cultivo te interesa: Frijol Guajirito o Moringa?";
      _addMessage({"role": "glyph", "text": reply});
      if (_isOfflineMode && _gemmaChat != null) {
        _gemmaChat!.addQuery(Message(text: text, isUser: true));
        _gemmaChat!.addQuery(Message(text: reply, isUser: false));
      }
      return;
    }
    if (_isTutorMode && (text == "2" || text.toLowerCase() == "wayuunaiki")) {
      setState(() => _tutorLanguage = "Wayuunaiki");
      final reply =
          "Anasü, ekirajawaa süka wayuunaiki. ¿Kasa püchekaka: Frijol Guajirito o Moringa?";
      _addMessage({"role": "glyph", "text": reply});
      if (_isOfflineMode && _gemmaChat != null) {
        _gemmaChat!.addQuery(Message(text: text, isUser: true));
        _gemmaChat!.addQuery(Message(text: reply, isUser: false));
      }
      return;
    }
    if (_isTutorMode && (text == "3" || text.toLowerCase() == "bilingüe")) {
      setState(() => _tutorLanguage = "Bilingüe");
      final reply =
          "Perfecto, seré bilingüe. ¿Qué cultivo te interesa: Frijol Guajirito o Moringa?";
      _addMessage({"role": "glyph", "text": reply});
      if (_isOfflineMode && _gemmaChat != null) {
        _gemmaChat!.addQuery(Message(text: text, isUser: true));
        _gemmaChat!.addQuery(Message(text: reply, isUser: false));
      }
      return;
    }

    if (text.toLowerCase().contains("salir tutor") ||
        text.toLowerCase().contains("modo normal")) {
      setState(() => _isTutorMode = false);
      _addMessage({"role": "glyph", "text": "Modo Tutor desactivado."});
      return;
    }

    // --- AGRICULTURA: contenido hardcodeado para Frijol y Moringa ---
    if (_isTutorMode) {
      final tl = text.toLowerCase();
      if (tl.contains("frijol")) {
        _addMessage({"role": "glyph", "text": _getFrijolContent()});
        return;
      }
      if (tl.contains("moringa")) {
        _addMessage({"role": "glyph", "text": _getMoringaContent()});
        return;
      }
    }

    _sendMultimodalData(question: text, base64Image: img);
  }

  void _startNewChat() async {
    if (_messages.isEmpty) return;

    _currentSessionId = await DatabaseHelper.instance.createSession();
    final defaultMsg = {
      "role": "glyph",
      "type": "language_selector",
      "text": ""
    };
    await DatabaseHelper.instance.insertMessage(_currentSessionId!, defaultMsg);

    setState(() {
      _messages.clear();
      _messages.add(defaultMsg);
      _isMenuOpen = false;
      _offlineInteractionCount = 0;
      _menuAnimationController.reverse();
    });

    // Recargar historial visual
    _loadPersistedHistory();
  }

  String _getOrdinalName(int index, int total) {
    final pos = total - index;
    const names = [
      "Primera",
      "Segunda",
      "Tercera",
      "Cuarta",
      "Quinta",
      "Sexta",
      "Séptima",
      "Octava",
      "Novena",
      "Décima",
      "Undécima",
      "Duodécima"
    ];
    if (pos >= 1 && pos <= names.length) return "${names[pos - 1]} interacción";
    return "Interacción #$pos";
  }

  void _unfocus() {
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() => _showTextField = false);
  }

  // ─── AGRICULTURAL CONTENT ─────────────────────────────────────────────────

  String _getFrijolContent() {
    String wayuu = "Tü Frijol Guajirokat (Vigna unguiculata)\n\n"
        "Tü plantajirü aka süka pülü maikirunüi sünainmüin tü mmakat müsia akuwaipajüi tü eküülü pülüshi. "
        "Püsirayaa 40-60 cm süka wopu süpüla tü wayataa. "
        "Emayaa 2 o 3 waküin süka wune mma süpüla wane jintü anasü.\n\n"
        "Kaa'uleein Eetaain: Tü plantakat eejüna tü bakterijakat tü mmakat süpüla akumajüin nitrogenokai süchiki tü wanüliakat. "
        "Nnojotsü pülaainjatüin tü fertilizanteka tütüjülia.\n\n"
        "Eküülü pülüshi: Anüiki tü soköshi, eejüna wane oütüü süchiki tü yaakat 'etapa crítica'. "
        "Müsia pütchikot tü waküin süpüla tü natiakat paala, tü aapakat wayuu süpüla tü mmaka outshi.";

    String en = "The Guajiro Bean (Vigna unguiculata)\n\n"
        "This crop is a survival master in poor soils. Planting begins with direct seeding — transplanting is not recommended because its roots are sensitive to initial movement. Plant at 40–60 cm spacing to allow air circulation, preventing fungal diseases in humid conditions.\n\n"
        "Germination & Soil: Sowing 2–3 seeds per site ensures at least one strong plant emerges. The plant has a symbiotic relationship with soil bacteria that 'trap' nitrogen from the air and fix it to the soil — no expensive chemical fertilizers needed.\n\n"
        "Critical Care: Although it tolerates extreme heat, there is a period called the 'critical stage' during pod formation. If the plant suffers severe drought at that moment, flowers drop and there will be no harvest. A supplemental irrigation at this stage is the difference between a successful and a failed crop.";

    String es = "El Frijol Guajirito (Vigna unguiculata)\n\n"
        "Este cultivo es un maestro de la supervivencia en suelos pobres. Su plantación comienza con la siembra directa; no se recomienda el trasplante porque sus raíces son sensibles al movimiento inicial. Debes sembrar a una distancia de 40 a 60 cm entre plantas para permitir que el aire circule, lo cual previene hongos si llega a haber mucha humedad.\n\n"
        "Germinación y Suelo: Al sembrar 2 o 3 semillas por sitio, aseguras que al menos una planta fuerte emerja. La planta tiene una relación simbiótica con bacterias del suelo que 'atrapan' el nitrógeno del aire y lo pegan a la tierra; por eso, no necesitas fertilizantes químicos costosos.\n\n"
        "Cuidado Crítico: Aunque tolera el calor extremo, existe un periodo llamado 'etapa crítica' que es durante la formación de las vainas. Si en ese momento la planta sufre demasiada sed, las flores se caen y no habrá cosecha. Un riego de auxilio en esta fase es la diferencia entre un cultivo exitoso y uno fallido.";

    if (_tutorLanguage == "Wayuunaiki") return wayuu;
    if (_tutorLanguage == "Inglés") return en;
    if (_tutorLanguage == "Español") return es;

    if (_tutorLanguage == "Bilingüe") {
      if (_appLanguage == "Wayuunaiki") {
        return "$wayuu\n\n---\n\n$es";
      } else if (_appLanguage == "Inglés") {
        return "$en\n\n---\n\n$es";
      } else {
        return "$es\n\n---\n\n$wayuu";
      }
    }
    return es;
  }

  String _getMoringaContent() {
    String wayuu = "Tü Moringa (Moringa oleifera)\n\n"
        "Tü moringa aka wane aapiakat ekirajükat maa'ulu (3 metros wane juyaka). "
        "Tü kaa'uleein pülüshikat aka süka tü outaakat. Süpüla tü mmakat La Guajirat, müsia akua'ipa, "
        "tü mmakat anüiki tü pasatkat; müsia tü wayuukat nümayaa, tü yaakat nüpütaa süchiirua.\n\n"
        "Akumajaa: Müsia pülaain bolsakat nüünüin, jieechishin nüünüin süpüla tü yaakat anüiki. "
        "Müsia pülaain 40x40 cm süpüla tü yaakat anüiki.\n\n"
        "Kaa'uleein: Tü poda de despunte aka müsia pülaain süpüla tü aapiakat anüiki copa. "
        "Jieechishin tü hojakat süpüla eküülü müsia tü mmakat anasü nümayaa sünainmüin.";

    String en = "The Moringa Tree (Moringa oleifera)\n\n"
        "Moringa is an ultra-fast-growing tree (it can grow up to 3 meters in a year). The key to planting lies in drainage. In La Guajira, although the soil is dry, it can sometimes be very compact; if water becomes waterlogged, the moringa root rots within days.\n\n"
        "Germination & Transplanting: If using seedling bags, ensure they have good depth, as moringa develops a taproot (like a long carrot) very quickly. When transplanting to the permanent site, the hole must be wide (about 40x40 cm) so the soil is loose and the root can sink in effortlessly.\n\n"
        "Care & Production: The most important management is tip pruning (despunte). If left to grow freely, you'll have a tall pole with few leaves. By cutting the tip at one meter, you force the tree to widen its canopy. This not only gives you more leaves for consumption, but creates natural shade that protects the surrounding soil, retaining moisture longer.";

    String es = "La Moringa (Moringa oleifera)\n\n"
        "La moringa es un árbol de crecimiento ultra rápido (puede crecer hasta 3 metros en un año). La clave de su plantación está en el drenaje. En La Guajira, aunque el suelo es seco, a veces es muy compacto; si el agua se queda estancada, la raíz de la moringa se pudre en cuestión de días.\n\n"
        "Germinación y Trasplante: Si usas bolsas de semillero, asegúrate de que tengan buena profundidad, ya que la moringa desarrolla una raíz pivotante (como una zanahoria larga) muy rápido. Al trasplantar al sitio definitivo, el hoyo debe ser amplio (unos 40x40 cm) para que la tierra esté suelta y la raíz baje sin esfuerzo.\n\n"
        "Cuidado y Producción: El manejo más importante es la poda de despunte. Si la dejas crecer libre, tendrás un poste alto con pocas hojas. Al cortar la punta cuando mide un metro, obligas al árbol a ensanchar su copa. Esto no solo te da más hojas para consumo, sino que crea una sombra natural que protege el suelo alrededor del tronco, manteniendo la humedad por más tiempo.";

    if (_tutorLanguage == "Wayuunaiki") return wayuu;
    if (_tutorLanguage == "Inglés") return en;
    if (_tutorLanguage == "Español") return es;

    if (_tutorLanguage == "Bilingüe") {
      if (_appLanguage == "Wayuunaiki") {
        return "$wayuu\n\n---\n\n$es";
      } else if (_appLanguage == "Inglés") {
        return "$en\n\n---\n\n$es";
      } else {
        return "$es\n\n---\n\n$wayuu";
      }
    }
    return es;
  }

  // ─── CHECK ANIMATION WIDGET ───────────────────────────────────────────────
  Widget _buildCheckAnimationBubble() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: value,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 28),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final isUser = msg["role"] == "user";
    final isThought = msg["isThought"] ?? false;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isThought
              ? Colors.cyanAccent.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: isUser ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isThought
                  ? Colors.cyanAccent.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg["image"] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(base64Decode(msg["image"]),
                      width: 180, fit: BoxFit.cover),
                ),
              ),
            if (msg["type"] == "check_animation") ...[
              _buildCheckAnimationBubble(),
            ],
            if (msg["type"] == "language_selector") ...[
              const Center(
                child: Text("🌎 Selecciona tu idioma / Pünaa pünük",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildLangBubble("Español"),
                  _buildLangBubble("Wayuunaiki"),
                  _buildLangBubble("Inglés"),
                ],
              )
            ],
            if (msg["type"] == "topic_selector") ...[
              Text(msg["text"] ?? "",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14)),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildTopicBubble("Salud"),
                  _buildTopicBubble("Agricultura"),
                ],
              )
            ],
            if (msg["type"] == "role_selector") ...[
              Text(msg["text"] ?? "",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14)),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildRoleBubble("Profesional"),
                  _buildRoleBubble("Persona"),
                ],
              )
            ],
            if (msg["type"] == "patient_type_selector") ...[
              Text(msg["text"] ?? "",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14)),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildPatientTypeOption(_translate("patient_boy")),
                  _buildPatientTypeOption(_translate("patient_girl")),
                  _buildPatientTypeOption(_translate("patient_man")),
                  _buildPatientTypeOption(_translate("patient_woman")),
                ],
              )
            ],
            if (msg["type"] == "name_input_bubble") ...[
              Text(msg["text"] ?? "",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14)),
              const SizedBox(height: 12),
              _buildTextInput("Nombre", (val) {
                 _interactiveName = val;
                 _messages.removeWhere((m) => m["type"] == "name_input_bubble");
                 _addMessage({"role": "user", "text": val});
                 
                 // Show date picker right after name is submitted
                 _showDobPickerForInteractiveFlow();
              })
            ],
            if (msg["type"] == "weight_input_bubble") ...[
              Text(msg["text"] ?? "",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14)),
              const SizedBox(height: 12),
              _buildNumberInput("Peso (kg)", (val) {
                 _interactiveWeight = val;
                 _messages.removeWhere((m) => m["type"] == "weight_input_bubble");
                 _addMessage({"role": "user", "text": "$val kg"});
                 _addMessage({
                   "role": "glyph",
                   "type": "height_input_bubble",
                   "text": _translate("height_q")
                 });
              })
            ],
            if (msg["type"] == "height_input_bubble") ...[
              Text(msg["text"] ?? "",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14)),
              const SizedBox(height: 12),
              _buildNumberInput("Talla (cm)", (val) {
                 _interactiveHeight = val;
                 _messages.removeWhere((m) => m["type"] == "height_input_bubble");
                 _addMessage({"role": "user", "text": "$val cm"});
                 
                 // Perform anthro calculation!
                 int exactDays = DateTime.now().difference(_interactiveDob!).inDays;
                 int months = exactDays ~/ 30; // approximate for logging, actual will use exactDays
                 _performAnthroCalculation(
                   _interactiveName ?? "Paciente",
                   months,
                   _interactiveWeight!,
                   _interactiveHeight!,
                   _interactiveGender!,
                   ageInDays: exactDays
                 );
                 
                 setState(() {
                   _isInteractiveAnthroFlow = false;
                 });
              })
            ],
            if (msg["type"] == "anthro_chart" && msg["data"] != null) ...[
              Text(msg["data"]["text"],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              if (_isHealthProfessional) ...[
                const SizedBox(height: 12),
                AnthroChartWidget(
                  ageInMonths: msg["data"]["edad"],
                  weightKg: msg["data"]["peso"],
                  heightCm: (msg["data"]["talla"] as num).toDouble(),
                  genderStr: msg["data"]["genero"],
                  diagnosis: msg["data"]["diag"],
                ),
              ],
            ],
            if (msg["type"] == "file_share" && msg["data"] != null) ...[
              GestureDetector(
                  onTap: () => Share.shareXFiles([XFile(msg["data"]["path"])],
                      text: "Base de datos exportada desde Glyph"),
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.blueAccent.withValues(alpha: 0.5))),
                      child: Row(children: [
                        const Icon(Icons.file_download, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(msg["data"]["text"],
                                style: const TextStyle(color: Colors.white)))
                      ]))),
            ],
            if (msg["type"] != "file_share" &&
                msg["text"]?.toString().isNotEmpty == true)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(msg["text"],
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontStyle: isThought
                                ? FontStyle.italic
                                : FontStyle.normal)),
                  ),
                  if (!isUser && !isThought)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () => _flutterTts.speak(msg["text"]),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.volume_up,
                              color: Colors.cyanAccent, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangBubble(String lang) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          _appLanguage = lang;
        });
        
        _messages.removeWhere((m) => m["type"] == "language_selector");
        if (_currentSessionId != null) {
           await DatabaseHelper.instance.deleteSession(_currentSessionId!);
           _currentSessionId = await DatabaseHelper.instance.createSession();
        }
        
        if (lang == "Wayuunaiki") {
          _addMessage({
            "role": "glyph",
            "type": "topic_selector",
            "text": "Taya Glyph, tü pütchipü'üka pia süpüla kaa'uleein chi tepichikai. ¿Kasa püchekaka tatüma?"
          });
        } else if (lang == "Inglés") {
          _addMessage({
            "role": "glyph",
            "type": "topic_selector",
            "text": "Hello! I'm Glyph, your pediatric and nutritional health assistant.\nHow can I help you today?"
          });
        } else {
          _addMessage({
            "role": "glyph",
            "type": "topic_selector",
            "text": "¡Hola! Soy Glyph, tu asistente de salud pediátrica y nutricional.\n¿En qué te puedo ayudar hoy?"
          });
        }
        
        if (_isOfflineMode) {
          _initGemmaChat();
        }
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 10)
                ]
              ),
              child: Text(lang, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          );
        }
      ),
    );
  }

  Widget _buildTopicBubble(String topic) {
    String display = "";
    String emoji = "";
    if (topic == "Salud") {
      emoji = "🏥";
      if (_appLanguage == "Wayuunaiki") display = "Tayaa tü kaa'uleein";
      else if (_appLanguage == "Inglés") display = "Health";
      else display = "Salud";
    } else {
      emoji = "🌱";
      if (_appLanguage == "Wayuunaiki") display = "Ekirajüi";
      else if (_appLanguage == "Inglés") display = "Agriculture";
      else display = "Agricultura";
    }

    return GestureDetector(
      onTap: () {
        // Limpiamos selectores previos y activamos modo tutor si aplica
        setState(() {
          _messages.removeWhere((m) => m["type"] == "topic_selector");
          _isTutorMode = (topic == "Agricultura");
        });
        
        // Añadimos los mensajes de confirmación
        _addMessage({"role": "user", "text": "$emoji $display"});
        
        if (topic == "Agricultura") {
           _addMessage({
             "role": "glyph",
             "text": _appLanguage == "Wayuunaiki" 
                 ? "Anasü. ¿Kasa püchekaka: Frijol Guajirito o Moringa?"
                 : _appLanguage == "Inglés"
                     ? "Understood. What crop are you interested in: Frijol Guajirito or Moringa?"
                     : "Entendido. ¿Qué cultivo te interesa: Frijol Guajirito o Moringa?"
           });
           _scrollToBottom();
        } else {
           _addMessage({
             "role": "glyph",
             "type": "role_selector",
             "text": _appLanguage == "Wayuunaiki" 
                 ? "Pülashii pia piamale. ¿Pia wanee pütchipü'üka o wayuu eekai?"
                 : _appLanguage == "Inglés"
                     ? "Are you a healthcare professional or a general user?"
                     : "¿Eres personal de salud o un usuario particular?"
           });
        }
        _scrollToBottom();
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.2), blurRadius: 10)
                ]
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(display, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildRoleBubble(String role) {
    String display = "";
    String emoji = role == "Profesional" ? "🩺" : "👤";
    
    if (role == "Profesional") {
      if (_appLanguage == "Wayuunaiki") display = "Pütchipü'üka";
      else if (_appLanguage == "Inglés") display = "Professional";
      else display = "Personal de Salud";
    } else {
      if (_appLanguage == "Wayuunaiki") display = "Wayuu eekai";
      else if (_appLanguage == "Inglés") display = "Person";
      else display = "Persona";
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _messages.removeWhere((m) => m["type"] == "role_selector");
          _isHealthProfessional = (role == "Profesional");
        });
        
        _addMessage({"role": "user", "text": "$emoji $display"});
        
        if (role == "Profesional") {
           _addMessage({
             "role": "glyph",
             "type": "patient_type_selector",
             "text": _translate("patient_type_q")
           });
           setState(() {
             _isInteractiveAnthroFlow = true;
             _interactiveGender = null;
             _interactiveDob = null;
             _interactiveWeight = null;
             _interactiveHeight = null;
             _interactiveName = null;
           });
        } else {
           _addMessage({
             "role": "glyph",
             "text": _appLanguage == "Wayuunaiki" 
                 ? "¿Kasa nüpüshi chi tepichikai? (¿Cómo se llama el niño o niña?)"
                 : _appLanguage == "Inglés"
                     ? "What is the patient's name?"
                     : "¿Cómo se llama el paciente?"
           });
           
           setState(() {
             _isRiskAssessmentMode = true;
             _pendingRiskName = null; // Reiniciar por si acaso
           });
        }
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.2), blurRadius: 10)
                ]
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(display, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildPatientTypeOption(String text) {
    return GestureDetector(
      onTap: () async {
         setState(() {
            _messages.removeWhere((m) => m["type"] == "patient_type_selector");
         });
         _addMessage({"role": "user", "text": text});
         
         final bool isChild = text.contains("Niño") || text.contains("Niña") || 
                            text.contains("Jintüi") || text.contains("Jintüt") ||
                            text.contains("Boy") || text.contains("Girl");
         
         if (isChild) {
            _interactiveGender = (text.contains("Niño") || text.contains("Jintüi") || text.contains("Boy")) ? "m" : "f";
            
            // Ask for name first
            _addMessage({
              "role": "glyph",
              "type": "name_input_bubble",
              "text": _translate("name_q")
            });
         } else {
            _addMessage({
              "role": "glyph",
              "text": "Evaluación de adultos en desarrollo. Por favor escribe directamente los datos como: 'Juan, 25 años, 70kg, 175cm'."
            });
            setState(() {
               _isInteractiveAnthroFlow = false;
            });
         }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildNumberInput(String hint, Function(double) onSubmit) {
    final TextEditingController inputCtrl = TextEditingController();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 100,
          child: TextField(
            controller: inputCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 28),
          onPressed: () {
            final val = double.tryParse(inputCtrl.text.replaceAll(',', '.'));
            if (val != null) {
              onSubmit(val);
            }
          },
        )
      ],
    );
  }

  String _translate(String key) {
    final Map<String, Map<String, String>> t = {
      "patient_type_q": {
        "Español": "¿El paciente es niño, niña, hombre o mujer?",
        "Wayuunaiki": "¿Chi wayuukai niia jintüi, jintüt, toloyuu o majayüt?",
        "Inglés": "Is the patient a boy, girl, man or woman?"
      },
      "name_q": {
        "Español": "¿Cómo se llama el paciente?",
        "Wayuunaiki": "¿Kasa nüpüshi chi wayuukai?",
        "Inglés": "What is the patient's name?"
      },
      "weight_q": {
        "Español": "¿Cuál es el peso en kilogramos?",
        "Wayuunaiki": "¿Je'tsü nüpüla en kilogramos?",
        "Inglés": "What is the weight in kilograms?"
      },
      "height_q": {
        "Español": "¿Cuál es la talla en centímetros?",
        "Wayuunaiki": "¿Je'tsü nno'u en centímetros?",
        "Inglés": "What is the height in centimeters?"
      },
      "topic_health": {
        "Español": "Salud",
        "Wayuunaiki": "Anasü",
        "Inglés": "Health"
      },
      "topic_agri": {
        "Español": "Agricultura",
        "Wayuunaiki": "Apünajawaa",
        "Inglés": "Agriculture"
      },
      "role_medic": {
        "Español": "Médico / Nutricionista",
        "Wayuunaiki": "Aküja pütchi salud",
        "Inglés": "Doctor / Nutritionist"
      },
      "role_mother": {
        "Español": "Madre / Cuidador",
        "Wayuunaiki": "Ei / Eküliya",
        "Inglés": "Mother / Caregiver"
      },
      "patient_boy": {
        "Español": "👦 Niño",
        "Wayuunaiki": "👦 Jintüi (Niño)",
        "Inglés": "👦 Boy"
      },
      "patient_girl": {
        "Español": "👧 Niña",
        "Wayuunaiki": "👧 Jintüt (Niña)",
        "Inglés": "👧 Girl"
      },
      "patient_man": {
        "Español": "👨 Hombre",
        "Wayuunaiki": "👨 Toloyuu (Hombre)",
        "Inglés": "👨 Man"
      },
      "patient_woman": {
        "Español": "👩 Mujer",
        "Wayuunaiki": "👩 Majayüt (Mujer)",
        "Inglés": "👩 Woman"
      },
    };
    final lang = _appLanguage.isEmpty ? "Español" : _appLanguage;
    return t[key]?[lang] ?? t[key]?["Español"] ?? key;
  }

  Future<void> _showDobPickerForInteractiveFlow() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF0A0A0F),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0A0A0F),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _interactiveDob = picked;
      final dateStr = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      _addMessage({"role": "user", "text": dateStr});
      _addMessage({
        "role": "glyph",
        "type": "weight_input_bubble",
        "text": _translate("weight_q")
      });
    } else {
      _addMessage({"role": "glyph", "text": "Selección de fecha cancelada."});
      setState(() => _isInteractiveAnthroFlow = false);
    }
  }

  Widget _buildTextInput(String hint, Function(String) onSubmit) {
    final TextEditingController inputCtrl = TextEditingController();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 160,
          child: TextField(
            controller: inputCtrl,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 28),
          onPressed: () {
            final val = inputCtrl.text.trim();
            if (val.isNotEmpty) onSubmit(val);
          },
        )
      ],
    );
  }

  String _getMenuText(String key) {
    Map<String, Map<String, String>> translations = {
      "new_chat": {
        "Español": "Nuevo Chat",
        "Wayuunaiki": "Wane pütchi mma'ana",
        "Inglés": "New Chat"
      },
      "patient_type_q": {
        "Español": "¿El paciente es niño, niña, hombre o mujer?",
        "Wayuunaiki": "¿Chi wayuukai niia jintüi, jintüt, toloyuu o majayüt?",
        "Inglés": "Is the patient a boy, girl, man or woman?"
      },
      "name_q": {
        "Español": "¿Cómo se llama el paciente?",
        "Wayuunaiki": "¿Kasa nüpüshi chi wayuukai?",
        "Inglés": "What is the patient's name?"
      },
      "weight_q": {
        "Español": "¿Cuál es el peso en kilogramos?",
        "Wayuunaiki": "¿Je'tsü nüpüla en kilogramos?",
        "Inglés": "What is the weight in kilograms?"
      },
      "height_q": {
        "Español": "¿Cuál es la talla en centímetros?",
        "Wayuunaiki": "¿Je'tsü nno'u en centímetros?",
        "Inglés": "What is the height in centimeters?"
      },
      "attach_image": {
        "Español": "Adjuntar Imagen",
        "Wayuunaiki": "Aapaa ayaakuwakalee",
        "Inglés": "Attach Image"
      },
      "attach_file": {
        "Español": "Adjuntar Archivo",
        "Wayuunaiki": "Aapaa karaloüta",
        "Inglés": "Attach File"
      },
      "generated_files": {
        "Español": "Archivos Generados",
        "Wayuunaiki": "Karaloüta akumajüna",
        "Inglés": "Generated Files"
      },
      "nutritional_control": {
        "Español": "Control Nutricional",
        "Wayuunaiki": "Kaa'uleein nne'erükü",
        "Inglés": "Nutritional Control"
      },
      "translator": {
        "Español": "Traductor",
        "Wayuunaiki": "Pütchipü'ü",
        "Inglés": "Translator"
      },
      "text": {
        "Español": "Texto",
        "Wayuunaiki": "Pütchi",
        "Inglés": "Text"
      },
      "audio": {
        "Español": "Audio",
        "Wayuunaiki": "Asülajaa",
        "Inglés": "Audio"
      },
      "p2p_sync": {
        "Español": "Sincronización P2P",
        "Wayuunaiki": "Akumajaa pütchi",
        "Inglés": "P2P Sync"
      },
      "download_apk": {
        "Español": "Descargar Nueva Versión",
        "Wayuunaiki": "Aapaa nükua'ipa Glyph",
        "Inglés": "Download New Version"
      },
      "risk_patients": {
        "Español": "Pacientes en Riesgo",
        "Wayuunaiki": "Wayuu ayuulii",
        "Inglés": "Patients at Risk"
      },
      "online_mode": {
        "Español": "Modo Online (Experimental)",
        "Wayuunaiki": "Aashajawaa mma'ana",
        "Inglés": "Online Mode"
      },
      "offline_mode": {
        "Español": "Modo Offline (Gemma)",
        "Wayuunaiki": "Aashajawaa yaa",
        "Inglés": "Offline Mode"
      },
    };

    String lang = _appLanguage.isEmpty ? "Español" : _appLanguage;
    return translations[key]?[lang] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: GestureDetector(
        onTap: _unfocus,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            MeshGradientBackground(animation: _waveController),
            Positioned.fill(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 100, bottom: 250),
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    _buildChatBubble(_messages[index]),
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedHamburger(isOpen: _isMenuOpen, onTap: _toggleMenu),
                  IconButton(
                      icon: Icon(
                          _showHistory ? Icons.chat_bubble : Icons.history,
                          color: Colors.white),
                      onPressed: () =>
                          setState(() => _showHistory = !_showHistory)),
                ],
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showTextField ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: _showTextField,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showTextField = true);
                      _focusNode.requestFocus();
                    },
                    onLongPressStart: (_) => _startRecording(forceSTT: true),
                    onLongPressEnd: (_) async {
                      await _stopRecording(autoSend: true);
                    },
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 300),
                        scale: _showTextField ? 0.4 : (_isRecording ? 1.8 : 1.0),
                        child: AnimatedBuilder(
                          animation: Listenable.merge(
                              [_pulseController, _waveController]),
                          builder: (context, _) => CustomPaint(
                            painter: FragmentedTrianglePainter(
                              animationValue: _waveController.value,
                              isThinking: _isThinking,
                              isRecording: _isRecording,
                            ),
                            size: const Size(60, 60), // Más pequeño y elegante
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              bottom: _showTextField ? 100 : 80,
              left: 30,
              right: 30,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _showTextField ? 1.0 : 0.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 500),
                  scale: _showTextField ? 1.0 : 0.8,
                  curve: Curves.easeOutBack,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: false,
                            onSubmitted: (_) => _handleSend(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: "", // Limpio
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.cyanAccent, size: 22),
                          onPressed: _handleSend,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Overlay de Traductor por Audio
            if (_isTranslatorAudioMode)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.88),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Triángulo palpitante
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) => Transform.scale(
                          scale: 1.0 + (_pulseController.value * (_isRecording ? 0.25 : 0.05)),
                          child: CustomPaint(
                            painter: FragmentedTrianglePainter(
                              animationValue: _waveController.value,
                              isThinking: false,
                              isRecording: _isRecording,
                            ),
                            size: const Size(100, 100),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Estado
                      Text(
                        _isRecording ? "ESCUCHANDO..." : "LISTO PARA GRABAR",
                        style: TextStyle(
                          color: _isRecording
                              ? Colors.cyanAccent.withValues(alpha: 0.9)
                              : Colors.white38,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.5,
                        ),
                      ),
                      // Texto reconocido en tiempo real
                      if (_controller.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          child: Text(
                            _controller.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        const SizedBox(height: 24),
                      const SizedBox(height: 20),
                      // Botones: Grabar + Detener
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Botón grabar (mic)
                          GestureDetector(
                            onTap: _isRecording ? null : _restartTranslatorRecording,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: _isRecording
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.cyanAccent.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: _isRecording ? Colors.white24 : Colors.cyanAccent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _isRecording
                                    ? []
                                    : [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 18)],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.mic_rounded,
                                  color: _isRecording ? Colors.white24 : Colors.cyanAccent,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 28),
                          // Botón detener (cuadrado rojo)
                          GestureDetector(
                            onTap: _stopTranslatorAudioMode,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                border: Border.all(color: Colors.redAccent, width: 2),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 20)
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.stop_rounded, color: Colors.redAccent, size: 34),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isRecording ? "Habla ahora · Toca ■ para traducir" : "Toca 🎙 para grabar",
                        style: TextStyle(color: Colors.white30, fontSize: 11, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isMenuOpen)
              GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: SlideTransition(
                    position: _menuOffsetAnimation,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        border: Border(
                            right: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 0.5)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: IconButton(
                                icon: AnimatedRotation(
                                  duration: const Duration(milliseconds: 300),
                                  turns: _isMenuOpen ? 0.25 : 0.0,
                                  child: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
                                ),
                                onPressed: _toggleMenu,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListTile(
                            leading: const Icon(Icons.add_circle_outline,
                                color: Colors.white60, size: 20),
                            title: Text(_getMenuText("new_chat"),
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2)),
                            onTap: _startNewChat,
                          ),
                          ListTile(
                            leading: const Icon(Icons.image_outlined,
                                color: Colors.white60, size: 20),
                            title: Text(_getMenuText("attach_image"),
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2)),
                            onTap: _pickImage,
                          ),
                          ListTile(
                            leading: const Icon(Icons.folder_outlined,
                                color: Colors.white60, size: 20),
                            title: Text(_getMenuText("generated_files"),
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2)),
                            onTap: _showGeneratedFiles,
                          ),
                          ListTile(
                            leading: const Icon(Icons.people_alt_outlined,
                                color: Colors.white60, size: 20),
                            title: Text(_getMenuText("nutritional_control"),
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2)),
                            onTap: () {
                              _toggleMenu();
                              _showNutritionalControl();
                            },
                          ),

                          // Traductor
                          ListTile(
                            leading: const Icon(Icons.g_translate_outlined,
                                color: Colors.white60, size: 20),
                            title: Text(_getMenuText("translator"),
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 13,
                                    fontWeight: FontWeight.w300)),
                            onTap: () {
                              _toggleMenu();
                              _showBilingualGlossary();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.qr_code_2_outlined,
                                color: Colors.white60, size: 20),
                            title: Text(_getMenuText("p2p_sync"),
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 13)),
                            onTap: _syncP2PData,
                          ),
                          ListTile(
                            leading: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                              builder: (_, v, __) => Transform.scale(
                                scale: v,
                                child: const Icon(Icons.android_rounded,
                                    color: Color(0xFF3DDC84), size: 22),
                              ),
                            ),
                            title: Text(_getMenuText("download_apk"),
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2)),
                            onTap: () {
                              _toggleMenu();
                              _sendMultimodalData(
                                  question:
                                      "Gabriel, he preparado el enlace para que descargues mi última versión (APK). Haz clic aquí: https://github.com/ggbbrr17/app/releases/latest");
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.warning_amber_rounded,
                                color: Colors.orangeAccent, size: 20),
                            title: Text(_getMenuText("risk_patients"),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            onTap: () {
                              _toggleMenu();
                              _showRiskPatients();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.memory_outlined,
                                color: Colors.white60, size: 20),
                            title: Text(
                                _isOfflineMode
                                    ? _getMenuText("online_mode")
                                    : _getMenuText("offline_mode"),
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2)),
                            onTap: () {
                              if (_isOfflineMode) {
                                setState(() {
                                  _isOfflineMode = false;
                                  _isMenuOpen = false;
                                  _addMessage({
                                    "role": "glyph",
                                    "text":
                                        "Cambiando a Modo Online (Experimental). Usando el servidor en la nube."
                                  });
                                });
                                _menuAnimationController.reverse();
                                _scrollToBottom();
                              } else {
                                _loadGemmaModel();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_showHistory)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: Colors.black
                        .withValues(alpha: 0.5), // Más opaco para mejor lectura
                    child: Column(
                      children: [
                        const SizedBox(height: 80),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("HISTORIAL",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 3.5,
                                      color: Colors.white70)),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() => _showHistory = false);
                                },
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Transform.rotate(
                                          angle: math.pi / 4,
                                          child: Container(
                                              width: 22,
                                              height: 1.5,
                                              color: Colors.white70)),
                                      Transform.rotate(
                                          angle: -math.pi / 4,
                                          child: Container(
                                              width: 22,
                                              height: 1.5,
                                              color: Colors.white70)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                            child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 30),
                                itemCount: _chatSessions.length,
                                itemBuilder: (c, i) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                        _getOrdinalName(
                                            i, _chatSessions.length),
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w300,
                                            letterSpacing: 0.5)),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.white24, size: 18),
                                      onPressed: () async {
                                        await DatabaseHelper.instance
                                            .deleteSession(_sessionIds[i]);
                                        _loadPersistedHistory();
                                      },
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _currentSessionId = _sessionIds[i];
                                        _messages.clear();
                                        _messages.addAll(_chatSessions[i]);
                                        _showHistory = false;
                                      });
                                    }))),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAncestralRecipes() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text("Recetario Soberano",
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("🌱 Moringa y Hierro",
                  style: TextStyle(
                      color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              const Text(
                  "Hojas secas en chicha o sopa para combatir la anemia.",
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              const Text("🫘 Frijol Guajirito",
                  style: TextStyle(
                      color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              const Text("Alta proteína local para recuperación nutricional.",
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cerrar",
                  style: TextStyle(color: Colors.cyanAccent)))
        ],
      ),
    );
  }

  void _startTranslatorAudioMode() async {
    _controller.clear();
    setState(() {
      _isTranslatorAudioMode = true;
    });
    await _startRecording(forceSTT: true);
  }

  void _restartTranslatorRecording() async {
    _controller.clear();
    await _startRecording(forceSTT: true);
  }

  void _stopTranslatorAudioMode() async {
    // 1. Detener reconocimiento
    await _stopRecording(autoSend: false);

    // 2. Capturar texto antes de limpiar
    final textToTranslate = _controller.text.trim();

    // 3. Cerrar overlay
    if (mounted) setState(() => _isTranslatorAudioMode = false);

    // 4. Enviar si hay texto
    if (textToTranslate.isNotEmpty) {
      _controller.clear();
      _addMessage({"role": "user", "text": "🎙️ $textToTranslate"});

      String prompt;
      if (_appLanguage == "Wayuunaiki") {
        prompt = "Traduce al Español: $textToTranslate";
      } else if (_appLanguage == "Inglés") {
        prompt = "Translate to Wayuunaiki: $textToTranslate";
      } else {
        // Español por defecto → Wayuunaiki
        prompt = "Traduce al Wayuunaiki: $textToTranslate";
      }

      // Usar diccionario offline primero; si hay resultado, mostrarlo directamente
      if (_wayuuDict.isLoaded) {
        _handleWayuuTranslation(textToTranslate);
      } else {
        _sendMultimodalData(question: prompt);
      }
    } else {
      // Sin texto capturado — informar al usuario
      _addMessage({
        "role": "glyph",
        "text": "No se detectó voz. Toca el micrófono para intentarlo de nuevo."
      });
    }
  }

  void _showRiskPatients() async {
    final patients = await DatabaseHelper.instance.getRiskPatients();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text("Pacientes en Riesgo", style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: patients.isEmpty 
              ? const Center(child: Text("No hay casos registrados.", style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (ctx, i) {
                    final p = patients[i];
                    return Card(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(p['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(p['symptoms'], style: const TextStyle(color: Colors.white70)),
                        trailing: Text(p['date'].toString().split('T').first, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cerrar", style: TextStyle(color: Colors.cyanAccent)),
          )
        ],
      )
    );
  }

  void _showBilingualGlossary() {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final query = searchController.text.trim();
          final entries = query.isEmpty
              ? WayuuDictionary.medicalGlossary.entries.toList()
              : WayuuDictionary.medicalGlossary.entries
                  .where((e) =>
                      e.key.toLowerCase().contains(query.toLowerCase()) ||
                      e.value.toLowerCase().contains(query.toLowerCase()))
                  .toList();
          // Also add fuzzy search results from full dictionary
          List<Map<String, String>> fuzzyResults = [];
          if (query.isNotEmpty) {
            fuzzyResults = _wayuuDict.fuzzySearch(query, limit: 15);
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF0D0D1A),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("📖 Diccionario Wayuunaiki",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                    "${_wayuuDict.stats['total_wayuunaiki']} palabras · 100% offline",
                    style: TextStyle(
                        color: Colors.cyanAccent.withValues(alpha: 0.7),
                        fontSize: 11)),
                const SizedBox(height: 10),
                TextField(
                  controller: searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Buscar palabra...",
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3)),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.cyanAccent, size: 18),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 350,
              child: ListView(
                children: [
                  if (query.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text("🏥 Glosario Médico",
                          style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ...entries.map((e) => _glossaryItem(e.value, e.key)),
                  if (fuzzyResults.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 8),
                      child: Text("🔍 Diccionario General",
                          style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                    ...fuzzyResults.map((r) =>
                        _glossaryItem(r['español']!, r['wayuunaiki']!)),
                  ],
                  if (entries.isEmpty && fuzzyResults.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text("No se encontró '$query'",
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4))),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cerrar",
                      style: TextStyle(color: Colors.cyanAccent)))
            ],
          );
        },
      ),
    );
  }

  Widget _glossaryItem(String esp, String way) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(way,
              style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
          const Text("  →  ",
              style: TextStyle(color: Colors.white30, fontSize: 13)),
          Expanded(
            child: Text(esp,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ─── WAYUUNAIKI TRANSLATION HANDLERS ──────────────────────────────────────
  void _handleWayuuTranslation(String text) {
    if (!_wayuuDict.isLoaded) {
      final loadingMsg = _appLanguage == "Inglés"
          ? "⏳ Dictionary is still loading..."
          : _appLanguage == "Wayuunaiki"
            ? "⏳ Tü diccionariokat eejünajatüin..."
            : "⏳ El diccionario aún se está cargando...";
      _addMessage({"role": "glyph", "text": loadingMsg});
      return;
    }
    final lang = _wayuuDict.detectLanguage(text);
    final StringBuffer result = StringBuffer();

    if (lang == 'wayuunaiki') {
      result.writeln("🌵 Wayuunaiki → 🇪🇸 Español\n");
      final words = text.toLowerCase().split(RegExp(r'\s+'));
      for (final word in words) {
        final clean = word.replaceAll(RegExp(r"[^\wáéíóúüñ']"), '');
        if (clean.isEmpty) continue;
        final esp = _wayuuDict.lookupWayuu(clean);
        if (esp != null) {
          result.writeln("• $clean → $esp");
        } else {
          final notFound = _appLanguage == "Inglés"
              ? "'$clean' — word not found in dictionary"
              : _appLanguage == "Wayuunaiki"
                ? "'$clean' — nnojötsü pütchi tü diccionariokat"
                : "'$clean' — palabra no está en el diccionario";
          result.writeln("⚠️ $notFound");
        }
      }
    } else {
      result.writeln("🇪🇸 Español → 🌵 Wayuunaiki\n");
      final words = text.toLowerCase().split(RegExp(r'\s+'));
      for (final word in words) {
        final clean = word.replaceAll(RegExp(r"[^\wáéíóúüñ']"), '');
        if (clean.isEmpty) continue;
        final way = _wayuuDict.lookupSpanish(clean);
        if (way != null) {
          result.writeln("• $clean → $way");
        } else {
          final notFound = _appLanguage == "Inglés"
              ? "'$clean' — word not found in dictionary"
              : _appLanguage == "Wayuunaiki"
                ? "'$clean' — nnojötsü pütchi tü diccionariokat"
                : "'$clean' — palabra no está en el diccionario";
          result.writeln("⚠️ $notFound");
        }
      }
    }
    _addMessage({"role": "glyph", "text": result.toString().trim()});
  }

  void _handleWayuuLookup(String word) {
    if (!_wayuuDict.isLoaded) {
      _addMessage({
        "role": "glyph",
        "text": "⏳ El diccionario aún se está cargando..."
      });
      return;
    }
    final direct = _wayuuDict.lookupAny(word);
    final fuzzy = _wayuuDict.fuzzySearch(word, limit: 5);

    final buffer = StringBuffer();
    buffer.writeln("📖 Búsqueda: \"$word\"");
    buffer.writeln("━━━━━━━━━━━━━━━━━━━━");

    if (direct != null) {
      buffer.writeln("\n✅ Resultado exacto:");
      buffer.writeln("  ${direct['wayuunaiki']}  →  ${direct['español']}");
    }

    if (fuzzy.isNotEmpty) {
      buffer.writeln("\n🔍 Palabras relacionadas:");
      for (final r in fuzzy) {
        buffer.writeln("  ${r['wayuunaiki']}  →  ${r['español']}");
      }
    }

    if (direct == null && fuzzy.isEmpty) {
      buffer.writeln("\n❌ No se encontró \"$word\" en el diccionario.");
      buffer.writeln("Prueba con otra palabra o escribe 'traducir [frase]'.");
    }

    _addMessage({"role": "glyph", "text": buffer.toString()});
  }

  void _syncP2PData() async {
    _toggleMenu();
    try {
      final file = await _exportDatabaseToCSV();
      _addMessage({
        "role": "glyph",
        "text":
            "He preparado los datos de la comunidad para sincronización física (P2P). Compártelos con otro promotor de salud para unir las bases de datos.",
        "type": "file_share",
        "data": {
          "path": file.path,
          "name": "sync_data.csv",
          "text": "Compartir datos para Sincronización"
        }
      });
    } catch (e) {
      _addMessage({"role": "glyph", "text": "Error al exportar datos: $e"});
    }
  }

  void _showEmergencyGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text("Suero Casero (Rehidratación)",
            style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. Un litro de agua hervida.",
                style: TextStyle(color: Colors.white70)),
            Text("2. 8 cucharaditas de azúcar.",
                style: TextStyle(color: Colors.white70)),
            Text("3. 1 cucharadita de sal.",
                style: TextStyle(color: Colors.white70)),
            SizedBox(height: 10),
            Text("🌵 Wayuunaiki:",
                style: TextStyle(
                    color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            Text(
                "Wane liitürü wüin lakalamasü. Mekisalü kuuchara asuuka. Wane kuuchara iichii.",
                style: TextStyle(
                    color: Colors.white, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Entendido",
                style: TextStyle(color: Colors.cyanAccent)),
          )
        ],
      ),
    );
  }

  Future<void> _showNutritionalControl() async {
    final patients = await DatabaseHelper.instance.getAllPatients();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text("Control Nutricional",
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: patients.isEmpty
              ? const Text("No hay datos guardados de niños.",
                  style: TextStyle(color: Colors.white70))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: patients.length,
                  itemBuilder: (ctx, i) {
                    final p = patients[i];
                    return ListTile(
                      title: Text(p['name'],
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text("ID: ${p['id']} - ${p['gender']}",
                          style: const TextStyle(color: Colors.white54)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.qr_code_2,
                                color: Colors.cyanAccent, size: 20),
                            onPressed: () => _showPatientQR(p),
                          ),
                          const Icon(Icons.android, color: Colors.cyanAccent),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _generatePatientReport(p);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cerrar",
                style: TextStyle(color: Colors.cyanAccent)),
          )
        ],
      ),
    );
  }

  void _showPatientQR(Map<String, dynamic> patient) async {
    final measurements =
        await DatabaseHelper.instance.getPatientMeasurements(patient['id']);
    if (measurements.isEmpty) return;

    final last = measurements.last;
    // Formato ultra-compacto para el QR: Nombre|Genero|Edad|Peso|Talla|Diagnostico
    final String qrData =
        "GLYPH|${patient['name']}|${patient['gender']}|${last['age_months']}|${last['weight_kg']}|${last['height_cm']}|${last['diagnosis']}";

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D1A),
        title: Text("Ficha Digital: ${patient['name']}",
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Escanea para transferir los datos de este paciente sin conexión.",
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: QrImageView(
                  data: qrData, version: QrVersions.auto, size: 200.0),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cerrar",
                  style: TextStyle(color: Colors.cyanAccent)))
        ],
      ),
    );
  }

  Future<void> _generatePatientReport(Map<String, dynamic> patient) async {
    final measurements =
        await DatabaseHelper.instance.getPatientMeasurements(patient['id']);

    String html = """
    <html>
      <head>
        <meta charset="utf-8">
        <title>Reporte Nutricional - ${patient['name']}</title>
        <style>
          body { font-family: sans-serif; padding: 20px; background: #f4f4f9; color: #333; }
          h1 { color: #0D0D1A; }
          table { width: 100%; border-collapse: collapse; margin-top: 20px; }
          th, td { border: 1px solid #ccc; padding: 10px; text-align: left; }
          th { background: #0D0D1A; color: white; }
          .chart { margin-top: 30px; padding: 20px; background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        </style>
      </head>
      <body>
        <h1>Reporte Nutricional Pediátrico</h1>
        <h2>Paciente: ${patient['name']}</h2>
        <p><strong>Género:</strong> ${patient['gender']} | <strong>Fecha de nacimiento:</strong> ${patient['birthDate'].split('T')[0]}</p>
        
        <table>
          <tr>
            <th>Fecha</th>
            <th>Edad (m)</th>
            <th>Peso (kg)</th>
            <th>Talla (cm)</th>
            <th>MUAC (cm)</th>
            <th>Z-WFA</th>
            <th>Z-HFA</th>
            <th>Diagnóstico</th>
          </tr>
    """;

    for (var m in measurements) {
      html += """
          <tr>
            <td>${m['date'].split('T')[0]}</td>
            <td>${m['age_months']}</td>
            <td>${m['weight_kg']}</td>
            <td>${m['height_cm']}</td>
            <td>${m['muac_cm'] ?? '-'}</td>
            <td>${m['z_wfa'].toStringAsFixed(2)}</td>
            <td>${m['z_hfa'].toStringAsFixed(2)}</td>
            <td>${m['diagnosis']}</td>
          </tr>
      """;
    }

    html += """
        </table>
        <div class="chart">
          <h3>Evolución y Gráficas</h3>
          <p>Para ver gráficas dinámicas de los indicadores Z, exporte la base de datos completa a CSV o utilice las gráficas mostradas en el historial de chat.</p>
        </div>
      </body>
    </html>
    """;

    final tempDir = await getTemporaryDirectory();
    final fileName =
        "reporte_${patient['name'].toString().replaceAll(' ', '_')}.html";
    final file = File("${tempDir.path}/$fileName");
    await file.writeAsString(html);

    _addMessage({
      "role": "glyph",
      "type": "file_share",
      "data": {
        "path": file.path,
        "name": fileName,
        "text":
            "He generado el reporte nutricional detallado de ${patient['name']}. Toca aquí para descargarlo o compartirlo."
      }
    });
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen)
        _menuAnimationController.forward();
      else
        _menuAnimationController.reverse();
    });
  }

  Future<File> _exportDatabaseToCSV() async {
    final patients = await DatabaseHelper.instance.getAllPatients();
    String csv =
        "ID,Nombre,Genero,FechaNacimiento,Medicion_ID,FechaMedicion,EdadMeses,PesoKg,TallaCm,Z_WFA,Z_HFA,Z_BMI,Diagnostico\n";
    for (var pat in patients) {
      final measurements =
          await DatabaseHelper.instance.getPatientMeasurements(pat['id']);
      if (measurements.isEmpty) {
        csv +=
            "${pat['id']},${pat['name']},${pat['gender']},${pat['birthDate']},,,,,,,,,\n";
      } else {
        for (var m in measurements) {
          csv +=
              "${pat['id']},${pat['name']},${pat['gender']},${pat['birthDate']},${m['id']},${m['date']},${m['age_months']},${m['weight_kg']},${m['height_cm']},${m['z_wfa']},${m['z_hfa']},${m['z_bmi']},${m['diagnosis']}\n";
        }
      }
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        p.join(dir.path, "base_datos_pediatrica_${DateTime.now().ms}.csv"));
    await file.writeAsString(csv);
    return file;
  }

  Future<void> _showGeneratedFiles() async {
    setState(() => _isMenuOpen = false);
    _menuAnimationController.reverse();

    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.csv'))
        .toList();

    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF121215),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Container(
              padding: const EdgeInsets.all(20),
              height: 350,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Archivos Generados",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 20),
                  if (files.isEmpty)
                    Expanded(
                        child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open,
                              color: Colors.white.withValues(alpha: 0.2),
                              size: 48),
                          const SizedBox(height: 10),
                          Text("No hay archivos generados aún",
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300)),
                        ],
                      ),
                    ))
                  else
                    Expanded(
                        child: ListView.builder(
                            itemCount: files.length,
                            itemBuilder: (ctx, i) {
                              return ListTile(
                                leading: const Icon(Icons.table_chart,
                                    color: Colors.greenAccent),
                                title: Text(p.basename(files[i].path),
                                    style:
                                        const TextStyle(color: Colors.white)),
                                trailing: const Icon(Icons.share,
                                    color: Colors.white54),
                                onTap: () {
                                  Share.shareXFiles([XFile(files[i].path)]);
                                },
                              );
                            }))
                ],
              ));
        });
  }

  void _performAnthroCalculation(
      String nombre, int edad, double peso, double talla, String genero,
      {double? muacCm, int? ageInDays}) {
    AnthroResult result;
    try {
       result = AnthroService.calculate(edad, peso, talla, genero, muacCm: muacCm, ageInDays: ageInDays);
    } catch (e) {
       _addMessage({"role": "glyph", "text": "Error en el cálculo: Los datos ingresados son extremos o inválidos."});
       return;
    }
    setState(() => _lastManualDiagnosis = result.diagnosis);

    String simplifiedDiag = "";
    if (result.diagnosis.contains("Normal")) {
      simplifiedDiag =
          "Está creciendo sano y fuerte. Recomendación: Continúe alimentándolo con comida local variada y mucho amor. ¡Sigan así!\n\n🌵 Wayuunaiki: Waima ni'iruku, katsinshi nia. Anashii pükülin nia sümaa eküülü anasü. ¡Müle'u chia!";
    } else if (result.diagnosis.contains("Desnutrición") ||
        result.diagnosis.contains("Delgadez")) {
      simplifiedDiag =
          "Precaución. Necesita atención urgente. Recomendación: Por favor, lleve al niño al centro de salud más cercano lo antes posible para que un profesional lo evalúe.\n\n🌵 Wayuunaiki: Jülüja aa'in. Cho'ujaasü ataralü mma'ana. Püshajaa chi jintükai eemüin tü piichi ataralü eesü kasakai.";
    } else if (result.diagnosis.contains("Sobrepeso") ||
        result.diagnosis.contains("Obesidad")) {
      simplifiedDiag =
          "Precaución. Tiene exceso de peso. Recomendación: Por favor, intente dar una alimentación más balanceada y consulte con un profesional.\n\n🌵 Wayuunaiki: Jülüja aa'in. Alatusü nutuma. Pükülin nia sümaa eküülü anasü siia püshajaa chi eekai atüjain.";
    }

    if (result.muacDiagnosis.isNotEmpty) {
      simplifiedDiag += "\n\nMUAC: " + result.muacDiagnosis;
    }

    final speechText = "He registrado a $nombre. $simplifiedDiag";

    String zFormat(double v) => v == -99.0 ? 'N/A' : v.toStringAsFixed(2);

    final zScoreText =
        '📊 Datos: $edad m, $peso kg, $talla cm\nZ-Scores: WFA: ${zFormat(result.zWeightForAge)}, HFA: ${zFormat(result.zHeightForAge)}, BMI: ${zFormat(result.zBmiForAge)}, W/H: ${zFormat(result.zWeightForHeight)}\nDiagnóstico: ${result.diagnosis}${result.muacDiagnosis.isNotEmpty ? '\n${result.muacDiagnosis}' : ''}';

    _addMessage({
      "role": "glyph",
      "type": "anthro_chart",
      "text": zScoreText,
      "data": {
        "edad": edad,
        "peso": peso,
        "talla": talla,
        "genero": genero,
        "diag": "${result.diagnosis} / ${_getWayuuDiagnosis(result.diagnosis)}",
        "text": speechText
      }
    });

    // Primero habla en español; cuando termine, reproduce el audio en Wayuunaiki
    String? wayuuAudio;
    if (result.diagnosis.contains("Normal")) {
      wayuuAudio = 'wayuu_sano.mp3';
    } else if (result.diagnosis.contains("Desnutrición") ||
        result.diagnosis.contains("Delgadez")) {
      wayuuAudio = 'wayuu_peligro.mp3';
    } else if (result.diagnosis.contains("Sobrepeso") ||
        result.diagnosis.contains("Obesidad")) {
      wayuuAudio = 'wayuu_precaucion.mp3';
    }

    if (wayuuAudio != null) {
      final audioFile = wayuuAudio; // captura local para el closure
      _flutterTts.setCompletionHandler(() {
        _audioPlayer.play(AssetSource(audioFile));
        // Limpiar el handler para que no se dispare en futuras reproducciones
        _flutterTts.setCompletionHandler(() {});
      });
    }

    _flutterTts.speak(speechText);

    DatabaseHelper.instance.getAllPatients().then((patients) {
      final existing = patients
          .where(
              (p) => p['name'].toString().toLowerCase() == nombre.toLowerCase())
          .toList();

      void saveMeasurement(int pid) {
        DatabaseHelper.instance.insertMeasurement({
          "patient_id": pid,
          "date": DateTime.now().toIso8601String(),
          "age_months": edad,
          "weight_kg": peso,
          "height_cm": talla,
          "bmi": 0.0,
          "z_wfa": result.zWeightForAge,
          "z_hfa": result.zHeightForAge,
          "z_bmi": result.zBmiForAge,
          "diagnosis": result.diagnosis,
          "muac_cm": muacCm
        });
        if (mounted) {
          // Z-Scores ya enviados en el mensaje principal
        }
      }

      if (existing.isNotEmpty) {
        saveMeasurement(existing.first['id']);
      } else {
        DatabaseHelper.instance.insertPatient({
          "name": nombre,
          "gender": genero,
          "birthDate": DateTime.now()
              .subtract(Duration(days: edad * 30))
              .toIso8601String()
        }).then((pid) {
          saveMeasurement(pid);
        });
      }
    });
  }

  void _performGestationalCalculation(
      String nombre, int semanas, double peso, double talla) {
    final result = AnthroService.calculateGestational(semanas, peso, talla);
    setState(() => _lastManualDiagnosis = result.diagnosis);

    String simplifiedDiag = "";
    if (result.diagnosis.contains("Normal")) {
      simplifiedDiag =
          "Su estado nutricional es adecuado para las $semanas semanas de gestación. Recomendación: Continúe con su alimentación balanceada y asista a sus controles prenatales.\n\n🌵 Wayuunaiki: Anashii tü pükülinka süpüla $semanas semanas kachonwa'a pia. Püküla eküülü anasü siia püshajaa chi eekai atüjain.";
    } else if (result.diagnosis.contains("Bajo Peso")) {
      simplifiedDiag =
          "Precaución. Su peso es bajo para las $semanas semanas de gestación. Recomendación: Aumente la ingesta de proteínas y energía, y consulte con su nutricionista en el próximo control.\n\n🌵 Wayuunaiki: Jülüja aa'in. Pe'u pia süpüla $semanas semanas kachonwa'a pia. Püküla eküülü katsinsü siia püshajaa chi eekai atüjain.";
    } else if (result.diagnosis.contains("Sobrepeso") ||
        result.diagnosis.contains("Obesidad")) {
      simplifiedDiag =
          "Precaución. Su peso es superior al recomendado para las $semanas semanas. Recomendación: Cuide las porciones de carbohidratos y grasas, y manténgase activa según lo permita su médico.\n\n🌵 Wayuunaiki: Jülüja aa'in. Alatusü pütuma süpüla $semanas semanas. Püküla eküülü anasü siia nnojot pülatüin pütuma.";
    }

    final speechText = "He registrado a la gestante $nombre. $simplifiedDiag";
    final zScoreText =
        'IMC Gestacional: ${result.bmi.toStringAsFixed(1)}\nSemanas: $semanas\nDiagnóstico: ${result.diagnosis}';

    _addMessage({
      "role": "glyph",
      "type":
          "anthro_chart", // Reutilizamos el widget de gráfico o mostramos el texto
      "text": zScoreText,
      "data": {
        "edad": semanas,
        "peso": peso,
        "talla": talla,
        "genero": "f",
        "diag": "${result.diagnosis} / ${_getWayuuDiagnosis(result.diagnosis)}",
        "text": speechText
      }
    });

    String? wayuuAudio;
    if (result.diagnosis.contains("Normal")) {
      wayuuAudio = 'wayuu_sano.mp3';
    } else if (result.diagnosis.contains("Bajo Peso")) {
      wayuuAudio = 'wayuu_peligro.mp3';
    } else if (result.diagnosis.contains("Sobrepeso") ||
        result.diagnosis.contains("Obesidad")) {
      wayuuAudio = 'wayuu_precaucion.mp3';
    }

    if (wayuuAudio != null) {
      final audioFile = wayuuAudio;
      _flutterTts.setCompletionHandler(() {
        _audioPlayer.play(AssetSource(audioFile));
        _flutterTts.setCompletionHandler(() {});
      });
    }

    _flutterTts.speak(speechText);

  }

  void _performAdultCalculation(
      String nombre, double peso, double talla, String genero) {
    final result = AnthroService.calculateAdult(peso, talla);
    setState(() => _lastManualDiagnosis = result.diagnosis);

    String simplifiedDiag = "";
    if (result.diagnosis.contains("Normal")) {
      simplifiedDiag =
          "Su IMC es normal. Recomendación: Mantenga una dieta equilibrada y actividad física regular.\n\n🌵 Wayuunaiki: Anashii tü pükülinka. Püküla eküülü anasü siia püshajaa chi eekai atüjain.";
    } else if (result.diagnosis.contains("Delgadez")) {
      simplifiedDiag =
          "Precaución. Su IMC indica delgadez. Recomendación: Aumente la ingesta calórica con alimentos nutritivos y consulte a un nutricionista.\n\n🌵 Wayuunaiki: Jülüja aa'in. Pe'u pia. Püküla eküülü katsinsü siia püshajaa chi eekai atüjain.";
    } else if (result.diagnosis.contains("Sobrepeso") ||
        result.diagnosis.contains("Obesidad")) {
      simplifiedDiag =
          "Precaución. Su IMC indica exceso de peso. Recomendación: Reduzca el consumo de azúcares y grasas saturadas, y aumente la actividad física.\n\n🌵 Wayuunaiki: Jülüja aa'in. Alatusü pütuma. Püküla eküülü anasü siia nnojot pülatüin pütuma.";
    }

    final speechText = "He registrado al adulto $nombre. $simplifiedDiag";
    final zScoreText =
        'IMC Adulto: ${result.bmi.toStringAsFixed(1)}\nDiagnóstico: ${result.diagnosis}';

    _addMessage({
      "role": "glyph",
      "type": "anthro_chart",
      "text": zScoreText,
      "data": {
        "edad": 25, // Referencia genérica para adultos
        "peso": peso,
        "talla": talla,
        "genero": genero,
        "diag": "${result.diagnosis} / ${_getWayuuDiagnosis(result.diagnosis)}",
        "text": speechText
      }
    });

    String? wayuuAudio;
    if (result.diagnosis.contains("Normal")) {
      wayuuAudio = 'wayuu_sano.mp3';
    } else if (result.diagnosis.contains("Delgadez")) {
      wayuuAudio = 'wayuu_peligro.mp3';
    } else if (result.diagnosis.contains("Sobrepeso") ||
        result.diagnosis.contains("Obesidad")) {
      wayuuAudio = 'wayuu_precaucion.mp3';
    }

    if (wayuuAudio != null) {
      final audioFile = wayuuAudio;
      _flutterTts.setCompletionHandler(() {
        _audioPlayer.play(AssetSource(audioFile));
        _flutterTts.setCompletionHandler(() {});
      });
    }

    _flutterTts.speak(speechText);
  }

  // Convierte palabras numéricas en español a enteros
  int? _spanishWordToNumber(String word) {
    const map = {
      "cero": 0,
      "uno": 1,
      "dos": 2,
      "tres": 3,
      "cuatro": 4,
      "cinco": 5,
      "seis": 6,
      "siete": 7,
      "ocho": 8,
      "nueve": 9,
      "diez": 10,
      "once": 11,
      "doce": 12,
      "trece": 13,
      "catorce": 14,
      "quince": 15,
      "dieciséis": 16,
      "diecisiete": 17,
      "dieciocho": 18,
      "diecinueve": 19,
      "veinte": 20,
      "veintiuno": 21,
      "veintidós": 22,
      "veintitrés": 23,
      "veinticuatro": 24,
      "veinticinco": 25,
      "veintiséis": 26,
      "veintisiete": 27,
      "veintiocho": 28,
      "veintinueve": 29,
      "treinta": 30,
      "cuarenta": 40,
      "cincuenta": 50,
      "sesenta": 60,
    };
    return map[word.toLowerCase().trim()];
  }

  String _getWayuuDiagnosis(String diag) {
    if (diag.contains("Normal")) return "Anasü (Normal)";
    if (diag.contains("Desnutrición") ||
        diag.contains("Delgadez") ||
        diag.contains("Bajo Peso")) return "Mootshishi / Pe'u (Bajo Peso)";
    if (diag.contains("Sobrepeso") || diag.contains("Obesidad"))
      return "Pootshishii / Alatusü (Exceso)";
    return diag;
  }

  void _tryManualExtraction(String userText) {
    final lower = userText.toLowerCase();

    if (_isRiskAssessmentMode) {
      bool isYes = lower.trim() == "si" ||
          lower.contains("si ") ||
          lower.contains("sí") ||
          lower.contains("yes") ||
          lower.contains("aashin") ||
          lower.contains("tiene") ||
          lower.contains("si,");
      bool isNo = lower.trim() == "no" ||
          lower.contains("no ") ||
          lower.contains("nnojo") ||
          lower.contains("no,");

      if (_pendingRiskName == null) {
        // Estamos esperando el nombre
        final nameMatch = RegExp(r"\b([A-Z][a-záéíóúñ]+)\b").firstMatch(userText);
        _pendingRiskName = nameMatch?.group(1) ?? userText.split(' ').last;
        
        _addMessage({
          "role": "glyph",
          "text": _appLanguage == "Wayuunaiki"
              ? "Anasü. ¿Chi tepichikai $_pendingRiskName nnojotsü anain nukuwa'ipa?\n¿Kachisü nüpüla tüü?\n• Atünasü/kache'esü nüpüla (Cabello seco)\n• Yutusu no'u (Ojos hundidos)\n• Jousü nierü (Abdomen abultado)\n• Alatiraa/Jemeta (Diarrea/Gripa)\n• Nnojoishii ekaain (Inapetencia)\n¿Aashin wanee?"
              : _appLanguage == "Inglés"
                  ? "Understood. Does $_pendingRiskName have any of these alert signs?\n• Dry hair/falling face, pale/swollen face, sunken eyes\n• Dry/flaky skin, very thin/swollen limbs\n• Swollen abdomen\n• Frequent diarrhea/flu\n• Loss of appetite, fatigue, or extreme irritability\nPlease reply YES or NO."
                  : "Entendido. Dime si $_pendingRiskName presenta alguno de estos signos de alerta:\n• Cabello seco, escaso o que cambia de color\n• Rostro hinchado y pálido, u ojos hundidos\n• Piel muy seca, extremidades muy delgadas o inflamadas\n• Abdomen abultado\n• Diarrea o gripa frecuente\n• Desgano, inapetencia o llanto excesivo\n¿Presenta alguno de estos signos?"
        });
        return;
      }

      if (isYes) {
        final nombre = _pendingRiskName ?? "Paciente";
        DatabaseHelper.instance.insertRiskPatient(nombre, userText);
        
        _addMessage({
           "role": "glyph",
           "text": _appLanguage == "Inglés" ? "ALERT: Severe malnutrition signs detected for $nombre. Saved in the Risk Database. Please go to a health center immediately."
           : "ALERTA: Se han detectado signos graves de desnutrición en $nombre. Caso guardado en la Base de Datos de Riesgo. Por favor, acuda a un centro de salud inmediatamente."
        });
        setState(() {
          _isRiskAssessmentMode = false;
          _pendingRiskName = null;
        });
        return;
      } else if (isNo) {
        _addMessage({
           "role": "glyph",
           "text": _appLanguage == "Inglés" ? "That's good. Since there are no severe alert signs for $_pendingRiskName, ensure a balanced diet."
           : "Excelente. Al no presentar $_pendingRiskName estos signos de alerta graves, asegúrese de mantener una alimentación balanceada."
        });
        setState(() {
          _isRiskAssessmentMode = false;
          _pendingRiskName = null;
        });
        return;
      }
    }

    // ── Edad ─────────────────────────────────────────────────────────────────
    int? edad;

    // 1. Buscar Años (ej. "1 año", "un año", "2 años")
    int years = 0;
    final yearDigitMatch = RegExp(r"(\d+)\s*años?").firstMatch(lower);
    if (yearDigitMatch != null) {
      years = int.tryParse(yearDigitMatch.group(1)!) ?? 0;
    } else {
      final yearWordMatch = RegExp(r"(\w+)\s+años?").firstMatch(lower);
      if (yearWordMatch != null) {
        years = _spanishWordToNumber(yearWordMatch.group(1)!) ?? 0;
      }
    }

    // 2. Buscar Meses (ej. "12 meses", "doce meses")
    int months = 0;
    final monthDigitMatch = RegExp(r"(\d+)\s*mes(es)?").firstMatch(lower);
    if (monthDigitMatch != null) {
      months = int.tryParse(monthDigitMatch.group(1)!) ?? 0;
    } else {
      final monthWordMatch = RegExp(r"(\w+)\s+mes(es)?").firstMatch(lower);
      if (monthWordMatch != null) {
        months = _spanishWordToNumber(monthWordMatch.group(1)!) ?? 0;
      }
    }

    // Calcular edad total en meses
    if (years > 0 || months > 0) {
      edad = (years * 12) + months;
    }

    // ── Peso ─────────────────────────────────────────────────────────────────
    // Número + kg/kilos (ej. "3kg", "3 kg", "3 kilos")
    double? peso;
    final weightDigitMatch =
        RegExp(r"(\d+(\.\d+)?)\s*(kg|kilos?|kilo)").firstMatch(lower);
    if (weightDigitMatch != null) {
      peso = double.tryParse(weightDigitMatch.group(1)!);
    } else {
      // Palabra numérica + kg (ej. "tres kg")
      final weightWordMatch =
          RegExp(r"([a-z]+)\s*(kg|kilos?|kilo)").firstMatch(lower);
      if (weightWordMatch != null) {
        final n = _spanishWordToNumber(weightWordMatch.group(1)!);
        if (n != null) peso = n.toDouble();
      }
    }

    // ── Talla ─────────────────────────────────────────────────────────────────
    double? talla;
    // Capturamos metros y centímetros (ej. "un metro cuarenta", "1.40 metros", "140 cm")
    final meterMatch = RegExp(r"(\d+(\.\d+)?|un)\s*metros?\s*(\d+(\.\d+)?|(\w+))?").firstMatch(lower);
    if (meterMatch != null) {
      double m = 0;
      if (meterMatch.group(1) == "un") m = 1.0;
      else m = double.tryParse(meterMatch.group(1)!) ?? 0;
      
      double cm = 0;
      if (meterMatch.group(3) != null) {
        cm = double.tryParse(meterMatch.group(3)!) ?? (_spanishWordToNumber(meterMatch.group(3)!)?.toDouble() ?? 0);
      }
      talla = (m * 100) + cm;
    } else {
      // Capturamos opcionalmente "ciento" antes de los dígitos o la palabra
      final heightCientoMatch = RegExp(r"(ciento\s+)?(\d+(\.\d+)?)\s*cm").firstMatch(lower);
      if (heightCientoMatch != null) {
        talla = double.tryParse(heightCientoMatch.group(2)!);
        if (talla != null && heightCientoMatch.group(1) != null) {
          talla += 100;
        }
      } else {
        final heightWordMatch = RegExp(r"(ciento\s+)?(\w+)\s*cm").firstMatch(lower);
        if (heightWordMatch != null) {
          final n = _spanishWordToNumber(heightWordMatch.group(2)!);
          if (n != null) {
            talla = n.toDouble();
            if (heightWordMatch.group(1) != null) talla += 100;
          }
        }
      }
    }

    // ── Nombre y género ───────────────────────────────────────────────────────
    final nameMatch = RegExp(r"\b([A-Z][a-záéíóúñ]+)\b").firstMatch(userText);
    final nombre = nameMatch?.group(1) ?? "Niño";
    final genero =
        (lower.contains("niña") || lower.contains("femenino") || lower.contains("mujer") || lower.contains("jintü")) ? "f" : "m";

    // ── Extracción Gestacional ───────────────────────────────────────────────
    if (lower.contains("embarazada") || lower.contains("gestante") || lower.contains("semanas")) {
      int? semanas;
      final weekMatch = RegExp(r"(\d+)\s*semana").firstMatch(lower);
      if (weekMatch != null) semanas = int.tryParse(weekMatch.group(1)!);
      
      if (semanas != null || peso != null || talla != null) {
        if (semanas == null || peso == null || talla == null) {
          List<String> missing = [];
          if (semanas == null) missing.add("Semanas de gestación");
          if (peso == null) missing.add("Peso (kg)");
          if (talla == null) missing.add("Talla (cm)");
          _addMessage({"role": "glyph", "text": "Para completar el diagnóstico gestacional de $nombre, necesito los datos faltantes que son: ${missing.join(', ')}."});
          return;
        } else {
          _performGestationalCalculation(nombre, semanas, peso, talla);
          return;
        }
      }
    }

    // ── Extracción Adulto explícito ──────────────────────────────────────────
    bool isAdultMode = lower.contains("adulto") || lower.contains("señor") || lower.contains("señora") || lower.contains("persona mayor") || (edad != null && edad > 228);
    if (isAdultMode) {
      if (peso != null || talla != null || (edad != null && edad > 228)) {
        if (peso == null || talla == null) {
          List<String> missing = [];
          if (peso == null) missing.add("Peso (kg)");
          if (talla == null) missing.add("Talla (cm)");
          _addMessage({"role": "glyph", "text": "Para completar el diagnóstico de adulto de $nombre, necesito los datos faltantes que son: ${missing.join(', ')}."});
          return;
        } else {
          _performAdultCalculation(nombre, peso, talla, genero);
          return;
        }
      }
    }

    // ── Extracción Pediátrico ────────────────────────────────────────────────
    bool hasPartialData = edad != null || peso != null || talla != null;
    if (hasPartialData) {
      if (edad == null || peso == null || talla == null) {
        List<String> missing = [];
        if (edad == null) missing.add("Edad (meses/años)");
        if (peso == null) missing.add("Peso (kg)");
        if (talla == null) missing.add("Talla (cm)");
        
        _addMessage({
          "role": "glyph",
          "text": "Para completar el diagnóstico pediátrico de $nombre, necesito los datos faltantes que son: ${missing.join(', ')}."
        });
        return;
      } else {
        _performAnthroCalculation(nombre, edad, peso, talla, genero);
        return;
      }
    }
  }

  Future<void> _handleWakeOnLan() async {
    String? mac = await DatabaseHelper.instance.getSetting('pc_mac');
    if (mac == null || mac.isEmpty) {
      // He pre-configurado tu dirección MAC Acer aquí
      mac = "48:A4:72:FB:C0:ED";
      await DatabaseHelper.instance.setSetting('pc_mac', mac);
    }
    await _performWakeOnLan(mac);
  }

  Future<void> _performWakeOnLan(String mac) async {
    try {
      final macAddress = MACAddress(mac);

      // Lista de configuraciones para probar (Puertos 7 y 9, Difusión Global y Local)
      final configs = [
        {'ip': '255.255.255.255', 'port': 9},
        {'ip': '192.168.1.255', 'port': 9},
        {'ip': '255.255.255.255', 'port': 7},
        {'ip': '192.168.1.255', 'port': 7},
      ];

      for (var config in configs) {
        final ip = config['ip'] as String;
        final port = config['port'] as int;
        final wol = WakeOnLAN(IPAddress(ip), macAddress, port: port);

        // Enviamos ráfagas por cada configuración
        for (int i = 0; i < 3; i++) {
          await wol.wake();
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      _addMessage({
        "role": "glyph",
        "text":
            "🚀 Ráfaga de encendido enviada (Puertos 7/9, IP Global/Local). Si sigue sin despertar, es posible que el Wi-Fi de tu laptop Acer se desconecte totalmente en modo S0."
      });
    } catch (e) {
      _addMessage({
        "role": "glyph",
        "text": "❌ Error al intentar encender la computadora: $e"
      });
    }
  }

  Future<String> _analyzeImageOffline(String base64Image) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_analysis.jpg');
      await tempFile.writeAsBytes(base64Decode(base64Image));

      final inputImage = InputImage.fromFilePath(tempFile.path);
      final imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
      final labels = await imageLabeler.processImage(inputImage);
      
      if (labels.isEmpty) return "una imagen sin objetos claros";
      
      String desc = labels.take(3).map((l) => l.label).join(", ");
      await imageLabeler.close();
      return "una imagen que contiene: $desc";
    } catch (e) {
      return "una imagen (error de visión: $e)";
    }
  }
}

extension DateExt on DateTime {
  int get ms => millisecondsSinceEpoch;
}
