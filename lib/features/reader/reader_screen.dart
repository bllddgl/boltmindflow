import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import 'reader_providers.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with SingleTickerProviderStateMixin {
  late final ReaderController _controller;
  DisplayState _display = const DisplayState();
  bool _showControls = true;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _controller = ReaderController(ref, widget.documentId, this);
    _controller.addListener(_onStateChanged);
    _controller.load();
  }

  void _onStateChanged() {
    if (mounted) setState(() => _display = _controller.state);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            children: [
              _buildReadingArea(context, l),
              if (_showControls && !_display.isFinished)
                _buildControls(context, l),
              if (_showSettings)
                _buildSettingsPanel(context, l),
              if (_display.isFinished)
                _buildFinishedOverlay(context, l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingArea(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);

    if (_display.totalWords == 0 && !_display.isPlaying) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading...', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _display.progress,
            minHeight: 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    _display.text,
                    key: ValueKey('${_display.blockIndex}-${_display.text}'),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          if (_showControls && !_display.isFinished)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Block ${_display.blockIndex + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface.withValues(alpha: 0),
              theme.colorScheme.surface.withValues(alpha: 0.95),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(_display.progress * 100).round()}% · ${_display.wordsRead}/${_display.totalWords} words',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => _controller.rewind(5),
                  icon: const Icon(Icons.fast_rewind),
                  iconSize: 32,
                  tooltip: l.readerRewind,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _controller.togglePlayPause,
                    icon: Icon(
                      _display.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    iconSize: 40,
                    color: theme.colorScheme.onPrimary,
                    tooltip: _display.isPlaying ? l.readerPause : l.readerPlay,
                  ),
                ),
                IconButton(
                  onPressed: () => _controller.skip(5),
                  icon: const Icon(Icons.fast_forward),
                  iconSize: 32,
                  tooltip: l.readerForward,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _controller.bookmark(),
                  icon: const Icon(Icons.bookmark_border, size: 20),
                  label: Text(l.readerBookmark),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showSettings = true),
                  icon: const Icon(Icons.tune, size: 20),
                  label: Text(l.readerSettings),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/reader/${widget.documentId}/ai'),
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text('AI'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(l.readerSettings, style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            _SettingSlider(
              label: l.readerWpm,
              value: 400,
              min: 100,
              max: 1500,
              divisions: 28,
              unit: ' WPM',
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            _SettingSlider(
              label: l.readerWordsPerDisplay,
              value: 1,
              min: 1,
              max: 20,
              divisions: 19,
              unit: ' words',
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            _SettingSlider(
              label: l.readerLineCount,
              value: 1,
              min: 1,
              max: 5,
              divisions: 4,
              unit: ' lines',
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l.readerAdaptiveSpeed),
              subtitle: Text(l.readerAdaptiveSpeedHint),
              value: false,
              onChanged: (v) {},
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => setState(() => _showSettings = false),
                child: Text(l.onboardingContinue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishedOverlay(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final stats = _display.stats;

    return Container(
      color: theme.colorScheme.surface.withValues(alpha: 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(l.readerFinished, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 24),
              if (stats != null) ...[
                _StatRow(label: l.statsWordsRead, value: '${stats.wordsRead}'),
                _StatRow(label: l.statsAvgWpm, value: '${stats.avgWpm}'),
                _StatRow(
                  label: l.statsFocusScore,
                  value: '${(stats.focusScore * 100).round()}%',
                ),
                _StatRow(
                  label: l.statsReadingTime,
                  value: '${stats.elapsed.inMinutes}m ${stats.elapsed.inSeconds % 60}s',
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/library'),
                child: Text(l.onboardingStart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingSlider extends StatelessWidget {
  const _SettingSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text('${value.round()}$unit',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
        Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
