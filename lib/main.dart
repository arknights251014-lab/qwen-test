import 'package:flutter/material.dart';
import 'pages/create_strategy_page.dart';
import 'services/persistence_service.dart';
import 'pages/dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '무한매수법 V4.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const StartupRouter(),
    );
  }
}

/// 앱 시작 시 저장된 전략이 있으면 Dashboard로, 없으면 CreateStrategyPage로 라우팅
class StartupRouter extends StatefulWidget {
  const StartupRouter({super.key});

  @override
  State<StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<StartupRouter> {
  late Future<bool> _hasRunningCycle;

  @override
  void initState() {
    super.initState();
    _hasRunningCycle = PersistenceService().loadState().then((s) => s != null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasRunningCycle,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == true) {
          return const DashboardPage();
        }
        return const CreateStrategyPage();
      },
    );
  }
}