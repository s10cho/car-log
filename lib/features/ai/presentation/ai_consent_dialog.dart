import 'package:flutter/material.dart';

/// Asks once before any receipt leaves the device.
///
/// A receipt carries a shop name, a date, a price and sometimes a plate number.
/// Sending that to a third party is the user's call to make knowingly, so the
/// dialog names the provider and says plainly what is sent.
Future<bool> showAiConsentDialog(
  BuildContext context, {
  required String providerName,
}) async {
  final agreed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('영수증을 AI 로 보낼까요?'),
      content: Text(
        '영수증 사진이 $providerName 으로 전송되어 분석됩니다.\n\n'
        '영수증에는 정비소, 날짜, 금액 같은 정보가 담겨 있습니다. '
        '분석 결과는 자동으로 저장되지 않고, 저장 전에 직접 확인하고 고칠 수 있습니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('직접 입력'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('동의하고 분석'),
        ),
      ],
    ),
  );
  return agreed ?? false;
}
