import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/tournament_provider.dart';
import 'theme/app_theme.dart';
import 'models/match_model.dart';
import 'widgets/live_dot.dart';
import 'widgets/admin_modal.dart';
import 'widgets/welcome_cover.dart';
import 'screens/live_screen.dart';
import 'screens/standings_screen.dart';
import 'screens/scorers_screen.dart';
import 'screens/results_screen.dart';
import 'screens/bracket_screen.dart';
import 'screens/teams_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TournamentProvider()..loadData()),
      ],
      child: MaterialApp(
        title: 'Torneo di Lozzo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.scaffoldBg,
          fontFamily: 'Outfit', // Usiamo un font pulito di sistema
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.cardBg,
          ),
        ),
        home: const TournamentShell(),
      ),
    );
  }
}

class TournamentShell extends StatefulWidget {
  const TournamentShell({super.key});

  @override
  State<TournamentShell> createState() => _TournamentShellState();
}

class _TournamentShellState extends State<TournamentShell> {
  bool _showCover = true;
  int _activeTabIndex = 0;
  final ScrollController _tabScrollController = ScrollController();

  List<Map<String, dynamic>> get _tabs => [
    {
      "id": 0, 
      "label": "⚽ Live", 
      "screen": LiveScreen(
        onShowCalendar: () {
          setState(() {
            _activeTabIndex = 3;
          });
        },
      )
    },
    {"id": 1, "label": "📊 Classifica", "screen": const StandingsScreen()},
    {"id": 2, "label": "🥇 Cannonieri", "screen": const ScorersScreen()},
    {"id": 3, "label": "📋 Risultati", "screen": const ResultsScreen()},
    {"id": 4, "label": "🏆 Tabellone", "screen": const BracketScreen()},
    {"id": 5, "label": "⚙️ Squadre", "screen": const TeamsScreen()},
  ];

  void _openAdminLoginModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AdminModal(
          onSuccess: () {
            Provider.of<TournamentProvider>(context, listen: false).setAdminMode(true);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Accesso Admin abilitato con successo!"),
                backgroundColor: AppColors.success,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(TournamentProvider provider) {
    final hasLive = provider.matches.any((m) => m.status == MatchStatus.live);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBg,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppColors.logoGradient.createShader(bounds),
                child: Text(
                  "Torneo di Lozzo".toUpperCase(),
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 18,
                    color: Colors.white, // Necessario per lo ShaderMask
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "4–5 Luglio 2026",
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          
          // Live indicator & lock button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLive) ...[
                const LiveDot(),
                const SizedBox(width: 12),
              ],
              GestureDetector(
                onTap: () {
                  if (provider.adminMode) {
                    provider.toggleAdmin();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Modalità Admin disattivata."),
                        backgroundColor: AppColors.surfaceBg,
                      ),
                    );
                  } else {
                    _openAdminLoginModal();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: provider.adminMode ? AppColors.accent : AppColors.surfaceBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: provider.adminMode ? AppColors.accent : AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      provider.adminMode ? "🔓" : "🔒",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBg,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _tabScrollController,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: _tabs.map((tab) {
              final id = tab["id"] as int;
              final label = tab["label"] as String;
              final isSel = _activeTabIndex == id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _activeTabIndex = id;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isSel ? AppColors.accent : AppColors.textTertiary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Gold bar underline
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        width: isSel ? 28 : 0,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TournamentProvider>(context);

    // Schermata di caricamento premium se i dati da disco non sono pronti
    if (!provider.loaded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppColors.logoGradient.createShader(bounds),
                child: const Text(
                  "⚽",
                  style: TextStyle(fontSize: 54, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => AppColors.logoGradient.createShader(bounds),
                child: const Text(
                  "CARICAMENTO...",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Centered constrained box mimicking high-end mobile shell
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.scaffoldBg,
                    border: Border.symmetric(
                      horizontal: BorderSide.none,
                      vertical: BorderSide(color: AppColors.borderLight, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Sticky header
                      _buildHeader(provider),
                      
                      // Horizontally scrollable navigation tabs
                      _buildTabBar(),
                      
                      // Expanded active tab display
                      Expanded(
                        child: _tabs[_activeTabIndex]["screen"] as Widget,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Goal Flash overlay pulse
            if (provider.goalFlash)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: provider.goalFlash ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 700),
                    child: Container(
                      color: AppColors.accent.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),

            // Welcome Cover Overlay (Slides left and fades out)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeInOutCubic,
              left: _showCover ? 0 : -screenWidth,
              right: _showCover ? 0 : screenWidth,
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _showCover ? 1.0 : 0.0,
                child: WelcomeCover(
                  onEnter: () {
                    setState(() {
                      _showCover = false;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
