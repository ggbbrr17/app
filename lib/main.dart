import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'anthro_service.dart';
import 'anthro_chart_widget.dart';
import 'database_helper.dart';
import 'model_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

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
                animationValue: 0.0, isThinking: false, isRecording: false, opacity: 0.18),
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
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                top: isOpen ? 23 : 16,
                child: AnimatedRotation(
                    duration: const Duration(milliseconds: 500),
                    turns: isOpen ? 0.125 : 0,
                    child: Container(
                        width: 26, height: 2.5, color: Colors.white))),
            AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isOpen ? 0.0 : 1.0,
                child: Container(width: 16, height: 2.5, color: Colors.white)),
            AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                bottom: isOpen ? 23 : 16,
                child: AnimatedRotation(
                    duration: const Duration(milliseconds: 500),
                    turns: isOpen ? -0.125 : 0,
                    child: Container(
                        width: 26, height: 2.5, color: Colors.white))),
          ],
        ),
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
  String? _pendingImageBase64, _pendingImageName;
  final List<List<Map<String, dynamic>>> _chatSessions = [];
  
  bool _isOfflineMode = false;
  InferenceModel? _gemmaModel;
  InferenceChat? _gemmaChat;
  bool _isTutorMode = false;
  String? _lastManualDiagnosis;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  final StreamController<double> _downloadProgressController = StreamController<double>.broadcast();
  Stream<double> get _downloadProgressStream => _downloadProgressController.stream;

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
    WidgetsBinding.instance.addObserver(this);
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
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
    _loadPersistedHistory();
  }

  Future<void> _loadPersistedHistory() async {
    final sessions = await DatabaseHelper.instance.getSessions();
    if (sessions.isEmpty) {
      _currentSessionId = await DatabaseHelper.instance.createSession();
      final defaultMsg = {
        "role": "glyph",
        "text": "¡Hola! Soy Glyph, tu asistente de salud pediátrica y nutricional.\n\nPuedo ayudarte con lo siguiente:\n1. 📊 Calcular el estado nutricional (Envíame: Nombre, Edad en meses, Peso, Talla, Género y Perímetro Braquial opcional).\n2. 📸 Identificar alimentos: Envíame una foto de comida y te daré su valor nutricional y recomendaciones.\n3. 🌱 Tutor Agrícola: Pregúntame cómo cultivar Frijol Guajirito o Moringa.\n\n🌵 Wayuunaiki:\nTaya Glyph, tü pütchipü'üka pia süpüla kaa'uleein chi tepichikai. Eesü süpüla tatüjaain:\n1. 📊 Tayaa tü kaa'uleein: Pütchajaa jintüt, kachon, nutuma, nütüjülü, tepichi o jintü, siia muac.\n2. 📸 Tayaa tü eküülü: Püshajaa wanee ayaakuaa süpüla tatüjaain tü eküülüka.\n3. 🌱 Ekirajüi: Püshajaa taya süpüla tapüla wunu'u (Frijol Guajirito o Moringa)."
      };
      await DatabaseHelper.instance.insertMessage(_currentSessionId!, defaultMsg);
      setState(() {
        _messages.add(defaultMsg);
      });
    } else {
      _currentSessionId = sessions.first['id'];
      final msgs = await DatabaseHelper.instance.getSessionMessages(_currentSessionId!);
      setState(() {
        _messages.clear();
        _messages.addAll(msgs.map((m) => {
          "role": m['role'],
          "text": m['text'],
          "type": m['type'],
          "data": m['data'] != null ? jsonDecode(m['data']) : null,
          "isThought": m['isThought'] == 1,
        }));
      });
      
      _chatSessions.clear();
      _sessionIds.clear();
      for (var session in sessions) {
        _sessionIds.add(session['id']);
        final sMsgs = await DatabaseHelper.instance.getSessionMessages(session['id']);
        _chatSessions.add(sMsgs.map((m) => {
          "role": m['role'],
          "text": m['text'],
          "type": m['type'],
          "data": m['data'] != null ? jsonDecode(m['data']) : null,
          "isThought": m['isThought'] == 1,
        }).toList());
      }
    }
    _scrollToBottom();
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
    var notificationDetails = fln.NotificationDetails(iOS: fln.DarwinNotificationDetails());
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
    _playWaterSound();
    FilePickerResult? res =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null) {
      final bytes = await File(res.files.single.path!).readAsBytes();
      setState(() {
        _isMenuOpen = false;
        _showTextField = true;
        _pendingImageBase64 = base64Encode(bytes);
        _pendingImageName = res.files.single.name;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? res =
        await FilePicker.platform.pickFiles(type: FileType.any);
    if (res != null && res.files.single.path != null) {
      final bytes = await File(res.files.single.path!).readAsBytes();
      setState(() {
        _isMenuOpen = false;
        _menuAnimationController.reverse();
        _showTextField = true;
        _pendingImageBase64 = base64Encode(bytes);
        _pendingImageName = res.files.single.name;
      });
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final path = p.join((await getTemporaryDirectory()).path,
          'audio_${DateTime.now().ms}.m4a');
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
    }
  }

  Future<String?> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    return path != null ? base64Encode(await File(path).readAsBytes()) : null;
  }

  Future<void> _initGemmaChat() async {
    final manager = ModelManager();
    await manager.initializeGemma();

    _gemmaModel = await FlutterGemma.getActiveModel(maxTokens: 1024);
    _gemmaChat = await _gemmaModel!.createChat(
      supportsFunctionCalls: true,
      toolChoice: ToolChoice.auto,
      tools: [
        Tool(
          name: "registrar_medicion_pediatrica",
          description: "IMPORTANT: Use this tool ALWAYS when the user provides pediatric data (name, age, weight, height, gender) to calculate the nutritional diagnosis. Data: Pedro, 12 months, 0kg, 60cm, male.",
          parameters: {
            "type": "object",
            "properties": {
              "nombre": {"type": "string", "description": "Nombre del niño"},
              "edad_meses": {"type": "integer", "description": "Edad en meses"},
              "peso_kg": {"type": "number", "description": "Peso en kilogramos"},
              "talla_cm": {"type": "number", "description": "Talla en centímetros"},
              "genero": {"type": "string", "description": "Género (m o f)"},
              "muac_cm": {"type": "number", "description": "Perímetro Braquial o MUAC en centímetros (opcional)"}
            },
            "required": ["nombre", "edad_meses", "peso_kg", "talla_cm", "genero"]
          }
        ),
        Tool(
          name: "exportar_base_datos",
          description: "Exporta y descarga la base de datos completa de pacientes pediátricos en formato CSV.",
          parameters: {"type": "object", "properties": {}}
        )
      ]
    );

    await _gemmaChat!.addQuery(Message(
      text: "Eres un asistente de salud pediátrica. Tu regla de oro es: SIEMPRE que te den un nombre, edad, peso y talla, DEBES usar la herramienta 'registrar_medicion_pediatrica'. No respondas con texto plano si puedes usar la herramienta.",
      isUser: false
    ));
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
        _addMessage({"role": "glyph", "text": "✅ ¡Modelo Gemma 4 cargado! Funcionando 100% offline."});
      } catch (e) {
        _addMessage({"role": "glyph", "text": "⚠️ El archivo del modelo local no se encontró o está corrupto. Descargando de nuevo..."});
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Descargando Gemma 4 E2B",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300, letterSpacing: 1)),
            content: StatefulBuilder(
              builder: (_, __) => StreamBuilder<double>(
                stream: _downloadProgressStream,
                builder: (_, snap) {
                  final p = snap.data ?? 0.0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("El modelo pesa ~2 GB.\nAsegúrate de tener buena conexión.",
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: p > 0 ? p : null,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(p > 0 ? "${(p * 100).toStringAsFixed(1)}%" : "Iniciando...",
                          style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
          _addMessage({"role": "glyph", "text": "✅ ¡Gemma 4 descargado y listo! Funcionando 100% offline."});
        } catch (e) {
          _addMessage({"role": "glyph", "text": "❌ Error al inicializar el modelo: $e"});
        } finally {
          setState(() => _isThinking = false);
          _scrollToBottom();
        }
      },
      onError: (err) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        _addMessage({"role": "glyph", "text": "❌ Error al descargar el modelo: $err"});
        _scrollToBottom();
      },
    );
  }

  Future<void> _sendMultimodalData(
      {String question = "", String? base64Image, String? base64Audio}) async {
    setState(() => _isThinking = true);

    String finalQuestion = question;
    if (base64Image != null) {
      finalQuestion = "INSTRUCCIÓN ESPECIAL: Identifica los alimentos en la imagen adjunta (si no la puedes ver, asume que es una imagen de comida relacionada con la pregunta). Da explicaciones nutricionales detalladas en Español y Wayuunaiki del alimento, y brinda recomendaciones. \nPREGUNTA: " + question;
    }

    if (_isOfflineMode && _gemmaChat != null) {
      try {
        if (base64Audio != null) {
          setState(() {
            _messages.add({"role": "glyph", "text": "El modo offline local actualmente no soporta audio. Ignorándolo."});
          });
          _scrollToBottom();
        }
        
        String finalQuestion = question;
        if (_lastManualDiagnosis != null) {
          finalQuestion = "SISTEMA: Ya se calculó el estado nutricional: $_lastManualDiagnosis. "
              "INSTRUCCIÓN: No repitas el diagnóstico técnico. "
              "Si estás en 'Modo Tutor', da recomendaciones sobre Frijol Guajirito o Moringa en Wayuunaiki basándote en este diagnóstico. "
              "Si no, da un mensaje breve de apoyo. "
              "PREGUNTA DEL USUARIO: $question";
          _lastManualDiagnosis = null; // Limpiar para el siguiente mensaje
        } else if (_isTutorMode) {
          finalQuestion = "ROL: Eres un profesor experto en agricultura de La Guajira. "
              "REGLA CRÍTICA: Cada mensaje debe ser BILINGÜE (Español y Wayuunaiki). "
              "TEMAS: Frijol Guajirito y Moringa. "
              "Si el usuario elige uno, explica el proceso de cultivo DESDE CERO (preparación, siembra, riego, cosecha). "
              "Sé paciente y educativo. "
              "PREGUNTA DEL USUARIO: $question";
        }
        
        await _gemmaChat!.addQuery(Message(
          text: finalQuestion, 
          isUser: true,
          imageBytes: base64Image != null ? base64Decode(base64Image) : null
        ));
        
        // Intentar extracción directa SIEMPRE, antes de la respuesta del modelo
        _tryManualExtraction(question);
        
        final response = await _gemmaChat!.generateChatResponse();
        
        if (response is TextResponse) {
           // Solo mostrar el texto si NO era una solicitud de cálculo (ya procesada arriba)
           final hasCalcData = RegExp(r"\d+\s*m[ea]s|\w+\s+m[ea]s").hasMatch(question.toLowerCase());
           if (!hasCalcData) {
             _addMessage({"role": "glyph", "text": response.token});
           }
        } else if (response is FunctionCallResponse) {
           if (response.name == "registrar_medicion_pediatrica") {
             _performAnthroCalculation(
               response.args['nombre'] ?? "Niño",
               response.args['edad_meses'] ?? 0,
               (response.args['peso_kg'] as num).toDouble(),
               (response.args['talla_cm'] as num).toDouble(),
               response.args['genero'] ?? "m",
               muacCm: response.args['muac_cm'] != null ? (response.args['muac_cm'] as num).toDouble() : null
             );
           } else if (response.name == "exportar_base_datos") {
             final csvFile = await _exportDatabaseToCSV();
             _addMessage({
                "role": "glyph", 
                "type": "file_share",
                "data": {"path": csvFile.path, "name": "base_datos_pediatrica.csv", "text": "He exportado la base de datos a CSV. Toca aquí para compartirla o descargarla."}
             });
           }
        }
        _scrollToBottom();
      } catch (e) {
        _addMessage({"role": "glyph", "text": "Error interno del modelo local: $e"});
        _scrollToBottom();
      } finally {
        setState(() => _isThinking = false);
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
        "base64_image": base64Image,
        "base64_audio": base64Audio
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
        _addMessage({"role": "glyph", "text": data['message'] ?? "..."});
      }
    } finally {
      setState(() => _isThinking = false);
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

    if (text.toLowerCase().contains("genera el archivo") || text.toLowerCase().contains("exportar")) {
       _exportDatabaseToCSV().then((csvFile) {
         _addMessage({
            "role": "glyph", 
            "type": "file_share",
            "data": {"path": csvFile.path, "name": "base_datos_pediatrica.csv", "text": "He generado el archivo de la base de datos. Toca aquí para compartirlo."}
         });
       });
       return;
    }

    if (text.toLowerCase().contains("modo tutor")) {
      setState(() => _isTutorMode = true);
      _addMessage({
        "role": "glyph", 
        "text": "¡Hola! He activado el Modo Tutor bilingüe. 🌵 Responderé en Español y Wayuunaiki.\n\nSoy tu profesor de agricultura. ¿Con qué cultivo te gustaría iniciar hoy? ¿Frijol Guajirito o Moringa?"
      });
      return;
    }
    if (text.toLowerCase().contains("salir tutor") || text.toLowerCase().contains("modo normal")) {
      setState(() => _isTutorMode = false);
      _addMessage({"role": "glyph", "text": "Modo Tutor desactivado."});
      return;
    }

    _sendMultimodalData(question: text, base64Image: img);
  }

  void _startNewChat() async {
    if (_messages.isEmpty) return;
    
    _currentSessionId = await DatabaseHelper.instance.createSession();
    final defaultMsg = {
      "role": "glyph",
      "text": "¡Hola! Soy Glyph, tu asistente de salud pediátrica.\n\nPor favor, comparte los siguientes datos para calcular el estado nutricional:\n• Nombre\n• Edad (en meses)\n• Peso (en kg)\n• Talla (en cm)\n• Género (niño o niña)\n\n📏 Instrucción de medición de talla:\n- Niños menores de 24 meses → medir ACOSTADO (longitud).\n- Niños de 24 meses o más → medir DE PIE (talla).\n\n🌵 Wayuunaiki:\nTaya Glyph, tü pütchipü'üka pia süpüla kaa'uleein chi tepichikai.\nPütchajaa tü wayuukalü:\n• Jintüt (nombre)\n• Kachon (edad en meses)\n• Nutuma (peso en kg)\n• Nütüjülü (talla en cm)\n• Tepichi o Jintü (niño o niña)\n\n📏 Süpüla ekirajaa nütüjülü:\n- Tepichi maa akumajünüshi 24 kachon → kataajalaa SÜPÜSHUA (acostado).\n- Tepichi 24 kachon o sümüin → kataajalaa NUKUJULEE (de pie)."
    };
    await DatabaseHelper.instance.insertMessage(_currentSessionId!, defaultMsg);

    setState(() {
        _messages.clear();
        _messages.add(defaultMsg);
        _isMenuOpen = false;
        _menuAnimationController.reverse();
    });
    
    // Recargar historial visual
    _loadPersistedHistory();
  }

  String _getOrdinalName(int index, int total) {
    final pos = total - index;
    const names = ["Primera", "Segunda", "Tercera", "Cuarta", "Quinta", "Sexta", "Séptima", "Octava", "Novena", "Décima", "Undécima", "Duodécima"];
    if (pos >= 1 && pos <= names.length) return "${names[pos - 1]} interacción";
    return "Interacción #$pos";
  }

  void _unfocus() {
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() => _showTextField = false);
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
            if (msg["type"] == "anthro_chart" && msg["data"] != null) ...[
              Text(msg["data"]["text"], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              AnthroChartWidget(
                ageInMonths: msg["data"]["edad"],
                weightKg: msg["data"]["peso"],
                heightCm: (msg["data"]["talla"] as num).toDouble(),
                genderStr: msg["data"]["genero"],
                diagnosis: msg["data"]["diag"],
              ),
            ],
            if (msg["type"] == "file_share" && msg["data"] != null) ...[
              GestureDetector(
                onTap: () => Share.shareXFiles([XFile(msg["data"]["path"])], text: "Base de datos exportada desde Glyph"),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5))),
                  child: Row(children: [const Icon(Icons.file_download, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(msg["data"]["text"], style: const TextStyle(color: Colors.white)))])
                )
              ),
            ],
            if (msg["type"] != "file_share" && msg["text"]?.toString().isNotEmpty == true)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(msg["text"],
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontStyle: isThought ? FontStyle.italic : FontStyle.normal)),
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
                          child: const Icon(Icons.volume_up, color: Colors.cyanAccent, size: 16),
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
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) async {
                      final audio = await _stopRecording();
                      if (audio != null) {
                        _sendMultimodalData(question: "INSTRUCCIÓN ESPECIAL: El audio adjunto es mi mensaje de voz. Escucha lo que digo y RESPONDE DIRECTAMENTE a mi pregunta o comentario. NO describas el audio (no digas 'Se escucha una voz diciendo...'). Trátalo como si fuera un mensaje de texto que te acabo de escribir.", base64Audio: audio);
                      }
                    },
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 300),
                        scale: _showTextField ? 0.4 : 1.0,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_pulseController, _waveController]),
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
            if (_isMenuOpen)
              GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  color: Colors.black54,
                  child: SlideTransition(
                    position: _menuOffsetAnimation,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border(
                            right: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 0.5)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 100),
                          ListTile(
                            leading: const Icon(Icons.add_circle_outline,
                                color: Colors.white60, size: 20),
                            title: const Text("Nuevo Chat",
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2)),
                            onTap: _startNewChat,
                          ),
                          ListTile(
                            leading: const Icon(Icons.image_outlined,
                                color: Colors.white60, size: 20),
                            title: const Text("Adjuntar Imagen",
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2)),
                            onTap: _pickImage,
                          ),
                          ListTile(
                            leading: const Icon(Icons.attach_file_outlined,
                                color: Colors.white60, size: 20),
                            title: const Text("Adjuntar Archivo",
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2)),
                            onTap: _pickFile,
                          ),
                          ListTile(
                            leading: const Icon(Icons.folder_outlined,
                                color: Colors.white60, size: 20),
                            title: const Text("Archivos Generados",
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2)),
                            onTap: _showGeneratedFiles,
                          ),
                          ListTile(
                            leading: const Icon(Icons.people_alt_outlined,
                                color: Colors.white60, size: 20),
                            title: const Text("Control Nutricional",
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.2)),
                            onTap: () {
                              _toggleMenu();
                              _showNutritionalControl();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.memory_outlined,
                                color: Colors.white60, size: 20),
                            title: Text(_isOfflineMode ? "Desactivar Offline" : "Modo Offline (Gemma)",
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
                                  _addMessage({"role": "glyph", "text": "Modo offline desactivado. Usando la nube."});
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
                                        _getOrdinalName(i, _chatSessions.length),
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w300,
                                            letterSpacing: 0.5)),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
                                      onPressed: () async {
                                        await DatabaseHelper.instance.deleteSession(_sessionIds[i]);
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

  Future<void> _showNutritionalControl() async {
    final patients = await DatabaseHelper.instance.getAllPatients();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text("Control Nutricional", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: patients.isEmpty
              ? const Text("No hay datos guardados de niños.", style: TextStyle(color: Colors.white70))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: patients.length,
                  itemBuilder: (ctx, i) {
                    final p = patients[i];
                    return ListTile(
                      title: Text(p['name'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text("ID: ${p['id']} - ${p['gender']}", style: const TextStyle(color: Colors.white54)),
                      trailing: const Icon(Icons.download, color: Colors.cyanAccent),
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
            child: const Text("Cerrar", style: TextStyle(color: Colors.cyanAccent)),
          )
        ],
      ),
    );
  }

  Future<void> _generatePatientReport(Map<String, dynamic> patient) async {
    final measurements = await DatabaseHelper.instance.getPatientMeasurements(patient['id']);
    
    String html = """
    <html>
      <head>
        <meta charset="utf-8">
        <title>Reporte Nutricional - \${patient['name']}</title>
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
        <h2>Paciente: \${patient['name']}</h2>
        <p><strong>Género:</strong> \${patient['gender']} | <strong>Fecha de nacimiento:</strong> \${patient['birthDate'].split('T')[0]}</p>
        
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
            <td>\${m['date'].split('T')[0]}</td>
            <td>\${m['age_months']}</td>
            <td>\${m['weight_kg']}</td>
            <td>\${m['height_cm']}</td>
            <td>\${m['muac_cm'] ?? '-'}</td>
            <td>\${m['z_wfa'].toStringAsFixed(2)}</td>
            <td>\${m['z_hfa'].toStringAsFixed(2)}</td>
            <td>\${m['diagnosis']}</td>
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
    final fileName = "reporte_${patient['name'].toString().replaceAll(' ', '_')}.html";
    final file = File("${tempDir.path}/$fileName");
    await file.writeAsString(html);

    _addMessage({
      "role": "glyph",
      "type": "file_share",
      "data": {
        "path": file.path,
        "name": fileName,
        "text": "He generado el reporte nutricional detallado de ${patient['name']}. Toca aquí para descargarlo o compartirlo."
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
    String csv = "ID,Nombre,Genero,FechaNacimiento,Medicion_ID,FechaMedicion,EdadMeses,PesoKg,TallaCm,Z_WFA,Z_HFA,Z_BMI,Diagnostico\n";
    for (var pat in patients) {
       final measurements = await DatabaseHelper.instance.getPatientMeasurements(pat['id']);
       if (measurements.isEmpty) {
          csv += "${pat['id']},${pat['name']},${pat['gender']},${pat['birthDate']},,,,,,,,,\n";
       } else {
          for (var m in measurements) {
             csv += "${pat['id']},${pat['name']},${pat['gender']},${pat['birthDate']},${m['id']},${m['date']},${m['age_months']},${m['weight_kg']},${m['height_cm']},${m['z_wfa']},${m['z_hfa']},${m['z_bmi']},${m['diagnosis']}\n";
          }
       }
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, "base_datos_pediatrica_${DateTime.now().ms}.csv"));
    await file.writeAsString(csv);
    return file;
  }

  Future<void> _showGeneratedFiles() async {
    setState(() => _isMenuOpen = false);
    _menuAnimationController.reverse();
    
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.csv')).toList();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121215),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Archivos Generados", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 1.2)),
              const SizedBox(height: 20),
              if (files.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, color: Colors.white.withValues(alpha: 0.2), size: 48),
                        const SizedBox(height: 10),
                        Text("No hay archivos generados aún", style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w300)),
                      ],
                    ),
                  )
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (ctx, i) {
                      return ListTile(
                        leading: const Icon(Icons.table_chart, color: Colors.greenAccent),
                        title: Text(p.basename(files[i].path), style: const TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.share, color: Colors.white54),
                        onTap: () {
                          Share.shareXFiles([XFile(files[i].path)]);
                        },
                      );
                    }
                  )
                )
            ],
          )
        );
      }
    );
  }

  void _performAnthroCalculation(String nombre, int edad, double peso, double talla, String genero, {double? muacCm}) {
    final result = AnthroService.calculate(edad, peso, talla, genero, muacCm: muacCm);
    setState(() => _lastManualDiagnosis = result.diagnosis);
    
    String simplifiedDiag = "";
    if (result.diagnosis.contains("Normal")) {
      simplifiedDiag = "Está creciendo sano y fuerte. Recomendación: Continúe alimentándolo con comida local variada y mucho amor. ¡Sigan así!\n\n🌵 Wayuunaiki: Waima ni'iruku, katsinshi nia. Anashii pükülin nia sümaa eküülü anasü. ¡Müle'u chia!";
    } else if (result.diagnosis.contains("Desnutrición") || result.diagnosis.contains("Delgadez")) {
      simplifiedDiag = "Precaución. Necesita atención urgente. Recomendación: Por favor, lleve al niño al centro de salud más cercano lo antes posible para que un profesional lo evalúe.\n\n🌵 Wayuunaiki: Jülüja aa'in. Cho'ujaasü ataralü mma'ana. Püshajaa chi jintükai eemüin tü piichi ataralü eesü kasakai.";
    } else if (result.diagnosis.contains("Sobrepeso") || result.diagnosis.contains("Obesidad")) {
      simplifiedDiag = "Precaución. Tiene exceso de peso. Recomendación: Por favor, intente dar una alimentación más balanceada y consulte con un profesional.\n\n🌵 Wayuunaiki: Jülüja aa'in. Alatusü nutuma. Pükülin nia sümaa eküülü anasü siia püshajaa chi eekai atüjain.";
    }

    if (result.muacDiagnosis.isNotEmpty) {
      simplifiedDiag += "\\n" + result.muacDiagnosis;
    }
    
    final speechText = "He registrado a $nombre. $simplifiedDiag";
    
    _addMessage({
       "role": "glyph", 
       "type": "anthro_chart",
       "data": {
           "edad": edad, "peso": peso, "talla": talla, "genero": genero, 
           "diag": result.diagnosis, 
           "text": speechText
       }
    });
    
    // Primero habla en español; cuando termine, reproduce el audio en Wayuunaiki
    String? wayuuAudio;
    if (result.diagnosis.contains("Normal")) {
      wayuuAudio = 'wayuu_sano.mp3';
    } else if (result.diagnosis.contains("Desnutrición") || result.diagnosis.contains("Delgadez")) {
      wayuuAudio = 'wayuu_peligro.mp3';
    } else if (result.diagnosis.contains("Sobrepeso") || result.diagnosis.contains("Obesidad")) {
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
      final existing = patients.where((p) => p['name'].toString().toLowerCase() == nombre.toLowerCase()).toList();
      
      void saveMeasurement(int pid) {
        DatabaseHelper.instance.insertMeasurement({
          "patient_id": pid, "date": DateTime.now().toIso8601String(),
          "age_months": edad, "weight_kg": peso, "height_cm": talla, "bmi": 0.0,
          "z_wfa": result.zWeightForAge, "z_hfa": result.zHeightForAge, "z_bmi": result.zBmiForAge,
          "diagnosis": result.diagnosis,
          "muac_cm": muacCm
        });
        if (mounted) {
           _addMessage({
              "role": "glyph",
              "text": 'Z-Scores: WFA: \${result.zWeightForAge.toStringAsFixed(2)}, HFA: \${result.zHeightForAge.toStringAsFixed(2)}, BMI: \${result.zBmiForAge.toStringAsFixed(2)}\\nDiagnóstico: \${result.diagnosis}' + (result.muacDiagnosis.isNotEmpty ? '\\n\${result.muacDiagnosis}' : '')
           });
        }
      }

      if (existing.isNotEmpty) {
        saveMeasurement(existing.first['id']);
      } else {
        DatabaseHelper.instance.insertPatient({
          "name": nombre, "gender": genero, "birthDate": DateTime.now().subtract(Duration(days: edad * 30)).toIso8601String()
        }).then((pid) {
          saveMeasurement(pid);
        });
      }
    });
  }

  // Convierte palabras numéricas en español a enteros
  int? _spanishWordToNumber(String word) {
    const map = {
      "cero": 0, "uno": 1, "dos": 2, "tres": 3, "cuatro": 4,
      "cinco": 5, "seis": 6, "siete": 7, "ocho": 8, "nueve": 9,
      "diez": 10, "once": 11, "doce": 12, "trece": 13, "catorce": 14,
      "quince": 15, "dieciséis": 16, "diecisiete": 17, "dieciocho": 18,
      "diecinueve": 19, "veinte": 20, "veintiuno": 21, "veintidós": 22,
      "veintitrés": 23, "veinticuatro": 24, "veinticinco": 25,
      "veintiséis": 26, "veintisiete": 27, "veintiocho": 28,
      "veintinueve": 29, "treinta": 30, "cuarenta": 40, "cincuenta": 50,
      "sesenta": 60,
    };
    return map[word.toLowerCase().trim()];
  }

  void _tryManualExtraction(String userText) {
    final lower = userText.toLowerCase();

    // ── Edad ─────────────────────────────────────────────────────────────────
    int? edad;
    
    // 1. Buscar Años (ej. "1 año", "un año", "2 años")
    int years = 0;
    final yearDigitMatch = RegExp(r"(\d+)\s*año").firstMatch(lower);
    if (yearDigitMatch != null) {
      years = int.tryParse(yearDigitMatch.group(1)!) ?? 0;
    } else {
      final yearWordMatch = RegExp(r"(\w+)\s+año").firstMatch(lower);
      if (yearWordMatch != null) {
        years = _spanishWordToNumber(yearWordMatch.group(1)!) ?? 0;
      }
    }

    // 2. Buscar Meses (ej. "12 meses", "doce meses")
    int months = 0;
    final monthDigitMatch = RegExp(r"(\d+)\s*mes").firstMatch(lower);
    if (monthDigitMatch != null) {
      months = int.tryParse(monthDigitMatch.group(1)!) ?? 0;
    } else {
      final monthWordMatch = RegExp(r"(\w+)\s+mes").firstMatch(lower);
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
    final weightDigitMatch = RegExp(r"(\d+(\.\d+)?)\s*(kg|kilos?)").firstMatch(lower);
    if (weightDigitMatch != null) {
      peso = double.tryParse(weightDigitMatch.group(1)!);
    } else {
      // Palabra numérica + kg (ej. "tres kg")
      final weightWordMatch = RegExp(r"(\w+)\s*(kg|kilos?)").firstMatch(lower);
      if (weightWordMatch != null) {
        final n = _spanishWordToNumber(weightWordMatch.group(1)!);
        if (n != null) peso = n.toDouble();
      }
    }

    // ── Talla ─────────────────────────────────────────────────────────────────
    double? talla;
    final heightDigitMatch = RegExp(r"(\d+(\.\d+)?)\s*cm").firstMatch(lower);
    if (heightDigitMatch != null) {
      talla = double.tryParse(heightDigitMatch.group(1)!);
    } else {
      final heightWordMatch = RegExp(r"(\w+)\s*cm").firstMatch(lower);
      if (heightWordMatch != null) {
        final n = _spanishWordToNumber(heightWordMatch.group(1)!);
        if (n != null) talla = n.toDouble();
      }
    }

    // ── Nombre y género ───────────────────────────────────────────────────────
    final nameMatch = RegExp(r"\b([A-Z][a-záéíóúñ]+)\b").firstMatch(userText);
    final nombre = nameMatch?.group(1) ?? "Niño";
    final genero = lower.contains("niña") || lower.contains("femenino") ? "f" : "m";

    if (edad != null && peso != null && talla != null) {
      _performAnthroCalculation(nombre, edad, peso, talla, genero);
    }
  }
}

extension DateExt on DateTime {
  int get ms => millisecondsSinceEpoch;
}
