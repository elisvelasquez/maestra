import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://nstsibynitpgsywvygni.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5zdHNpYnluaXRwZ3N5d3Z5Z25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1ODUzMjMsImV4cCI6MjA4ODE2MTMyM30.MYtxJFT5JBwRM2mKM_-LUjkorG0kZL_34w6oTYRcN2s',
  );
  runApp(const TeacherDashboardApp());
}

/// Root MaterialApp for the Teacher Dashboard
class TeacherDashboardApp extends StatelessWidget {
  const TeacherDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maestra - Dashboard de Despachos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A5F7A),
          brightness: Brightness.light,
          primary: const Color(0xFF1A5F7A),
          secondary: const Color(0xFF159895),
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

/// Main dashboard screen showing students "En Cola" with real-time updates
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// Cache for estudiante fetches to avoid duplicate API calls on rebuilds
  final Map<String, Future<Map<String, dynamic>?>> _estudianteFetchCache = {};

  /// Returns a cached Future for fetching estudiante data
  Future<Map<String, dynamic>?> _getEstudiante(String estudianteId) {
    if (!_estudianteFetchCache.containsKey(estudianteId)) {
      _estudianteFetchCache[estudianteId] = _fetchEstudianteFromSupabase(
        estudianteId,
      );
    }
    return _estudianteFetchCache[estudianteId]!;
  }

  Future<Map<String, dynamic>?> _fetchEstudianteFromSupabase(
    String estudianteId,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('estudiantes')
          .select('nombre_completo, grado_seccion, foto_url')
          .eq('id', estudianteId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching estudiante $estudianteId: $e');
      return null;
    }
  }

  /// Updates log_despachos record to 'Llamado al Salon'
  Future<void> _enviarAlumnoALaPuerta(String logId) async {
    try {
      await Supabase.instance.client
          .from('log_despachos')
          .update({'estatus': 'Llamado al Salon'}).eq('id', logId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alumno enviado a la puerta correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating log_despachos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D3B4C),
      appBar: AppBar(
        title: const Text(
          'Cola de Despachos',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A5F7A),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('log_despachos')
                  .stream(primaryKey: ['id'])
                  .eq('estatus', 'En Cola'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar la cola',
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 24),
                        Text(
                          'Conectando a la cola...',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final records = snapshot.data ?? [];

                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 120,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No hay alumnos en cola',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'La cola se actualiza en tiempo real',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final log = records[index];
                    final logId = log['id'] as String?;
                    final estudianteId = log['estudiante_id'] as String?;

                    if (logId == null || estudianteId == null) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _WaitingStudentCard(
                        logId: logId,
                        estudianteId: estudianteId,
                        getEstudiante: _getEstudiante,
                        onEnviarPressed: _enviarAlumnoALaPuerta,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(color: Colors.white, thickness: 2),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('log_despachos')
                  .stream(primaryKey: ['id'])
                  .eq('estatus', 'Llamado al Salon')
                  .order('fecha_hora_entrega', ascending: false)
                  .limit(20),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar entregados: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final records = snapshot.data ?? [];

                if (records.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay alumnos entregados',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final log = records[index];
                    final estudianteId = log['estudiante_id'] as String?;

                    if (estudianteId == null) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _DeliveredStudentCard(
                        estudianteId: estudianteId,
                        getEstudiante: _getEstudiante,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// High-contrast card displaying a waiting student with [ENVIAR ALUMNO A LA PUERTA] button
class _WaitingStudentCard extends StatefulWidget {
  const _WaitingStudentCard({
    required this.logId,
    required this.estudianteId,
    required this.getEstudiante,
    required this.onEnviarPressed,
  });

  final String logId;
  final String estudianteId;
  final Future<Map<String, dynamic>?> Function(String) getEstudiante;
  final Future<void> Function(String) onEnviarPressed;

  @override
  State<_WaitingStudentCard> createState() => _WaitingStudentCardState();
}

class _WaitingStudentCardState extends State<_WaitingStudentCard> {
  bool _isSent = false;
  String _buttonLabel = 'ENVIAR ALUMNO A LA PUERTA';

  Future<void> _handleEnviar() async {
    await widget.onEnviarPressed(widget.logId);
    if (mounted) {
      setState(() {
        _isSent = true;
        _buttonLabel = 'Alumno enviado a la puerta correctamente';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: widget.getEstudiante(widget.estudianteId),
      builder: (context, estSnapshot) {
        final estudiante = estSnapshot.data;
        final isLoading = estSnapshot.connectionState == ConnectionState.waiting;
        final hasError = estSnapshot.hasError || estSnapshot.data == null;

        return Card(
          color: const Color(0xFF159895),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (hasError)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error al cargar datos del estudiante',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (estudiante?['foto_url'] != null &&
                          (estudiante!['foto_url'] as String).isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            estudiante['foto_url'] as String,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.white24,
                              child: const Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              estudiante?['nombre_completo']?.toString() ??
                                  'Nombre no disponible',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              estudiante?['grado_seccion']?.toString() ??
                                  'Grado no disponible',
                              style: TextStyle(
                                fontSize: 26,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isSent ? null : _handleEnviar,
                      icon: const Icon(Icons.send, size: 28),
                      label: Text(
                        _buttonLabel,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _isSent ? Colors.grey : const Color(0xFF0D3B4C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Card displaying a delivered student
class _DeliveredStudentCard extends StatelessWidget {
  const _DeliveredStudentCard({
    required this.estudianteId,
    required this.getEstudiante,
  });

  final String estudianteId;
  final Future<Map<String, dynamic>?> Function(String) getEstudiante;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getEstudiante(estudianteId),
      builder: (context, estSnapshot) {
        final estudiante = estSnapshot.data;
        final isLoading = estSnapshot.connectionState == ConnectionState.waiting;
        final hasError = estSnapshot.hasError || estSnapshot.data == null;

        return Card(
          color: const Color(0xFF4CAF50), // Green color for delivered
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (hasError)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error al cargar datos del estudiante',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (estudiante?['foto_url'] != null &&
                          (estudiante!['foto_url'] as String).isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            estudiante['foto_url'] as String,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.white24,
                              child: const Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              estudiante?['nombre_completo']?.toString() ??
                                  'Nombre no disponible',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              estudiante?['grado_seccion']?.toString() ??
                                  'Grado no disponible',
                              style: TextStyle(
                                fontSize: 26,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Entregado',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
