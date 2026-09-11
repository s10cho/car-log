import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_credentials.dart';
import '../domain/ai_provider.dart';

/// Connects an AI provider so receipts can be read automatically.
///
/// Entirely optional: with nothing connected the app behaves exactly as it did
/// before, and the record form simply does not offer analysis.
class AiSettingsPage extends ConsumerStatefulWidget {
  const AiSettingsPage({super.key});

  @override
  ConsumerState<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends ConsumerState<AiSettingsPage> {
  /// Provider ids whose key is stored, loaded once and kept in step by hand —
  /// secure storage has nothing to watch.
  Set<String> _connected = const {};
  String? _selected;
  bool _loading = true;
  String? _busyProviderId;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final credentials = ref.read(aiCredentialsProvider);
    final providers = ref.read(aiProvidersProvider);

    final connected = <String>{};
    for (final provider in providers) {
      final key = await credentials.apiKeyFor(provider.id);
      if (key != null && key.isNotEmpty) {
        connected.add(provider.id);
      }
    }
    final selected = await credentials.selectedProviderId();

    if (mounted) {
      setState(() {
        _connected = connected;
        _selected = selected;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providers = ref.watch(aiProvidersProvider);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI 영수증 분석')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '영수증 사진을 AI 로 읽어 정비 기록을 미리 채웁니다. 연결하지 않아도 앱의 모든 기능을 '
              '그대로 쓸 수 있고, 분석 결과는 저장 전에 항상 직접 확인합니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // RadioGroup owns the selection; the tiles only describe the choices.
          RadioGroup<String?>(
            groupValue: _selected,
            onChanged: _select,
            child: Column(
              children: [
                for (final provider in providers)
                  RadioListTile<String?>(
                    value: provider.id,
                    enabled: _connected.contains(provider.id),
                    title: Text(provider.displayName),
                    subtitle: Text(
                      _connected.contains(provider.id) ? '키 저장됨' : '키가 없습니다',
                    ),
                    secondary: _busyProviderId == provider.id
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: () => _enterKey(provider),
                            child: Text(
                              _connected.contains(provider.id) ? '변경' : '키 입력',
                            ),
                          ),
                  ),
              ],
            ),
          ),
          if (_selected != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: _disconnect,
                child: const Text('AI 사용 끄기'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'API 키는 이 기기의 보안 저장소(iOS Keychain / Android Keystore)에만 저장되며 '
              '백업 파일에는 포함되지 않습니다.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _select(String? id) async {
    if (id == null) {
      return;
    }
    await ref.read(aiCredentialsProvider).select(id);
    setState(() => _selected = id);
  }

  Future<void> _disconnect() async {
    await ref.read(aiCredentialsProvider).clearSelection();
    setState(() => _selected = null);
  }

  Future<void> _enterKey(AiProvider provider) async {
    final apiKey = await showDialog<String>(
      context: context,
      builder: (context) => _ApiKeyDialog(provider: provider),
    );
    if (apiKey == null || !mounted) {
      return;
    }

    if (apiKey.isEmpty) {
      await ref.read(aiCredentialsProvider).removeApiKey(provider.id);
      await _refresh();
      return;
    }

    setState(() => _busyProviderId = provider.id);
    // Validate before storing: a key that is wrong now will only fail later,
    // in front of a receipt the user is trying to record.
    bool valid;
    try {
      valid = await provider.validateCredential(apiKey);
    } on Object {
      valid = false;
    }

    if (!mounted) {
      return;
    }
    setState(() => _busyProviderId = null);

    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${provider.displayName} 키를 확인하지 못했습니다.')),
      );
      return;
    }

    final credentials = ref.read(aiCredentialsProvider);
    await credentials.saveApiKey(provider.id, apiKey);
    await credentials.select(provider.id);
    await _refresh();
  }
}

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.provider});

  final AiProvider provider;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.provider.displayName} API 키'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'API 키 붙여넣기'),
          ),
          const SizedBox(height: 12),
          SelectableText(
            widget.provider.credentialHelpUrl,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(''),
          child: const Text('키 삭제'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
