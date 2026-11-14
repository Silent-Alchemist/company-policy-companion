import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

void main() {
  runApp(const BoardGameCompanionApp());
}

class Player {
  final String id;
  String name;
  String role;
  int score;
  int strikes;

  Player({
    required this.id,
    required this.name,
    this.role = 'Employee',
    this.score = 15,
    this.strikes = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'score': score,
    'strikes': strikes,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] ?? '',
    name: json['name'] ?? 'Player',
    role: json['role'] ?? 'Employee',
    score: json['score'] ?? 15,
    strikes: json['strikes'] ?? 0,
  );
}

class LanClientConnection {
  final Socket socket;
  final Stream<String> lines;

  LanClientConnection(this.socket)
    : lines = utf8.decoder
          .bind(socket)
          .transform(const LineSplitter())
          .asBroadcastStream();

  void send(Map<String, dynamic> data) {
    socket.write('${jsonEncode(data)}\n');
  }

  void close() {
    try {
      socket.destroy();
    } catch (_) {}
  }
}

class BoardGameCompanionApp extends StatelessWidget {
  const BoardGameCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Company Policy Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.business_center,
                size: 72,
                color: Colors.indigoAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'COMPANY POLICY\nCOMPANION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              _MenuButton(
                label: 'Single Device (Pass & Play)',
                icon: Icons.phone_android,
                color: Colors.blueAccent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PassAndPlaySetupScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _MenuButton(
                label: 'Host Local LAN Lobby',
                icon: Icons.wifi_tethering,
                color: Colors.indigoAccent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HostLobbyScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _MenuButton(
                label: 'Join Local LAN Lobby',
                icon: Icons.wifi_find,
                color: Colors.tealAccent.shade700,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JoinLobbyScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class PassAndPlaySetupScreen extends StatefulWidget {
  const PassAndPlaySetupScreen({super.key});

  @override
  State<PassAndPlaySetupScreen> createState() => _PassAndPlaySetupScreenState();
}

class _PassAndPlaySetupScreenState extends State<PassAndPlaySetupScreen> {
  int playerCount = 4;
  int startingPoints = 15;
  final List<TextEditingController> _controllers = [];

  static const List<String> _defaultRoles = [
    'The Driller',
    'The Hacker',
    'The Mechanic',
    'The Medic',
    'The Guard',
    'The Manager',
    'IT Support',
    'Intern',
  ];

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  void _syncControllers() {
    while (_controllers.length < playerCount) {
      _controllers.add(
        TextEditingController(text: 'Employee ${_controllers.length + 1}'),
      );
    }
    while (_controllers.length > playerCount) {
      _controllers.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    List<Player> players = [];
    for (int i = 0; i < playerCount; i++) {
      String name = _controllers[i].text.trim();
      if (name.isEmpty) name = 'Employee ${i + 1}';
      if (name.length > 16) name = name.substring(0, 16);
      players.add(
        Player(
          id: 'p$i',
          name: name,
          role: _defaultRoles[i % _defaultRoles.length],
          score: startingPoints,
        ),
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          initialPlayers: players,
          startingPoints: startingPoints,
          isLanHost: false,
          isLanClient: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pass & Play Setup')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Employees (2 - 8):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: playerCount > 2
                        ? () => setState(() {
                            playerCount--;
                            _syncControllers();
                          })
                        : null,
                  ),
                  Text(
                    '$playerCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: playerCount < 8
                        ? () => setState(() {
                            playerCount++;
                            _syncControllers();
                          })
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Starting Points:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: startingPoints > 5
                        ? () => setState(() => startingPoints -= 5)
                        : null,
                  ),
                  Text(
                    '$startingPoints',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: startingPoints < 50
                        ? () => setState(() => startingPoints += 5)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          ...List.generate(playerCount, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                controller: _controllers[index],
                maxLength: 16,
                decoration: InputDecoration(
                  labelText:
                      'Player ${index + 1} (${_defaultRoles[index % _defaultRoles.length]})',
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.indigoAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _startGame,
            child: const Text(
              'Start Shift',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class HostLobbyScreen extends StatefulWidget {
  const HostLobbyScreen({super.key});

  @override
  State<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends State<HostLobbyScreen> {
  final TextEditingController _hostNameCtrl = TextEditingController(
    text: 'Host',
  );
  int startingPoints = 15;
  String localIp = 'Detecting...';
  ServerSocket? _server;
  final List<Socket> _clientSockets = [];
  final List<Player> _players = [];
  bool _gameStarted = false;

  static const List<String> _roles = [
    'The Driller',
    'The Hacker',
    'The Mechanic',
    'The Medic',
    'The Guard',
    'The Manager',
    'IT Support',
    'Intern',
  ];

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
      }
    } catch (_) {}

    _players.add(
      Player(id: 'host', name: 'Host', role: _roles[0], score: startingPoints),
    );

    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, 4040);
      _server!.listen((client) {
        if (_players.length >= 8 || _gameStarted) {
          client.destroy();
          return;
        }
        _clientSockets.add(client);
        final clientId = '${client.remoteAddress.address}:${client.remotePort}';

        utf8.decoder
            .bind(client)
            .transform(const LineSplitter())
            .listen(
              (line) {
                if (line.trim().isEmpty) return;
                try {
                  final msg = jsonDecode(line);
                  if (msg['type'] == 'JOIN') {
                    setState(() {
                      _players.add(
                        Player(
                          id: clientId,
                          name: msg['name'] ?? 'Employee',
                          role: _roles[_players.length % _roles.length],
                          score: startingPoints,
                        ),
                      );
                    });
                    _broadcastLobby();
                  }
                } catch (_) {}
              },
              onDone: () {
                _clientSockets.remove(client);
                if (!_gameStarted && mounted) {
                  setState(() {
                    _players.removeWhere((p) => p.id == clientId);
                  });
                  _broadcastLobby();
                }
              },
              onError: (_) {
                _clientSockets.remove(client);
              },
            );
      });
    } catch (_) {}

    if (mounted) setState(() {});
  }

  void _broadcastLobby() {
    final payload = jsonEncode({
      'type': 'LOBBY_UPDATE',
      'players': _players.map((p) => p.toJson()).toList(),
      'startingPoints': startingPoints,
    });
    for (var sock in _clientSockets) {
      try {
        sock.write('$payload\n');
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _hostNameCtrl.dispose();
    if (!_gameStarted) {
      for (var s in _clientSockets) {
        try {
          s.destroy();
        } catch (_) {}
      }
      _server?.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host LAN Lobby')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Employees on same Wi-Fi connect to:'),
                  const SizedBox(height: 4),
                  SelectableText(
                    localIp,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.tealAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hostNameCtrl,
              maxLength: 16,
              decoration: InputDecoration(
                labelText: 'Host Name',
                counterText: '',
                fillColor: const Color(0xFF1E293B),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (val) {
                if (_players.isNotEmpty) {
                  _players[0].name = val.isEmpty ? 'Host' : val;
                  _broadcastLobby();
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Connected Employees (${_players.length}/8)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (context, i) => Card(
                  color: const Color(0xFF1E293B),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(_players[i].name),
                    subtitle: Text(_players[i].role),
                    trailing: i == 0 ? const Chip(label: Text('Host')) : null,
                  ),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigoAccent,
              ),
              onPressed: _players.length < 2
                  ? null
                  : () {
                      _gameStarted = true;
                      final payload = jsonEncode({
                        'type': 'START_GAME',
                        'players': _players.map((p) => p.toJson()).toList(),
                        'startingPoints': startingPoints,
                      });
                      for (var sock in _clientSockets) {
                        try {
                          sock.write('$payload\n');
                        } catch (_) {}
                      }
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            initialPlayers: _players,
                            startingPoints: startingPoints,
                            isLanHost: true,
                            isLanClient: false,
                            serverSocket: _server,
                            clientSockets: _clientSockets,
                          ),
                        ),
                      );
                    },
              child: const Text(
                'Start LAN Game',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JoinLobbyScreen extends StatefulWidget {
  const JoinLobbyScreen({super.key});

  @override
  State<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends State<JoinLobbyScreen> {
  final TextEditingController _ipCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController(
    text: 'Employee',
  );
  LanClientConnection? _conn;
  StreamSubscription? _sub;
  bool _connecting = false;
  bool _navigatedToGame = false;
  List<Player> _lobbyPlayers = [];
  int _startingPoints = 15;

  Future<void> _connect() async {
    setState(() => _connecting = true);
    try {
      final rawSocket = await Socket.connect(
        _ipCtrl.text.trim(),
        4040,
        timeout: const Duration(seconds: 4),
      );
      final connection = LanClientConnection(rawSocket);
      _conn = connection;

      connection.send({
        'type': 'JOIN',
        'name': _nameCtrl.text.trim().isEmpty
            ? 'Employee'
            : _nameCtrl.text.trim(),
      });

      _sub = connection.lines.listen(
        (line) {
          if (line.trim().isEmpty) return;
          try {
            final msg = jsonDecode(line);
            if (msg['type'] == 'LOBBY_UPDATE') {
              if (mounted) {
                setState(() {
                  _lobbyPlayers = (msg['players'] as List)
                      .map((p) => Player.fromJson(p))
                      .toList();
                  _startingPoints = msg['startingPoints'] ?? 15;
                });
              }
            } else if (msg['type'] == 'START_GAME') {
              final syncedPlayers = msg['players'] != null
                  ? (msg['players'] as List)
                        .map((p) => Player.fromJson(p))
                        .toList()
                  : _lobbyPlayers;
              final pts = msg['startingPoints'] ?? _startingPoints;

              _navigatedToGame = true;
              _sub?.cancel();

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreen(
                      initialPlayers: syncedPlayers,
                      startingPoints: pts,
                      isLanHost: false,
                      isLanClient: true,
                      clientConnection: connection,
                    ),
                  ),
                );
              }
            }
          } catch (_) {}
        },
        onDone: () {
          if (mounted && !_navigatedToGame) {
            Navigator.popUntil(context, (r) => r.isFirst);
          }
        },
        onError: (_) {
          if (mounted && !_navigatedToGame) {
            Navigator.popUntil(context, (r) => r.isFirst);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    if (!_navigatedToGame) {
      _conn?.close();
    }
    _ipCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join LAN Lobby')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              maxLength: 16,
              decoration: InputDecoration(
                labelText: 'Your Name',
                counterText: '',
                fillColor: const Color(0xFF1E293B),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ipCtrl,
              decoration: InputDecoration(
                labelText: 'Host IP (e.g. 192.168.1.50)',
                fillColor: const Color(0xFF1E293B),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _connecting || _conn != null ? null : _connect,
                child: Text(
                  _conn != null ? 'Connected (Waiting for host...)' : 'Connect',
                ),
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: _lobbyPlayers.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(_lobbyPlayers[i].name),
                  subtitle: Text(_lobbyPlayers[i].role),
                  leading: CircleAvatar(child: Text('${i + 1}')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final List<Player> initialPlayers;
  final int startingPoints;
  final bool isLanHost;
  final bool isLanClient;
  final ServerSocket? serverSocket;
  final List<Socket>? clientSockets;
  final LanClientConnection? clientConnection;

  const GameScreen({
    super.key,
    required this.initialPlayers,
    required this.startingPoints,
    required this.isLanHost,
    required this.isLanClient,
    this.serverSocket,
    this.clientSockets,
    this.clientConnection,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<Player> players;
  int activeIndex = 0;
  int quarter = 1;
  int shift = 1;
  int facilityIntegrity = 100;
  String activeDirective =
      'Q1 Onboarding: Meet work quotas and avoid HR violations.';
  String? ejectionAlert;
  bool facilityCollapsed = false;
  StreamSubscription? _clientSub;

  static const List<String> _markDirectives = [
    'Q1 Onboarding: Meet work quotas and avoid HR violations.',
    'Mandatory Productivity Audit: Auditor-Bot patrolling high-activity zones.',
    'Cost Reduction Policy: Recycling utility cards yields +1 Performance Point.',
    'Overachiever Equity Tax: Point leaders under heightened M.A.R.K. scrutiny.',
    'Containment Alert: Critical system integrity below optimal thresholds.',
  ];

  @override
  void initState() {
    super.initState();
    players = List<Player>.from(widget.initialPlayers);
    if (players.isEmpty) {
      players.add(
        Player(
          id: 'fallback',
          name: 'Employee 1',
          score: widget.startingPoints,
        ),
      );
    }

    if (widget.isLanClient && widget.clientConnection != null) {
      _clientSub = widget.clientConnection!.lines.listen(
        (line) {
          if (line.trim().isEmpty) return;
          try {
            final msg = jsonDecode(line);
            if (msg['type'] == 'STATE_UPDATE') {
              if (mounted) {
                setState(() {
                  players = (msg['players'] as List)
                      .map((p) => Player.fromJson(p))
                      .toList();
                  quarter = msg['quarter'] ?? quarter;
                  shift = msg['shift'] ?? shift;
                  facilityIntegrity =
                      msg['facilityIntegrity'] ?? facilityIntegrity;
                  activeDirective = msg['activeDirective'] ?? activeDirective;
                  ejectionAlert = msg['ejectionAlert'];
                  facilityCollapsed = facilityIntegrity <= 0;
                });
              }
            } else if (msg['type'] == 'HOST_QUIT') {
              if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
            }
          } catch (_) {}
        },
        onDone: () {
          if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
        },
      );
    }
  }

  void _syncLan() {
    if (widget.isLanHost && widget.clientSockets != null) {
      final payload = jsonEncode({
        'type': 'STATE_UPDATE',
        'players': players.map((p) => p.toJson()).toList(),
        'quarter': quarter,
        'shift': shift,
        'facilityIntegrity': facilityIntegrity,
        'activeDirective': activeDirective,
        'ejectionAlert': ejectionAlert,
      });
      for (var s in widget.clientSockets!) {
        try {
          s.write('$payload\n');
        } catch (_) {}
      }
    }
  }

  void _modifyScore(int delta) {
    if (widget.isLanClient || facilityCollapsed) return;
    setState(() {
      players[activeIndex].score += delta;
      ejectionAlert = null;
    });
    _syncLan();
  }

  void _modifyStrikes(int delta) {
    if (widget.isLanClient || facilityCollapsed) return;
    setState(() {
      final p = players[activeIndex];
      p.strikes = (p.strikes + delta).clamp(0, 3);
      if (p.strikes >= 3) {
        p.strikes = 0;
        p.score -= 3;
        ejectionAlert =
            'HR EJECTION: ${p.name} hit 3 strikes! Authorization Cap revoked (-3 pts).';
      } else {
        ejectionAlert = null;
      }
    });
    _syncLan();
  }

  void _modifyIntegrity(int delta) {
    if (widget.isLanClient) return;
    setState(() {
      facilityIntegrity = (facilityIntegrity + delta).clamp(0, 100);
      facilityCollapsed = facilityIntegrity <= 0;
      ejectionAlert = null;
    });
    _syncLan();
  }

  void _advanceShift() {
    if (widget.isLanClient || facilityCollapsed) return;
    setState(() {
      ejectionAlert = null;
      if (shift < 8) {
        shift++;
      } else if (quarter < 4) {
        shift = 1;
        quarter++;
      }
      activeDirective =
          _markDirectives[(quarter + shift - 2) % _markDirectives.length];
    });
    _syncLan();
  }

  void _resetGame() {
    if (widget.isLanClient) return;
    setState(() {
      for (var p in players) {
        p.score = widget.startingPoints;
        p.strikes = 0;
      }
      quarter = 1;
      shift = 1;
      facilityIntegrity = 100;
      facilityCollapsed = false;
      ejectionAlert = null;
      activeDirective = _markDirectives[0];
    });
    _syncLan();
  }

  @override
  void dispose() {
    _clientSub?.cancel();
    if (widget.isLanHost) {
      final payload = jsonEncode({'type': 'HOST_QUIT'});
      for (var s in widget.clientSockets ?? []) {
        try {
          s.write('$payload\n');
          s.destroy();
        } catch (_) {}
      }
      _serverClose();
    }
    widget.clientConnection?.close();
    super.dispose();
  }

  void _serverClose() {
    try {
      widget.serverSocket?.close();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = activeIndex.clamp(0, players.length - 1);
    final activePlayer = players[safeIndex];
    final canControl = !widget.isLanClient;

    return Scaffold(
      appBar: AppBar(
        title: Text('Q$quarter • Shift $shift/8'),
        actions: [
          if (canControl)
            IconButton(
              icon: const Icon(Icons.skip_next),
              tooltip: 'Next Shift',
              onPressed: _advanceShift,
            ),
          if (canControl)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset Match',
              onPressed: _resetGame,
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Main Menu',
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E293B),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Facility Integrity: $facilityIntegrity%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: facilityIntegrity <= 30
                            ? Colors.redAccent
                            : Colors.tealAccent,
                      ),
                    ),
                    if (canControl)
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _modifyIntegrity(-10),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '-10%',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _modifyIntegrity(10),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '+10%',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: facilityIntegrity / 100.0,
                  backgroundColor: Colors.black38,
                  color: facilityIntegrity <= 30
                      ? Colors.redAccent
                      : Colors.tealAccent,
                ),
                const SizedBox(height: 8),
                Text(
                  'M.A.R.K.: $activeDirective',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.amberAccent,
                  ),
                ),
              ],
            ),
          ),
          if (ejectionAlert != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.redAccent.shade700,
              child: Text(
                ejectionAlert!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: players.length,
              itemBuilder: (context, i) {
                final isSelected = i == safeIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 8.0,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      '${players[i].name} • ${players[i].score} pts • ${players[i].strikes}/3',
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => activeIndex = i),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: facilityCollapsed
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 84,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'FACILITY COLLAPSED',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('All employees terminated.'),
                        if (canControl) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _resetGame,
                            icon: const Icon(Icons.replay),
                            label: const Text('Restart Shift'),
                          ),
                        ],
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          activePlayer.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          activePlayer.role,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.indigoAccent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${activePlayer.score}',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'PERFORMANCE POINTS',
                          style: TextStyle(letterSpacing: 1.2, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'HR Strikes: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ...List.generate(3, (idx) {
                              final filled = idx < activePlayer.strikes;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  filled ? Icons.gavel : Icons.circle_outlined,
                                  color: filled
                                      ? Colors.redAccent
                                      : Colors.grey,
                                ),
                              );
                            }),
                          ],
                        ),
                        if (canControl) ...[
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ActionTile(
                                label: '-1 Pt',
                                color: Colors.redAccent.shade700,
                                onPressed: () => _modifyScore(-1),
                              ),
                              const SizedBox(width: 16),
                              _ActionTile(
                                label: '+1 Pt',
                                color: Colors.greenAccent.shade700,
                                onPressed: () => _modifyScore(1),
                              ),
                              const SizedBox(width: 16),
                              _ActionTile(
                                label: '+4 Sabotage',
                                color: Colors.amber.shade800,
                                onPressed: () => _modifyScore(4),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ActionTile(
                                label: '-1 Strike',
                                color: Colors.blueGrey,
                                onPressed: () => _modifyStrikes(-1),
                              ),
                              const SizedBox(width: 16),
                              _ActionTile(
                                label: '+1 HR Strike',
                                color: Colors.deepOrangeAccent,
                                onPressed: () => _modifyStrikes(1),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 28),
                          const Text(
                            'Synced with Host Terminal',
                            style: TextStyle(
                              color: Colors.tealAccent,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionTile({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
