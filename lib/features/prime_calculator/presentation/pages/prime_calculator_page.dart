import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/prime_bloc.dart';
import '../bloc/prime_event.dart';
import '../bloc/prime_state.dart';
import '../widgets/dual_trace_monitor.dart';
import '../widgets/instrument_panel.dart';
import '../widgets/labeled_stat.dart';
import '../widgets/segmented_progress_bar.dart';
import '../widgets/status_pill.dart';

class PrimeCalculatorPage extends StatefulWidget {
  const PrimeCalculatorPage({super.key});

  @override
  State<PrimeCalculatorPage> createState() => _PrimeCalculatorPageState();
}

class _PrimeCalculatorPageState extends State<PrimeCalculatorPage> {
  final TextEditingController _controller = TextEditingController(text: '2000000');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                const _Header(),
                const SizedBox(height: 20),
                BlocBuilder<PrimeBloc, PrimeState>(
                  builder: (context, state) => InstrumentPanel(
                    title: 'Thread activity',
                    child: DualTraceMonitor(
                      isBusy: state is PrimeCalculating,
                      uiColor: AppPalette.traceUi,
                      workerColor: AppPalette.traceWorker,
                      gridColor: AppPalette.gridLine,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InstrumentPanel(
                  title: 'Search parameters',
                  child: _ControlsSection(controller: _controller),
                ),
                const SizedBox(height: 16),
                BlocBuilder<PrimeBloc, PrimeState>(
                  builder: (context, state) => InstrumentPanel(
                    title: 'Readout',
                    child: _ReadoutSection(state: state),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// App title + a live uptime clock. The clock is a second, simpler
/// proof that the UI thread keeps ticking on its own schedule —
/// independent of whatever the worker isolate is doing below.
class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  late final Timer _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _uptime {
    final int minutes = _seconds ~/ 60;
    final int secs = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: AppPalette.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PRIME LAB',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Isolate-backed prime search · BLoC · Clean Architecture',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppPalette.textMuted),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'UPTIME',
              style: TextStyle(fontSize: 11, color: AppPalette.textMuted, letterSpacing: 1.4),
            ),
            Text(
              _uptime,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppPalette.traceUi,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlsSection extends StatelessWidget {
  final TextEditingController controller;

  const _ControlsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 16, color: AppPalette.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Upper bound',
            prefixText: 'N = ',
          ),
        ),
        const SizedBox(height: 14),
        BlocBuilder<PrimeBloc, PrimeState>(
          builder: (context, state) {
            final bool isCalculating = state is PrimeCalculating;
            return Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isCalculating ? null : () => _onRunPressed(context),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('RUN ON ISOLATE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isCalculating
                        ? () => context.read<PrimeBloc>().add(const CancelCalculationRequested())
                        : null,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('STOP'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _onRunPressed(BuildContext context) {
    final int? limit = int.tryParse(controller.text.trim());
    if (limit == null || limit < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid integer greater than 1.')),
      );
      return;
    }
    context.read<PrimeBloc>().add(CalculatePrimesRequested(limit));
  }
}

class _ReadoutSection extends StatelessWidget {
  final PrimeState state;

  const _ReadoutSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      PrimeInitial() => const _StandbyView(),
      PrimeCalculating s => _CalculatingView(state: s),
      PrimeSuccess s => _SuccessView(state: s),
      PrimeFailure s => _FailureView(message: s.message),
      PrimeCancelled() => const _CancelledView(),
    };
  }
}

class _StandbyView extends StatelessWidget {
  const _StandbyView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusPill(label: 'Standby', color: AppPalette.textMuted),
        SizedBox(height: 12),
        Text(
          'Enter an upper bound and start the search. The isolate reports back in real time.',
          style: TextStyle(color: AppPalette.textMuted),
        ),
      ],
    );
  }
}

class _CalculatingView extends StatelessWidget {
  final PrimeCalculating state;

  const _CalculatingView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusPill(label: 'Active', color: AppPalette.traceWorker),
        const SizedBox(height: 14),
        SegmentedProgressBar(
          value: state.percentage,
          color: AppPalette.traceWorker,
          trackColor: AppPalette.bgPanelRaised,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            LabeledStat(
              value: '${(state.percentage * 100).toStringAsFixed(1)}%',
              label: 'Progress',
              color: AppPalette.traceWorker,
            ),
            const SizedBox(width: 28),
            LabeledStat(
              value: '${state.current}',
              label: 'Checked up to',
              color: AppPalette.traceUi,
            ),
          ],
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final PrimeSuccess state;

  const _SuccessView({required this.state});

  @override
  Widget build(BuildContext context) {
    final List<int> preview = state.primes.length > 500 ? state.primes.sublist(0, 500) : state.primes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusPill(label: 'Done', color: AppPalette.success),
        const SizedBox(height: 14),
        Row(
          children: [
            LabeledStat(value: '${state.primes.length}', label: 'Primes found', color: AppPalette.success),
            const SizedBox(width: 28),
            LabeledStat(value: '${state.elapsedMs} ms', label: 'Elapsed', color: AppPalette.traceUi),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 30,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: preview.length,
            itemBuilder: (context, index) => Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppPalette.bgPanelRaised,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${preview[index]}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppPalette.textPrimary),
              ),
            ),
          ),
        ),
        if (state.primes.length > 500)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Showing first 500 of ${state.primes.length} results.',
              style: const TextStyle(color: AppPalette.textMuted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  final String message;

  const _FailureView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusPill(label: 'Error', color: AppPalette.danger),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: AppPalette.danger)),
      ],
    );
  }
}

class _CancelledView extends StatelessWidget {
  const _CancelledView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusPill(label: 'Stopped', color: AppPalette.textMuted),
        SizedBox(height: 12),
        Text('Calculation cancelled. Enter a new bound to run again.', style: TextStyle(color: AppPalette.textMuted)),
      ],
    );
  }
}
