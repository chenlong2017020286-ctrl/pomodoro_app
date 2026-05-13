import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// 国际化文本
// ============================================================
class _L {
  static const Map<String, _ZhEn> data = {
    'appTitle': _ZhEn(zh: '番茄时钟', en: 'Pomodoro'),
    'focus': _ZhEn(zh: '专注', en: 'Focus'),
    'shortBreak': _ZhEn(zh: '短休息', en: 'Short Break'),
    'longBreak': _ZhEn(zh: '长休息', en: 'Long Break'),
    'start': _ZhEn(zh: '开始', en: 'Start'),
    'pause': _ZhEn(zh: '暂停', en: 'Pause'),
    'reset': _ZhEn(zh: '重置', en: 'Reset'),
    'tomatoCount': _ZhEn(zh: '已完成番茄', en: 'Tomatoes'),
    'focusComplete': _ZhEn(zh: '专注完成！休息一下吧', en: 'Focus done! Take a break'),
    'breakComplete': _ZhEn(zh: '休息结束！继续加油', en: 'Break over! Keep going'),
    'longBreakHint': _ZhEn(zh: '完成4个番茄，享受长休息', en: '4 tomatoes done, enjoy a long break'),
  };
}

class _ZhEn {
  final String zh;
  final String en;
  const _ZhEn({required this.zh, required this.en});
}

// ============================================================
// 计时器模式
// ============================================================
enum TimerMode { focus, shortBreak, longBreak }

// ============================================================
// 圆形进度条画笔
// ============================================================
class _CircleProgressPainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 背景轨道
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // 进度弧线
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -3.14159265 / 2,
        endAngle: 3.14159265 * 1.5,
        colors: [progressColor, progressColor.withOpacity(0.6)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159265 * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}

// ============================================================
// 主应用
// ============================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Round',
        scaffoldBackgroundColor: const Color(0xFFFFF8F0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B6B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const PomodoroHomePage(),
    );
  }
}

// ============================================================
// 首页
// ============================================================
class PomodoroHomePage extends StatefulWidget {
  const PomodoroHomePage({super.key});

  @override
  State<PomodoroHomePage> createState() => _PomodoroHomePageState();
}

class _PomodoroHomePageState extends State<PomodoroHomePage>
    with TickerProviderStateMixin {
  // ---- 状态 ----
  TimerMode _mode = TimerMode.focus;
  bool _isRunning = false;
  bool _isZh = true; // 中文

  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  int _tomatoCount = 0;

  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ---- 颜色 ----
  static const Color _creamBg = Color(0xFFFFF8F0);
  static const Color _tomatoRed = Color(0xFFFF6B6B);
  static const Color _warmYellow = Color(0xFFFFD93D);
  static const Color _freshGreen = Color(0xFF6BCB77);
  static const Color _softPink = Color(0xFFFFB6C1);
  static const Color _cardBg = Color(0xFFFFFFFF);

  // ---- 模式对应时长（秒）----
  int _getModeDuration(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return 25 * 60;
      case TimerMode.shortBreak:
        return 5 * 60;
      case TimerMode.longBreak:
        return 15 * 60;
    }
  }

  Color _getModeColor() {
    switch (_mode) {
      case TimerMode.focus:
        return _tomatoRed;
      case TimerMode.shortBreak:
        return _freshGreen;
      case TimerMode.longBreak:
        return _warmYellow;
    }
  }

  String _t(String key) {
    final entry = _L.data[key];
    if (entry == null) return key;
    return _isZh ? entry.zh : entry.en;
  }

  // ---- 生命周期 ----
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ---- 计时器逻辑 ----
  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    if (!_isRunning) return;
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _switchMode(TimerMode newMode) {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _mode = newMode;
      _isRunning = false;
      _totalSeconds = _getModeDuration(newMode);
      _remainingSeconds = _totalSeconds;
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    _isRunning = false;

    // 播放系统提示音
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);

    if (_mode == TimerMode.focus) {
      setState(() => _tomatoCount++);
      // 每4个番茄自动切换到长休息
      if (_tomatoCount % 4 == 0) {
        _switchMode(TimerMode.longBreak);
        _showSnackBar(_t('longBreakHint'));
      } else {
        _switchMode(TimerMode.shortBreak);
        _showSnackBar(_t('focusComplete'));
      }
    } else {
      _switchMode(TimerMode.focus);
      _showSnackBar(_t('breakComplete'));
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: _getModeColor(),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---- 格式化时间 ----
  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ---- 模式 emoji ----
  String _modeEmoji() {
    switch (_mode) {
      case TimerMode.focus:
        return '\u{1F345}'; // tomato
      case TimerMode.shortBreak:
        return '\u{1F341}'; // green apple
      case TimerMode.longBreak:
        return '\u{1F33C}'; // sunflower
    }
  }

  // ---- 构建 ----
  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0
        ? _remainingSeconds / _totalSeconds
        : 0.0;
    final modeColor = _getModeColor();

    return Scaffold(
      backgroundColor: _creamBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // ---- 顶栏 ----
              _buildTopBar(),
              const SizedBox(height: 20),

              // ---- 模式切换 ----
              _buildModeSelector(modeColor),
              const SizedBox(height: 32),

              // ---- 圆形进度条 + 时间 ----
              _buildTimerCircle(progress, modeColor),
              const SizedBox(height: 32),

              // ---- 控制按钮 ----
              _buildControlButtons(modeColor),
              const SizedBox(height: 32),

              // ---- 番茄计数卡片 ----
              _buildTomatoCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---- 顶栏 ----
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _tomatoRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('\u{1F345}', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _t('appTitle'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ],
        ),
        // 语言切换
        GestureDetector(
          onTap: () => setState(() => _isZh = !_isZh),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _isZh ? 'EN' : '中',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _tomatoRed,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- 模式选择器 ----
  Widget _buildModeSelector(Color activeColor) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _modeButton(TimerMode.focus, _t('focus'), '\u{1F345}', activeColor),
          _modeButton(TimerMode.shortBreak, _t('shortBreak'), '\u{1F341}', activeColor),
          _modeButton(TimerMode.longBreak, _t('longBreak'), '\u{1F33C}', activeColor),
        ],
      ),
    );
  }

  Widget _modeButton(
    TimerMode mode,
    String label,
    String emoji,
    Color activeColor,
  ) {
    final isActive = _mode == mode;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _switchMode(mode),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? Colors.white : const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- 圆形计时器 ----
  Widget _buildTimerCircle(double progress, Color modeColor) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = _isRunning ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: 260,
        height: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: modeColor.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 进度条
            Positioned.fill(
              child: CustomPaint(
                painter: _CircleProgressPainter(
                  progress: progress,
                  trackColor: modeColor.withOpacity(0.12),
                  progressColor: modeColor,
                  strokeWidth: 10,
                ),
              ),
            ),
            // 中间内容
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _modeEmoji(),
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3A3A3A),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isRunning
                      ? (_isZh ? '进行中...' : 'Running...')
                      : (_isZh ? '准备就绪' : 'Ready'),
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFFAAAAAA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- 控制按钮 ----
  Widget _buildControlButtons(Color modeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 重置按钮
        _controlButton(
          icon: Icons.refresh_rounded,
          label: _t('reset'),
          bgColor: const Color(0xFFF0F0F0),
          iconColor: const Color(0xFF888888),
          onTap: _resetTimer,
        ),
        const SizedBox(width: 20),
        // 开始/暂停按钮（大按钮）
        GestureDetector(
          onTap: _isRunning ? _pauseTimer : _startTimer,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [modeColor, modeColor.withOpacity(0.75)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: modeColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // 跳过按钮（重用重置图标位置，这里放跳过）
        _controlButton(
          icon: Icons.skip_next_rounded,
          label: _isZh ? '跳过' : 'Skip',
          bgColor: const Color(0xFFF0F0F0),
          iconColor: const Color(0xFF888888),
          onTap: _onTimerComplete,
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFAAAAAA),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ---- 番茄计数卡片 ----
  Widget _buildTomatoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _t('tomatoCount'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
              Text(
                _isZh ? '今日目标: 8' : 'Goal: 8',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFBBBBBB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 番茄 emoji 展示
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '\u{1F345}',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 8),
              Text(
                'x $_tomatoCount',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _tomatoRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_tomatoCount % 4) / 4.0,
              minHeight: 8,
              backgroundColor: _tomatoRed.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(_tomatoRed),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isZh
                ? '下一个长休息还需 ${4 - (_tomatoCount % 4)} 个番茄'
                : '${4 - (_tomatoCount % 4)} more until long break',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFBBBBBB),
            ),
          ),
        ],
      ),
    );
  }
}

// AnimatedBuilder 兼容性辅助（Flutter 3.10+ 内置，低版本备用）
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
