import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const CompanyPolicyApp());
}

const Color kBgDark = Color(0xFF0B0E14);
const Color kCardDark = Color(0xFF151A23);
const Color kCardBorder = Color(0xFF262E3D);
const Color kAccentOrange = Color(0xFFE86A33);
const Color kCardPurple = Color(0xFF7E4DD2);
const Color kTealSync = Color(0xFF2EC4B6);
const Color kMarkBlue = Color(0xFF8FB8CA);

class BoardNode {
  final String id;
  final String roomName;
  final String label;
  final double x;
  final double y;
  final bool isZiplineTerminal;
  final String? ziplineTargetId;

  const BoardNode({
    required this.id,
    required this.roomName,
    required this.label,
    required this.x,
    required this.y,
    this.isZiplineTerminal = false,
    this.ziplineTargetId,
  });
}

const List<BoardNode> kBoardNodes = [
  // Medical (2 tiles)
  BoardNode(
    id: 'med_1',
    roomName: 'Medical',
    label: 'MED T1',
    x: 0.14,
    y: 0.22,
  ),
  BoardNode(
    id: 'med_2',
    roomName: 'Medical',
    label: 'MED T2',
    x: 0.14,
    y: 0.30,
    isZiplineTerminal: true,
    ziplineTargetId: 'sec_1',
  ),
  // Drill Site (1 tile + zipline pad)
  BoardNode(
    id: 'drill_1',
    roomName: 'Drill Site',
    label: 'DRILL T1',
    x: 0.62,
    y: 0.12,
    isZiplineTerminal: true,
    ziplineTargetId: 'lounge_2',
  ),
  // Corridor: Drill -> Admin (with Hallway Pump Task)
  BoardNode(
    id: 'hall_pump',
    roomName: 'North Corridor',
    label: 'PUMP TASK',
    x: 0.54,
    y: 0.31,
  ),
  // IT (2 tiles)
  BoardNode(
    id: 'it_1',
    roomName: 'IT Server',
    label: 'IT T1',
    x: 0.16,
    y: 0.50,
    isZiplineTerminal: true,
    ziplineTargetId: 'react_1',
  ),
  BoardNode(
    id: 'it_2',
    roomName: 'IT Server',
    label: 'IT T2',
    x: 0.26,
    y: 0.54,
  ),
  // Admin / HR (4 tiles)
  BoardNode(
    id: 'hr_1',
    roomName: 'Admin / HR',
    label: 'HR T1',
    x: 0.50,
    y: 0.48,
  ),
  BoardNode(
    id: 'hr_2',
    roomName: 'Admin / HR',
    label: 'HR T2',
    x: 0.58,
    y: 0.48,
  ),
  BoardNode(
    id: 'hr_3',
    roomName: 'Admin / HR',
    label: 'HR T3',
    x: 0.50,
    y: 0.56,
  ),
  BoardNode(
    id: 'hr_4',
    roomName: 'Admin / HR',
    label: 'HR T4',
    x: 0.58,
    y: 0.56,
  ),
  // Cargo Bay (2 tiles)
  BoardNode(
    id: 'cargo_1',
    roomName: 'Cargo Bay',
    label: 'CARGO T1',
    x: 0.84,
    y: 0.46,
  ),
  BoardNode(
    id: 'cargo_2',
    roomName: 'Cargo Bay',
    label: 'CARGO T2',
    x: 0.84,
    y: 0.54,
  ),
  // Security (1 tile)
  BoardNode(
    id: 'sec_1',
    roomName: 'Security',
    label: 'SEC T1',
    x: 0.28,
    y: 0.76,
    isZiplineTerminal: true,
    ziplineTargetId: 'med_2',
  ),
  // Reactor (1 tile)
  BoardNode(
    id: 'react_1',
    roomName: 'Reactor',
    label: 'REACT T1',
    x: 0.54,
    y: 0.90,
    isZiplineTerminal: true,
    ziplineTargetId: 'it_1',
  ),
  // Lounge (2 tiles)
  BoardNode(
    id: 'lounge_1',
    roomName: 'Lounge',
    label: 'LOUNGE T1',
    x: 0.80,
    y: 0.76,
  ),
  BoardNode(
    id: 'lounge_2',
    roomName: 'Lounge',
    label: 'LOUNGE T2',
    x: 0.88,
    y: 0.76,
    isZiplineTerminal: true,
    ziplineTargetId: 'drill_1',
  ),
];

class WorkTask {
  final String id;
  final String title;
  final String nodeId;
  final String locationLabel;
  final int rewardPts;
  bool completed;

  WorkTask({
    required this.id,
    required this.title,
    required this.nodeId,
    required this.locationLabel,
    this.rewardPts = 3,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'nodeId': nodeId,
    'locationLabel': locationLabel,
    'rewardPts': rewardPts,
    'completed': completed,
  };

  factory WorkTask.fromJson(Map<String, dynamic> json) => WorkTask(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    nodeId: json['nodeId'] ?? 'hr_1',
    locationLabel: json['locationLabel'] ?? '',
    rewardPts: json['rewardPts'] ?? 3,
    completed: json['completed'] ?? false,
  );
}

const List<Map<String, dynamic>> kTaskTemplates = [
  {
    'title': 'Calibrate Bore Rig',
    'nodeId': 'drill_1',
    'loc': 'Drill Site • Tile 1',
    'pts': 4,
  },
  {
    'title': 'Repair Coolant Pump',
    'nodeId': 'hall_pump',
    'loc': 'North Hallway • Pump Tile',
    'pts': 3,
  },
  {
    'title': 'Scrub Audit Logs',
    'nodeId': 'it_2',
    'loc': 'IT Server • Tile 2',
    'pts': 3,
  },
  {
    'title': 'Restock Medbay Kits',
    'nodeId': 'med_1',
    'loc': 'Medical • Tile 1',
    'pts': 3,
  },
  {
    'title': 'Verify Manifest Crates',
    'nodeId': 'cargo_1',
    'loc': 'Cargo Bay • Tile 1',
    'pts': 3,
  },
  {
    'title': 'Stabilize Core Rods',
    'nodeId': 'react_1',
    'loc': 'Reactor • Tile 1',
    'pts': 4,
  },
  {
    'title': 'Reset Camera Grid',
    'nodeId': 'sec_1',
    'loc': 'Security • Tile 1',
    'pts': 3,
  },
  {
    'title': 'File Compliance Form',
    'nodeId': 'hr_2',
    'loc': 'Admin / HR • Tile 2',
    'pts': 2,
  },
];

const Map<String, List<String>> kRolePowerCards = {
  'The Driller': [
    'Shortcut Bore: Move to an adjacent room tile for 0 AP once per shift.',
    'Heavy Overtime: Earn +2 bonus Points on Drill Site or Reactor tasks.',
    'Structural Bypass: Ignore 1 Security lockdown barrier per quarter.',
  ],
  'The Hacker': [
    'Log Scrubbing: Spend 1 AP in IT Tile 2 to erase 1 HR Strike.',
    'Phantom Routing: Sabotage a target remotely without sharing a sector.',
    'Policy Spoof: Cancel one M.A.R.K. audit penalty once per quarter.',
  ],
  'The Mechanic': [
    'Quick Patch: Restore +15% Facility Integrity instead of +5% on tasks.',
    'Jury-Rig Terminal: Delay an HR Ejection by 1 full shift.',
    'Salvage Bonus: Gain +1 Point whenever any player plays an Action Card.',
  ],
  'The Medic': [
    'Triage Clearance: Immune to Hazard tile penalties.',
    'Wellness Excuse: Cancel 1 HR Strike for yourself or an ally in Medical.',
    'Adrenaline Rush: Gain +1 extra Action Point (4 AP) once per quarter.',
  ],
  'The Guard': [
    'Detain Suspect: Force a player in your room to lose 1 AP next turn.',
    'Camera Feed: Inspect an opponent’s Purple Power Card.',
    'Escort Protocol: Gain +2 Points whenever another player is sent to HR.',
  ],
  'The Manager': [
    'Delegate Quota: Force an employee in your room to complete your task.',
    'Executive Expense: Draw 2 Orange Action Cards for 1 AP.',
    'Performance Review: Swap Points with any player within 3 pts of you.',
  ],
  'IT Support': [
    'System Reboot: Clear an active M.A.R.K. crisis from IT Tile 1.',
    'Firewall Shield: Block a Sabotage played against your current room.',
    'Ticket Priority: Warp directly to IT Tile 1 for 1 AP from anywhere.',
  ],
  'Intern': [
    'Under the Radar: Auditor-Bot ignores you during Quarter 2.',
    'Coffee Run: Grant +1 AP to an ally in Lounge to gain +3 Points.',
    'Scapegoat Escape: Transfer 1 HR Strike to another employee in your room.',
  ],
};

class Player {
  final String id;
  String name;
  String role;
  String powerCard;
  bool powerActive;
  int score;
  int strikes;
  String nodeId;
  bool completedTaskThisShift;
  bool sabotagedThisShift;
  int taskQuota;
  List<WorkTask> tasks;

  Player({
    required this.id,
    required this.name,
    this.role = 'Employee',
    this.powerCard = '',
    this.powerActive = true,
    this.score = 15,
    this.strikes = 0,
    this.nodeId = 'lounge_1',
    this.completedTaskThisShift = false,
    this.sabotagedThisShift = false,
    this.taskQuota = 2,
    List<WorkTask>? tasks,
  }) : tasks = tasks ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'powerCard': powerCard,
    'powerActive': powerActive,
    'score': score,
    'strikes': strikes,
    'nodeId': nodeId,
    'completedTaskThisShift': completedTaskThisShift,
    'sabotagedThisShift': sabotagedThisShift,
    'taskQuota': taskQuota,
    'tasks': tasks.map((t) => t.toJson()).toList(),
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] ?? '',
    name: json['name'] ?? 'Employee',
    role: json['role'] ?? 'Employee',
    powerCard: json['powerCard'] ?? '',
    powerActive: json['powerActive'] ?? true,
    score: json['score'] ?? 15,
    strikes: json['strikes'] ?? 0,
    nodeId: json['nodeId'] ?? 'lounge_1',
    completedTaskThisShift: json['completedTaskThisShift'] ?? false,
    sabotagedThisShift: json['sabotagedThisShift'] ?? false,
    taskQuota: json['taskQuota'] ?? 2,
    tasks: (json['tasks'] as List? ?? [])
        .map((t) => WorkTask.fromJson(t))
        .toList(),
  );
}

class LanPeer {
  final String id;
  final Socket socket;
  final Stream<String> lines;

  LanPeer({required this.id, required this.socket})
    : lines = utf8.decoder
          .bind(socket)
          .transform(const LineSplitter())
          .asBroadcastStream();

  void send(Map<String, dynamic> data) {
    try {
      socket.write('${jsonEncode(data)}\n');
    } catch (_) {}
  }

  void close() {
    try {
      socket.destroy();
    } catch (_) {}
  }
}

class CompanyPolicyApp extends StatelessWidget {
  const CompanyPolicyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Company Policy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBgDark,
        colorScheme: const ColorScheme.dark(
          primary: kAccentOrange,
          secondary: kTealSync,
          surface: kCardDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBgDark,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MarkAvatarBadge extends StatelessWidget {
  final double size;
  const MarkAvatarBadge({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kMarkBlue,
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: Colors.black87, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.14,
            child: Container(
              width: size * 0.68,
              height: size * 0.44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D24),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD9D2C5), width: 2.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: size * 0.14,
                    height: size * 0.14,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: size * 0.14,
                    height: size * 0.14,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.10,
            child: Container(
              width: size * 0.56,
              height: size * 0.24,
              decoration: BoxDecoration(
                color: const Color(0xFF232730),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Container(
                  width: size * 0.10,
                  height: size * 0.22,
                  color: Colors.red.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: MarkAvatarBadge(size: 92)),
              const SizedBox(height: 20),
              const Text(
                'COMPANY POLICY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'M.A.R.K. WORKPLACE TELEMETRY & TERMINAL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              _MenuCardButton(
                label: 'HOST LOCAL LOBBY',
                subtitle: 'Create a 4-letter room code on Wi-Fi',
                icon: Icons.wifi_tethering,
                accentColor: kAccentOrange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HostLobbyScreen()),
                ),
              ),
              const SizedBox(height: 14),
              _MenuCardButton(
                label: 'JOIN WITH ROOM CODE',
                subtitle: 'Sync your device to an active shift',
                icon: Icons.tag,
                accentColor: kTealSync,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JoinLobbyScreen()),
                ),
              ),
              const SizedBox(height: 14),
              _MenuCardButton(
                label: 'PASS & PLAY (SINGLE DEVICE)',
                subtitle: 'Shared tabletop mode for 2–8 employees',
                icon: Icons.devices,
                accentColor: kCardPurple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PassAndPlaySetupScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCardButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _MenuCardButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kCardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

void _dealRolesPowersAndTasks(List<Player> players, {int tasksPerPlayer = 2}) {
  final rng = Random();
  final availableRoles = kRolePowerCards.keys.toList()..shuffle(rng);
  final usedPowers = <String>{};

  for (int i = 0; i < players.length; i++) {
    final role = availableRoles[i % availableRoles.length];
    final powerOptions = List<String>.from(kRolePowerCards[role]!)
      ..shuffle(rng);
    String chosenPower = powerOptions.first;
    for (var p in powerOptions) {
      if (!usedPowers.contains(p)) {
        chosenPower = p;
        break;
      }
    }
    usedPowers.add(chosenPower);

    players[i].role = role;
    players[i].powerCard = chosenPower;
    players[i].powerActive = true;
    players[i].nodeId = 'lounge_1';
    players[i].strikes = 0;
    players[i].completedTaskThisShift = false;
    players[i].sabotagedThisShift = false;
    players[i].taskQuota = tasksPerPlayer;
    players[i].tasks = _generateTasksForPlayer(
      players[i].id,
      tasksPerPlayer,
      rng,
    );
  }
}

List<WorkTask> _generateTasksForPlayer(String playerId, int count, Random rng) {
  final pool = List<Map<String, dynamic>>.from(kTaskTemplates)..shuffle(rng);
  return List.generate(count.clamp(1, pool.length), (idx) {
    final item = pool[idx];
    return WorkTask(
      id: '${playerId}_t_${rng.nextInt(99999)}',
      title: item['title'],
      nodeId: item['nodeId'],
      locationLabel: item['loc'],
      rewardPts: item['pts'],
    );
  });
}

class PassAndPlaySetupScreen extends StatefulWidget {
  const PassAndPlaySetupScreen({super.key});

  @override
  State<PassAndPlaySetupScreen> createState() => _PassAndPlaySetupScreenState();
}

class _PassAndPlaySetupScreenState extends State<PassAndPlaySetupScreen> {
  int playerCount = 4;
  final List<TextEditingController> _controllers = [];

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

  void _proceedToDiceOrder() {
    final list = <Player>[];
    for (int i = 0; i < playerCount; i++) {
      String name = _controllers[i].text.trim();
      if (name.isEmpty) name = 'Employee ${i + 1}';
      list.add(Player(id: 'p$i', name: name, score: 15));
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TurnOrderSetupScreen(
          players: list,
          localPlayerId: '',
          isLanHost: false,
          hostPeers: const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ROSTER SETUP')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kCardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Employees (2–8)',
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
                        fontSize: 20,
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
          ),
          const SizedBox(height: 16),
          ...List.generate(playerCount, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _controllers[i],
                maxLength: 16,
                decoration: InputDecoration(
                  labelText: 'Employee ${i + 1}',
                  counterText: '',
                  filled: true,
                  fillColor: kCardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _proceedToDiceOrder,
              child: const Text(
                'NEXT: SET DICE ROLL ORDER',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
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
  late final String roomCode;
  String localIp = 'Detecting...';
  ServerSocket? _server;
  RawDatagramSocket? _udpBeacon;
  final List<LanPeer> _peers = [];
  final List<Player> _players = [];
  bool _advancingToOrder = false;

  @override
  void initState() {
    super.initState();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    roomCode = List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
    _startLobbyNetwork();
  }

  Future<void> _startLobbyNetwork() async {
    try {
      for (var iface in await NetworkInterface.list()) {
        for (var addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
      }
    } catch (_) {}

    _players.add(Player(id: 'host', name: 'Host', score: 15));

    try {
      _udpBeacon = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4041);
      _udpBeacon!.broadcastEnabled = true;
      _udpBeacon!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _udpBeacon!.receive();
          if (dg != null) {
            final msg = utf8.decode(dg.data).trim();
            if (msg == 'DISCOVER:$roomCode' && !_advancingToOrder) {
              _udpBeacon!.send(
                utf8.encode('LOBBY:$roomCode:$localIp'),
                dg.address,
                dg.port,
              );
            }
          }
        }
      });
    } catch (_) {}

    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, 4040);
      _server!.listen((client) {
        if (_players.length >= 8 || _advancingToOrder) {
          client.destroy();
          return;
        }
        final clientId = '${client.remoteAddress.address}:${client.remotePort}';
        final peer = LanPeer(id: clientId, socket: client);
        _peers.add(peer);

        peer.lines.listen(
          (line) {
            if (line.trim().isEmpty) return;
            try {
              final msg = jsonDecode(line);
              if (msg['type'] == 'JOIN') {
                if (mounted) {
                  setState(() {
                    _players.add(
                      Player(
                        id: clientId,
                        name: msg['name'] ?? 'Employee',
                        score: 15,
                      ),
                    );
                  });
                }
                peer.send({'type': 'WELCOME', 'yourId': clientId});
                _broadcastLobby();
              }
            } catch (_) {}
          },
          onDone: () {
            _peers.remove(peer);
            if (!_advancingToOrder && mounted) {
              setState(() {
                _players.removeWhere((p) => p.id == clientId);
              });
              _broadcastLobby();
            }
          },
          onError: (_) => _peers.remove(peer),
        );
      });
    } catch (_) {}

    if (mounted) setState(() {});
  }

  void _broadcastLobby() {
    final payload = {
      'type': 'LOBBY_UPDATE',
      'players': _players.map((p) => p.toJson()).toList(),
    };
    for (var p in _peers) {
      p.send(payload);
    }
  }

  @override
  void dispose() {
    _hostNameCtrl.dispose();
    _udpBeacon?.close();
    if (!_advancingToOrder) {
      for (var p in _peers) {
        p.close();
      }
      _server?.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HOST LOBBY')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kAccentOrange, width: 1.5),
              ),
              child: Column(
                children: [
                  const Text(
                    'ROOM CODE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2.0,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    roomCode,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8.0,
                      color: kAccentOrange,
                    ),
                  ),
                  Text(
                    'Backup IP: $localIp',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _hostNameCtrl,
              maxLength: 16,
              decoration: InputDecoration(
                labelText: 'Your Employee Name',
                counterText: '',
                fillColor: kCardDark,
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
            const SizedBox(height: 14),
            Text(
              'CONNECTED EMPLOYEES (${_players.length}/8)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (context, i) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: kCardDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kCardBorder),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kAccentOrange.withValues(alpha: 0.2),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: kAccentOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      _players[i].name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: i == 0
                        ? const Chip(
                            label: Text('HOST', style: TextStyle(fontSize: 11)),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _players.length < 2
                    ? null
                    : () {
                        _advancingToOrder = true;
                        _udpBeacon?.close();
                        for (var peer in _peers) {
                          peer.send({'type': 'ROLLING_ORDER'});
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TurnOrderSetupScreen(
                              players: _players,
                              localPlayerId: 'host',
                              isLanHost: true,
                              serverSocket: _server,
                              hostPeers: _peers,
                            ),
                          ),
                        );
                      },
                child: const Text(
                  'NEXT: SET DICE ROLL ORDER',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TurnOrderSetupScreen extends StatefulWidget {
  final List<Player> players;
  final String localPlayerId;
  final bool isLanHost;
  final ServerSocket? serverSocket;
  final List<LanPeer> hostPeers;

  const TurnOrderSetupScreen({
    super.key,
    required this.players,
    required this.localPlayerId,
    required this.isLanHost,
    this.serverSocket,
    required this.hostPeers,
  });

  @override
  State<TurnOrderSetupScreen> createState() => _TurnOrderSetupScreenState();
}

class _TurnOrderSetupScreenState extends State<TurnOrderSetupScreen> {
  late List<Player> orderedPlayers;
  bool _startedMatch = false;

  @override
  void initState() {
    super.initState();
    orderedPlayers = List<Player>.from(widget.players);
  }

  @override
  void dispose() {
    if (!_startedMatch && widget.isLanHost) {
      for (var p in widget.hostPeers) {
        p.send({'type': 'HOST_QUIT'});
        p.close();
      }
      try {
        widget.serverSocket?.close();
      } catch (_) {}
    }
    super.dispose();
  }

  void _confirmOrderAndStart() {
    _startedMatch = true;
    _dealRolesPowersAndTasks(orderedPlayers, tasksPerPlayer: 2);

    if (widget.isLanHost) {
      final startPayload = {
        'type': 'START_GAME',
        'players': orderedPlayers.map((p) => p.toJson()).toList(),
      };
      for (var peer in widget.hostPeers) {
        peer.send(startPayload);
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          initialPlayers: orderedPlayers,
          localPlayerId: widget.localPlayerId,
          isLanHost: widget.isLanHost,
          isLanClient: false,
          serverSocket: widget.serverSocket,
          hostPeers: widget.hostPeers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DICE ROLL TURN ORDER')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kAccentOrange),
              ),
              child: const Text(
                'Roll physical dice at the table! Drag employees into turn order from HIGHEST roll (#1) to LOWEST roll.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: orderedPlayers.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = orderedPlayers.removeAt(oldIndex);
                    orderedPlayers.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, i) {
                  final p = orderedPlayers[i];
                  return Container(
                    key: ValueKey(p.id),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: kCardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: i == 0 ? kAccentOrange : kCardBorder,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: i == 0
                            ? kAccentOrange
                            : Colors.white12,
                        child: Text(
                          '#${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: i == 0 ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        i == 0
                            ? 'Goes First (Highest Roll)'
                            : 'Turn Position ${i + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.drag_handle,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _confirmOrderAndStart,
                child: const Text(
                  'CONFIRM ORDER & DEAL ROLES',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
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
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _ipFallbackCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController(
    text: 'Employee',
  );
  LanPeer? _peer;
  StreamSubscription? _sub;
  String _myAssignedId = '';
  bool _connecting = false;
  bool _showManualIp = false;
  bool _hostSettingOrder = false;
  bool _navigatedToGame = false;
  List<Player> _lobbyPlayers = [];

  Future<String?> _discoverHostIpByCode(String code) async {
    RawDatagramSocket? udp;
    try {
      udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      udp.broadcastEnabled = true;
      final completer = Completer<String?>();

      udp.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = udp!.receive();
          if (dg != null) {
            final text = utf8.decode(dg.data).trim();
            if (text.startsWith('LOBBY:$code:')) {
              final parts = text.split(':');
              if (parts.length >= 3 && !completer.isCompleted) {
                completer.complete(parts[2]);
              }
            }
          }
        }
      });

      final packet = utf8.encode('DISCOVER:$code');
      udp.send(packet, InternetAddress('255.255.255.255'), 4041);
      for (var iface in await NetworkInterface.list()) {
        for (var addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final segs = addr.address.split('.');
            if (segs.length == 4) {
              try {
                udp.send(
                  packet,
                  InternetAddress('${segs[0]}.${segs[1]}.${segs[2]}.255'),
                  4041,
                );
              } catch (_) {}
            }
          }
        }
      }
      return await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    } finally {
      udp?.close();
    }
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);
    try {
      String? targetIp;
      final enteredCode = _codeCtrl.text.trim().toUpperCase();

      if (_showManualIp && _ipFallbackCtrl.text.trim().isNotEmpty) {
        targetIp = _ipFallbackCtrl.text.trim();
      } else {
        if (enteredCode.length != 4) throw 'Enter a 4-character Room Code';
        targetIp = await _discoverHostIpByCode(enteredCode);
        if (targetIp == null)
          throw 'Lobby "$enteredCode" not found. Try Backup IP below.';
      }

      final rawSocket = await Socket.connect(
        targetIp,
        4040,
        timeout: const Duration(seconds: 4),
      );
      final peer = LanPeer(id: 'client', socket: rawSocket);
      _peer = peer;

      peer.send({
        'type': 'JOIN',
        'name': _nameCtrl.text.trim().isEmpty
            ? 'Employee'
            : _nameCtrl.text.trim(),
      });

      _sub = peer.lines.listen(
        (line) {
          if (line.trim().isEmpty) return;
          try {
            final msg = jsonDecode(line);
            if (msg['type'] == 'WELCOME') {
              _myAssignedId = msg['yourId'] ?? '';
            } else if (msg['type'] == 'LOBBY_UPDATE') {
              if (mounted) {
                setState(() {
                  _lobbyPlayers = (msg['players'] as List)
                      .map((p) => Player.fromJson(p))
                      .toList();
                });
              }
            } else if (msg['type'] == 'ROLLING_ORDER') {
              if (mounted) setState(() => _hostSettingOrder = true);
            } else if (msg['type'] == 'START_GAME') {
              final syncedPlayers = (msg['players'] as List)
                  .map((p) => Player.fromJson(p))
                  .toList();
              _navigatedToGame = true;
              _sub?.cancel();

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreen(
                      initialPlayers: syncedPlayers,
                      localPlayerId: _myAssignedId,
                      isLanHost: false,
                      isLanClient: true,
                      clientPeer: peer,
                    ),
                  ),
                );
              }
            }
          } catch (_) {}
        },
        onDone: () {
          if (mounted && !_navigatedToGame)
            Navigator.popUntil(context, (r) => r.isFirst);
        },
        onError: (_) {
          if (mounted && !_navigatedToGame)
            Navigator.popUntil(context, (r) => r.isFirst);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    if (!_navigatedToGame) _peer?.close();
    _codeCtrl.dispose();
    _ipFallbackCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JOIN LOBBY')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              maxLength: 16,
              decoration: InputDecoration(
                labelText: 'Employee Name',
                counterText: '',
                fillColor: kCardDark,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!_showManualIp)
              TextField(
                controller: _codeCtrl,
                maxLength: 4,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
                decoration: InputDecoration(
                  labelText: '4-Letter Room Code',
                  counterText: '',
                  fillColor: kCardDark,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            else
              TextField(
                controller: _ipFallbackCtrl,
                decoration: InputDecoration(
                  labelText: 'Host Backup IP (e.g. 192.168.1.50)',
                  fillColor: kCardDark,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _showManualIp = !_showManualIp),
                child: Text(
                  _showManualIp
                      ? 'Use 4-Letter Room Code'
                      : 'Wi-Fi blocking code? Use Backup IP',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTealSync,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _connecting || _peer != null ? null : _connect,
                child: Text(
                  _connecting
                      ? 'SEARCHING FOR LOBBY...'
                      : (_hostSettingOrder
                            ? 'ROLL DICE! HOST SETTING TURN ORDER...'
                            : (_peer != null
                                  ? 'SYNCED (WAITING FOR HOST)'
                                  : 'JOIN LOBBY')),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: _lobbyPlayers.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(_lobbyPlayers[i].name),
                  leading: CircleAvatar(
                    backgroundColor: kTealSync.withValues(alpha: 0.2),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: kTealSync),
                    ),
                  ),
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
  final String localPlayerId;
  final bool isLanHost;
  final bool isLanClient;
  final ServerSocket? serverSocket;
  final List<LanPeer> hostPeers;
  final LanPeer? clientPeer;

  const GameScreen({
    super.key,
    required this.initialPlayers,
    required this.localPlayerId,
    required this.isLanHost,
    required this.isLanClient,
    this.serverSocket,
    this.hostPeers = const [],
    this.clientPeer,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<Player> players;
  int currentTurnIndex = 0;
  int actionPointsLeft = 3;
  int quarter = 1;
  int shift = 1;
  int facilityIntegrity = 100;
  String auditorNodeId = 'hr_1';
  int sabotagesThisShift = 0;

  bool isMarkIntermission = false;
  bool isQuarterTransition = false;
  String markAnnouncement =
      'Q1 Shift 1: Auditor-Bot docked in Admin/HR. Complete your assigned tasks.';
  String? globalAlertBanner;
  bool gameOver = false;
  bool showMySecretCard = false;
  int selectedTab = 0;

  Map<String, dynamic>? pendingSabotage;
  final List<String> _undoHistory = [];
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    players = List<Player>.from(widget.initialPlayers);

    if (widget.isLanHost) {
      for (var peer in widget.hostPeers) {
        _subs.add(
          peer.lines.listen(
            (line) {
              if (line.trim().isEmpty) return;
              try {
                final msg = jsonDecode(line);
                if (msg['type'] == 'CLIENT_ACTION') {
                  _processAction(
                    action: msg['action'],
                    targetId: msg['targetId'],
                    extra: msg['extra'],
                  );
                }
              } catch (_) {}
            },
            onDone: () {},
            onError: (_) {},
          ),
        );
      }
    } else if (widget.isLanClient && widget.clientPeer != null) {
      _subs.add(
        widget.clientPeer!.lines.listen(
          (line) {
            if (line.trim().isEmpty) return;
            try {
              final msg = jsonDecode(line);
              if (msg['type'] == 'STATE_UPDATE') {
                _applyStateSnapshot(msg);
              } else if (msg['type'] == 'HOST_QUIT') {
                if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
              }
            } catch (_) {}
          },
          onDone: () {
            if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
          },
          onError: (_) {},
        ),
      );
    }
  }

  Map<String, dynamic> _captureStateSnapshot() => {
    'type': 'STATE_UPDATE',
    'players': players.map((p) => p.toJson()).toList(),
    'currentTurnIndex': currentTurnIndex,
    'actionPointsLeft': actionPointsLeft,
    'quarter': quarter,
    'shift': shift,
    'facilityIntegrity': facilityIntegrity,
    'auditorNodeId': auditorNodeId,
    'sabotagesThisShift': sabotagesThisShift,
    'isMarkIntermission': isMarkIntermission,
    'isQuarterTransition': isQuarterTransition,
    'markAnnouncement': markAnnouncement,
    'globalAlertBanner': globalAlertBanner,
    'gameOver': gameOver,
    'pendingSabotage': pendingSabotage,
  };

  void _applyStateSnapshot(Map<String, dynamic> msg) {
    if (!mounted) return;
    setState(() {
      players = (msg['players'] as List)
          .map((p) => Player.fromJson(p))
          .toList();
      currentTurnIndex = msg['currentTurnIndex'] ?? 0;
      actionPointsLeft = msg['actionPointsLeft'] ?? 3;
      quarter = msg['quarter'] ?? 1;
      shift = msg['shift'] ?? 1;
      facilityIntegrity = msg['facilityIntegrity'] ?? 100;
      auditorNodeId = msg['auditorNodeId'] ?? 'hr_1';
      sabotagesThisShift = msg['sabotagesThisShift'] ?? 0;
      isMarkIntermission = msg['isMarkIntermission'] ?? false;
      isQuarterTransition = msg['isQuarterTransition'] ?? false;
      markAnnouncement = msg['markAnnouncement'] ?? '';
      globalAlertBanner = msg['globalAlertBanner'];
      gameOver = msg['gameOver'] ?? false;
      pendingSabotage = msg['pendingSabotage'];
    });
  }

  void _syncHostToClients() {
    if (!widget.isLanHost) return;
    final snap = _captureStateSnapshot();
    for (var peer in widget.hostPeers) {
      peer.send(snap);
    }
  }

  void _dispatchAction(String action, {String? targetId, String? extra}) {
    if (widget.isLanClient) {
      widget.clientPeer?.send({
        'type': 'CLIENT_ACTION',
        'action': action,
        'targetId': targetId,
        'extra': extra,
      });
    } else {
      _processAction(action: action, targetId: targetId, extra: extra);
    }
  }

  void _processAction({
    required String action,
    String? targetId,
    String? extra,
  }) {
    if (gameOver && action != 'UNDO') return;

    if (action == 'UNDO') {
      if (_undoHistory.isNotEmpty) {
        final prev =
            jsonDecode(_undoHistory.removeLast()) as Map<String, dynamic>;
        _applyStateSnapshot(prev);
        _syncHostToClients();
      }
      return;
    }

    _undoHistory.add(jsonEncode(_captureStateSnapshot()));
    if (_undoHistory.length > 25) _undoHistory.removeAt(0);

    setState(() {
      globalAlertBanner = null;
      final active = players[currentTurnIndex];

      if (action == 'MOVE' && targetId != null) {
        final isZipline = extra == 'ZIPLINE';
        if (actionPointsLeft >= 1) {
          actionPointsLeft -= 1;
          active.nodeId = targetId;
          final node = _nodeById(targetId);
          if (isZipline) {
            globalAlertBanner =
                '${active.name} used a Zipline Card to reach ${node.roomName}!';
          }
          if (targetId == auditorNodeId && quarter >= 2) {
            _issueStrike(
              active,
              'Intercepted by Auditor-Bot at ${node.roomName} (${node.label})!',
            );
          }
        }
      } else if (action == 'COMPLETE_TASK' &&
          targetId != null &&
          !active.completedTaskThisShift &&
          actionPointsLeft >= 1) {
        final taskIdx = active.tasks.indexWhere((t) => t.id == targetId);
        if (taskIdx != -1 && !active.tasks[taskIdx].completed) {
          actionPointsLeft -= 1;
          active.completedTaskThisShift = true;
          active.tasks[taskIdx].completed = true;
          active.score += active.tasks[taskIdx].rewardPts;
          facilityIntegrity = (facilityIntegrity + 5).clamp(0, 100);
          globalAlertBanner =
              '${active.name} completed "${active.tasks[taskIdx].title}" (+${active.tasks[taskIdx].rewardPts} pts)!';
        }
      } else if (action == 'DRAW_ACTION' && actionPointsLeft >= 1) {
        actionPointsLeft -= 1;
        globalAlertBanner = '${active.name} drew an Orange Action Card.';
      } else if (action == 'INIT_SABOTAGE' &&
          targetId != null &&
          !active.sabotagedThisShift &&
          actionPointsLeft >= 1) {
        final victim = players.firstWhere((p) => p.id == targetId);
        pendingSabotage = {
          'attackerId': active.id,
          'attackerName': active.name,
          'victimId': victim.id,
          'victimName': victim.name,
        };
      } else if (action == 'RESOLVE_SABOTAGE' && pendingSabotage != null) {
        final attacker = players.firstWhere(
          (p) => p.id == pendingSabotage!['attackerId'],
        );
        final victim = players.firstWhere(
          (p) => p.id == pendingSabotage!['victimId'],
        );
        actionPointsLeft = (actionPointsLeft - 1).clamp(0, 3);
        attacker.sabotagedThisShift = true;

        if (extra == 'ALLOW') {
          attacker.score += 4;
          victim.score = (victim.score - 2).clamp(0, 999);
          facilityIntegrity = (facilityIntegrity - 10).clamp(0, 100);
          sabotagesThisShift++;
          globalAlertBanner =
              'SABOTAGE SUCCESS: ${attacker.name} sabotaged ${victim.name} (+4 pts / -10% Integrity)!';
        } else if (extra == 'PROTECT') {
          globalAlertBanner =
              'SABOTAGE BLOCKED: ${victim.name} played a Protect Card! Attack negated.';
        } else if (extra == 'REVERSE') {
          victim.score += 3;
          _issueStrike(attacker, 'Sabotage reversed by ${victim.name}!');
        }
        pendingSabotage = null;
      } else if (action == 'STRIKE') {
        _issueStrike(active, 'Manual HR violation logged.');
      } else if (action == 'END_TURN') {
        if (currentTurnIndex < players.length - 1) {
          currentTurnIndex++;
          actionPointsLeft = 3;
        } else {
          isMarkIntermission = true;
          isQuarterTransition = (shift == 8);
          _runMarkAiEvaluation();
        }
      } else if (action == 'ACK_MARK') {
        isMarkIntermission = false;
        isQuarterTransition = false;
        sabotagesThisShift = 0;
        currentTurnIndex = 0;
        actionPointsLeft = 3;
        for (var p in players) {
          p.completedTaskThisShift = false;
          p.sabotagedThisShift = false;
        }

        if (shift < 8) {
          shift++;
        } else if (quarter < 4) {
          shift = 1;
          quarter++;
        } else {
          gameOver = true;
        }
      }

      if (facilityIntegrity <= 0) {
        facilityIntegrity = 0;
        gameOver = true;
      }
    });

    _syncHostToClients();
  }

  void _issueStrike(Player p, String reason) {
    p.strikes += 1;
    if (p.strikes >= 3) {
      p.strikes = 0;
      p.score = (p.score - 3).clamp(0, 999);
      p.nodeId = 'hr_1';
      p.powerActive = false;
      globalAlertBanner =
          'HR EJECTION: ${p.name} hit 3/3 Strikes! Docked in HR Terminal (-3 pts & Power Card suspended).';
    } else {
      globalAlertBanner = 'HR STRIKE (${p.strikes}/3) to ${p.name}: $reason';
    }
  }

  void _runMarkAiEvaluation() {
    final rng = Random();
    final leader = players.reduce((a, b) => a.score >= b.score ? a : b);

    if (isQuarterTransition && quarter < 4) {
      final avgScore =
          players.map((p) => p.score).reduce((a, b) => a + b) / players.length;
      final newQuota = (facilityIntegrity < 60 || avgScore < 18) ? 3 : 2;
      for (var p in players) {
        p.taskQuota = newQuota;
        p.tasks = _generateTasksForPlayer(p.id, newQuota, rng);
      }
      auditorNodeId = leader.nodeId;
      markAnnouncement =
          'Q$quarter REVIEW COMPLETE: Based on company performance, Q${quarter + 1} task quotas adjusted to $newQuota tasks per employee. New Directive: All sabotages in Q${quarter + 1} carry double Auditor scrutiny!';
      return;
    }

    if (quarter == 1) {
      auditorNodeId = 'hr_1';
      markAnnouncement = sabotagesThisShift > 0
          ? 'M.A.R.K. LOG: Sabotage activity flagged in Shift $shift. Auditor-Bot remains docked in HR until Q2.'
          : 'M.A.R.K. LOG: Shift $shift nominal. No new rules issued. Proceeding to Shift ${shift + 1}.';
      return;
    }

    if (sabotagesThisShift >= 1 || facilityIntegrity < 65) {
      auditorNodeId = leader.nodeId;
      final targetNode = _nodeById(auditorNodeId);
      markAnnouncement =
          'DIRECTIVE ALERT: Auditor-Bot deployed to ${targetNode.roomName} (${targetNode.label}) to audit ${leader.name}. Ending a turn on that tile triggers an automatic HR Strike.';
    } else {
      final patrolPool = [
        'drill_1',
        'it_1',
        'sec_1',
        'react_1',
        'cargo_1',
        'hall_pump',
      ];
      auditorNodeId = patrolPool[rng.nextInt(patrolPool.length)];
      final targetNode = _nodeById(auditorNodeId);
      markAnnouncement =
          'M.A.R.K. PATROL: Auditor-Bot relocated to ${targetNode.roomName} (${targetNode.label}). Quota efficiency nominal.';
    }
  }

  BoardNode _nodeById(String id) {
    return kBoardNodes.firstWhere(
      (n) => n.id == id,
      orElse: () => kBoardNodes.first,
    );
  }

  @override
  void dispose() {
    for (var s in _subs) {
      s.cancel();
    }
    if (widget.isLanHost) {
      for (var peer in widget.hostPeers) {
        peer.send({'type': 'HOST_QUIT'});
        peer.close();
      }
      try {
        widget.serverSocket?.close();
      } catch (_) {}
    }
    widget.clientPeer?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePlayer = players[currentTurnIndex];
    final isPassAndPlay = !widget.isLanHost && !widget.isLanClient;
    final me = isPassAndPlay
        ? activePlayer
        : players.firstWhere(
            (p) => p.id == widget.localPlayerId,
            orElse: () => players.first,
          );
    final isMyTurn = isPassAndPlay || activePlayer.id == widget.localPlayerId;

    if (gameOver) return _buildFinaleLeaderboard();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Q$quarter • SHIFT $shift/8',
          style: const TextStyle(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          if (_undoHistory.isNotEmpty && !widget.isLanClient)
            IconButton(
              icon: const Icon(Icons.undo, color: kAccentOrange),
              tooltip: 'Undo Last Action',
              onPressed: () => _dispatchAction('UNDO'),
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildTopTelemetryBar(),
              if (globalAlertBanner != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  color: Colors.redAccent.shade700,
                  child: Text(
                    globalAlertBanner!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              Expanded(
                child: selectedTab == 0
                    ? _buildTurnDashboardTab(activePlayer, me, isMyTurn)
                    : _buildBoardMapTab(activePlayer, isMyTurn),
              ),
            ],
          ),
          if (pendingSabotage != null)
            _buildSabotageReactionOverlay(isPassAndPlay),
          if (isMarkIntermission)
            _buildMarkIntermissionOverlay(isMyTurn || widget.isLanHost),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: kCardDark,
        selectedItemColor: kAccentOrange,
        unselectedItemColor: Colors.grey,
        currentIndex: selectedTab,
        onTap: (idx) => setState(() => selectedTab = idx),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize),
            label: 'Shift & Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Board Map & Ziplines',
          ),
        ],
      ),
    );
  }

  Widget _buildTopTelemetryBar() {
    final lowInt = facilityIntegrity <= 30;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: kCardDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FACILITY INTEGRITY',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
              Text(
                '$facilityIntegrity%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: lowInt ? Colors.redAccent : kTealSync,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: facilityIntegrity / 100.0,
              backgroundColor: Colors.black45,
              color: lowInt ? Colors.redAccent : kTealSync,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnDashboardTab(Player activePlayer, Player me, bool isMyTurn) {
    final currentNode = _nodeById(activePlayer.nodeId);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isMyTurn ? kAccentOrange.withValues(alpha: 0.14) : kCardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMyTurn ? kAccentOrange : kCardBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMyTurn
                          ? 'YOUR TURN • ${activePlayer.name.toUpperCase()}'
                          : 'ACTIVE: ${activePlayer.name.toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMyTurn ? kAccentOrange : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tile: ${currentNode.roomName} (${currentNode.label})',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(3, (i) {
                  final ok = i < actionPointsLeft;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: ok ? kAccentOrange : Colors.white10,
                      child: Text(
                        'AP',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: ok ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildMyAssignedTasksCard(me),
        const SizedBox(height: 12),
        _buildMySecretPowerCard(me),
        const SizedBox(height: 14),
        if (isMyTurn && !isMarkIntermission)
          _buildPlayerActionButtons(activePlayer),
        const SizedBox(height: 16),
        const Text(
          'SHIFT ORDER & STANDINGS',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(players.length, (i) {
          final p = players[i];
          final node = _nodeById(p.nodeId);
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kCardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: i == currentTurnIndex ? kAccentOrange : kCardBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${i + 1} ${p.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${p.role} • ${node.roomName} (${node.label})',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${p.score} PTS',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTealSync,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${p.strikes}/3 HR',
                      style: TextStyle(
                        fontSize: 12,
                        color: p.strikes >= 2 ? Colors.redAccent : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMyAssignedTasksCard(Player me) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kTealSync.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR ASSIGNED WORK TASKS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: kTealSync,
                ),
              ),
              Text(
                'Quota: ${me.tasks.where((t) => t.completed).length}/${me.taskQuota}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...me.tasks.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    t.completed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: t.completed ? kTealSync : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${t.title} — ${t.locationLabel} (+${t.rewardPts} pts)',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: t.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: t.completed ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMySecretPowerCard(Player me) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCardPurple.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ROLE: ${me.role.toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => showMySecretCard = !showMySecretCard),
                child: Text(
                  showMySecretCard ? 'HIDE PURPLE CARD' : 'REVEAL PURPLE CARD',
                  style: const TextStyle(color: kCardPurple, fontSize: 11),
                ),
              ),
            ],
          ),
          if (showMySecretCard)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kCardPurple.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kCardPurple),
              ),
              child: Text(
                me.powerActive ? me.powerCard : 'SUSPENDED BY HR (3 Strikes)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerActionButtons(Player activePlayer) {
    final hasAp = actionPointsLeft > 0;
    final canTask =
        hasAp &&
        !activePlayer.completedTaskThisShift &&
        activePlayer.tasks.any((t) => !t.completed);
    final canSabotage = hasAp && !activePlayer.sabotagedThisShift;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionGridBtn(
                label: 'Move Pawn\n(Open Tile Map • 1 AP)',
                color: Colors.blueAccent,
                enabled: hasAp,
                onTap: () => setState(() => selectedTab = 1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionGridBtn(
                label: activePlayer.completedTaskThisShift
                    ? 'Task Done\n(Max 1/Shift)'
                    : 'Complete Task\n(Select Task • 1 AP)',
                color: kTealSync,
                enabled: canTask,
                onTap: () => _showCompleteTaskModal(activePlayer),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionGridBtn(
                label: 'Draw Orange Card\n(Action Deck • 1 AP)',
                color: kAccentOrange,
                enabled: hasAp,
                onTap: () => _dispatchAction('DRAW_ACTION'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionGridBtn(
                label: activePlayer.sabotagedThisShift
                    ? 'Sabotaged\n(Max 1/Shift)'
                    : 'Sabotage Rival\n(Pick Target • 1 AP)',
                color: Colors.amber.shade700,
                enabled: canSabotage,
                onTap: () => _showSabotageTargetModal(activePlayer),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _dispatchAction('STRIKE'),
                  child: const Text(
                    '+1 Strike',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(
                    currentTurnIndex < players.length - 1
                        ? 'END TURN → ${players[currentTurnIndex + 1].name.toUpperCase()}'
                        : 'END SHIFT → M.A.R.K.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () => _dispatchAction('END_TURN'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCompleteTaskModal(Player activePlayer) {
    final openTasks = activePlayer.tasks.where((t) => !t.completed).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardDark,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SELECT COMPLETED WORK TASK',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Confirm you are standing on the required room tile:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            ...openTasks.map(
              (t) => ListTile(
                tileColor: kBgDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: const Icon(Icons.task_alt, color: kTealSync),
                title: Text(
                  t.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${t.locationLabel} • +${t.rewardPts} Pts'),
                onTap: () {
                  Navigator.pop(ctx);
                  _dispatchAction('COMPLETE_TASK', targetId: t.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSabotageTargetModal(Player activePlayer) {
    final targets = players.where((p) => p.id != activePlayer.id).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardDark,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SELECT EMPLOYEE TO SABOTAGE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Target will have a chance to play Protect or Reverse cards:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            ...targets.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  tileColor: kBgDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: const Icon(Icons.warning_amber, color: Colors.amber),
                  title: Text(
                    t.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${t.role} • ${t.score} Pts'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _dispatchAction('INIT_SABOTAGE', targetId: t.id);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardMapTab(Player activePlayer, bool isMyTurn) {
    final activeNode = _nodeById(activePlayer.nodeId);
    final canZipline =
        isMyTurn &&
        actionPointsLeft >= 1 &&
        activeNode.isZiplineTerminal &&
        activeNode.ziplineTargetId != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FACILITY TILES & ZIPLINES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.grey,
                ),
              ),
              if (canZipline)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCardPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.bolt, size: 14),
                  label: Text(
                    'Use Zipline → ${_nodeById(activeNode.ziplineTargetId!).roomName}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onPressed: () {
                    _dispatchAction(
                      'MOVE',
                      targetId: activeNode.ziplineTargetId,
                      extra: 'ZIPLINE',
                    );
                    setState(() => selectedTab = 0);
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF101620),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kCardBorder, width: 1.5),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;

                return Stack(
                  children: [
                    CustomPaint(
                      size: Size(w, h),
                      painter: _BoardConnectionsPainter(),
                    ),
                    ...kBoardNodes.map((node) {
                      final occupants = players
                          .where((p) => p.nodeId == node.id)
                          .toList();
                      final hasAuditor = auditorNodeId == node.id;
                      final isMyTaskTile = activePlayer.tasks.any(
                        (t) => !t.completed && t.nodeId == node.id,
                      );

                      return Positioned(
                        left: (node.x * w) - 34,
                        top: (node.y * h) - 22,
                        child: GestureDetector(
                          onTap: (isMyTurn && actionPointsLeft >= 1)
                              ? () {
                                  _dispatchAction('MOVE', targetId: node.id);
                                  setState(() => selectedTab = 0);
                                }
                              : null,
                          child: Container(
                            width: 68,
                            height: 44,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: hasAuditor
                                  ? Colors.redAccent.withValues(alpha: 0.25)
                                  : (isMyTaskTile
                                        ? kTealSync.withValues(alpha: 0.22)
                                        : kCardDark),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hasAuditor
                                    ? Colors.redAccent
                                    : (node.isZiplineTerminal
                                          ? kCardPurple
                                          : (isMyTaskTile
                                                ? kTealSync
                                                : kCardBorder)),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  node.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 2,
                                  children: [
                                    if (hasAuditor)
                                      const Icon(
                                        Icons.smart_toy,
                                        size: 12,
                                        color: Colors.redAccent,
                                      ),
                                    ...occupants.map(
                                      (occ) => CircleAvatar(
                                        radius: 6.5,
                                        backgroundColor: kAccentOrange,
                                        child: Text(
                                          occ.name
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Purple Border = Zipline Pad  •  Teal = Your Task Tile  •  Tap any tile to move (1 AP)',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildSabotageReactionOverlay(bool isPassAndPlay) {
    final attackerName = pendingSabotage!['attackerName'];
    final victimName = pendingSabotage!['victimName'];
    final victimId = pendingSabotage!['victimId'];
    final canRespond =
        isPassAndPlay || widget.localPlayerId == victimId || widget.isLanHost;

    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, size: 48, color: Colors.amber),
              const SizedBox(height: 10),
              const Text(
                'SABOTAGE ATTEMPT!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$attackerName is sabotaging $victimName!\nDoes $victimName have a Protect or Reverse Action Card?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              if (canRespond) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        _dispatchAction('RESOLVE_SABOTAGE', extra: 'ALLOW'),
                    child: const Text(
                      'NO COUNTER (ALLOW SABOTAGE)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTealSync,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () =>
                        _dispatchAction('RESOLVE_SABOTAGE', extra: 'PROTECT'),
                    child: const Text(
                      'PLAY PROTECT CARD (BLOCK)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCardPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        _dispatchAction('RESOLVE_SABOTAGE', extra: 'REVERSE'),
                    child: const Text(
                      'PLAY UNO REVERSE (+1 STRIKE TO ATTACKER)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ] else
                Text(
                  'Waiting for $victimName to respond...',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkIntermissionOverlay(bool canAck) {
    return Container(
      color: Colors.black.withValues(alpha: 0.90),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kMarkBlue, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MarkAvatarBadge(size: 72),
              const SizedBox(height: 12),
              Text(
                isQuarterTransition
                    ? 'END OF QUARTER $quarter'
                    : 'END OF Q$quarter • SHIFT $shift',
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.0,
                  color: kMarkBlue,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'M.A.R.K. DIRECTIVE',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Text(
                markAnnouncement,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              if (canAck)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentOrange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _dispatchAction('ACK_MARK'),
                    child: Text(
                      isQuarterTransition && quarter < 4
                          ? 'START QUARTER ${quarter + 1}'
                          : 'BEGIN NEXT SHIFT',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                const Text(
                  'Waiting for Host to acknowledge M.A.R.K....',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinaleLeaderboard() {
    final sorted = List<Player>.from(players)
      ..sort((a, b) => b.score.compareTo(a.score));
    final collapsed = facilityIntegrity <= 0;

    return Scaffold(
      appBar: AppBar(title: const Text('QUARTERLY REVIEW')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              collapsed ? Icons.warning_amber_rounded : Icons.emoji_events,
              size: 72,
              color: collapsed ? Colors.redAccent : Colors.amber,
            ),
            const SizedBox(height: 12),
            Text(
              collapsed
                  ? 'FACILITY COLLAPSED'
                  : '${sorted.first.name.toUpperCase()} WINS!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: collapsed ? Colors.redAccent : Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, i) {
                  final p = sorted[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kCardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: i == 0 && !collapsed
                            ? Colors.amber
                            : kCardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${i + 1} ${p.name} (${p.role})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${p.score} PTS',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: kTealSync,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentOrange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text(
                  'RETURN TO MENU',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardConnectionsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final corridorPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final ziplinePaint = Paint()
      ..color = kCardPurple.withValues(alpha: 0.75)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Offset pos(String id) {
      final n = kBoardNodes.firstWhere((e) => e.id == id);
      return Offset(n.x * size.width, n.y * size.height);
    }

    // Standard hallway corridors
    const corridors = [
      ['med_1', 'med_2'],
      ['med_1', 'drill_1'],
      ['med_2', 'it_1'],
      ['drill_1', 'hall_pump'],
      ['hall_pump', 'hr_1'],
      ['it_1', 'it_2'],
      ['it_2', 'hr_3'],
      ['hr_1', 'hr_2'],
      ['hr_3', 'hr_4'],
      ['hr_2', 'cargo_1'],
      ['cargo_1', 'cargo_2'],
      ['cargo_2', 'lounge_2'],
      ['hr_3', 'sec_1'],
      ['hr_4', 'lounge_1'],
      ['hr_3', 'react_1'],
      ['lounge_1', 'lounge_2'],
    ];

    for (var pair in corridors) {
      canvas.drawLine(pos(pair[0]), pos(pair[1]), corridorPaint);
    }

    // Outer Zipline arcs (Drill <-> Lounge, IT <-> Reactor, Med <-> Security)
    final zip1 = Path()
      ..moveTo(pos('drill_1').dx, pos('drill_1').dy)
      ..quadraticBezierTo(
        size.width * 0.98,
        size.height * 0.25,
        pos('lounge_2').dx,
        pos('lounge_2').dy,
      );
    canvas.drawPath(zip1, ziplinePaint);

    final zip2 = Path()
      ..moveTo(pos('it_1').dx, pos('it_1').dy)
      ..quadraticBezierTo(
        size.width * 0.04,
        size.height * 0.94,
        pos('react_1').dx,
        pos('react_1').dy,
      );
    canvas.drawPath(zip2, ziplinePaint);

    canvas.drawLine(pos('med_2'), pos('sec_1'), ziplinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActionGridBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionGridBtn({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? color.withValues(alpha: 0.2)
              : Colors.white10,
          foregroundColor: enabled ? color : Colors.grey,
          side: BorderSide(color: enabled ? color : Colors.white12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        onPressed: enabled ? onTap : null,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
