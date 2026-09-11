import 'dart:io';

import 'package:car_log/core/errors/app_exception.dart';
import 'package:car_log/features/receipt/data/receipt_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory documents;
  late ReceiptStorage storage;

  setUp(() {
    documents = Directory.systemTemp.createTempSync('car_log_docs');
    addTearDown(() => documents.deleteSync(recursive: true));
    storage = ReceiptStorage(documentsDirectory: () async => documents);
  });

  File sourceFile(String name, [String contents = 'receipt']) {
    final directory = Directory.systemTemp.createTempSync('car_log_pick');
    addTearDown(() => directory.deleteSync(recursive: true));
    return File(p.join(directory.path, name))..writeAsStringSync(contents);
  }

  test('stores a relative path, not an absolute one', () async {
    final stored = await storage.save(sourceFile('receipt.jpg'));

    expect(p.isRelative(stored), isTrue);
    expect(stored, startsWith('$receiptsDirectoryName/'));
    expect(stored, isNot(contains(documents.path)));
  });

  test('keeps the original extension', () async {
    expect(await storage.save(sourceFile('a.png')), endsWith('.png'));
    expect(await storage.save(sourceFile('b.pdf')), endsWith('.pdf'));
  });

  test('copies the contents into the app directory', () async {
    final stored = await storage.save(sourceFile('receipt.jpg', '영수증 내용'));

    final file = await storage.resolve(stored);
    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), '영수증 내용');
  });

  test('leaves the picked file where it was', () async {
    final source = sourceFile('receipt.jpg');

    await storage.save(source);

    expect(source.existsSync(), isTrue);
  });

  test('two saves of the same name do not collide', () async {
    final first = await storage.save(sourceFile('receipt.jpg', 'first'));
    final second = await storage.save(sourceFile('receipt.jpg', 'second'));

    expect(first, isNot(second));
    expect((await storage.resolve(first)).readAsStringSync(), 'first');
    expect((await storage.resolve(second)).readAsStringSync(), 'second');
  });

  test(
    'a stored path resolves against wherever the container is now',
    () async {
      final stored = await storage.save(sourceFile('receipt.jpg', 'moved'));

      // 앱을 재설치하면 컨테이너 경로가 바뀐다. 같은 상대 경로가 새 위치에서 풀려야 한다.
      final moved = Directory.systemTemp.createTempSync('car_log_docs2');
      addTearDown(() => moved.deleteSync(recursive: true));
      File(p.join(documents.path, stored)).copySync(
        (Directory(
              p.join(moved.path, receiptsDirectoryName),
            )..createSync(recursive: true)).path +
            Platform.pathSeparator +
            p.basename(stored),
      );

      final relocated = ReceiptStorage(documentsDirectory: () async => moved);
      expect((await relocated.resolve(stored)).readAsStringSync(), 'moved');
    },
  );

  test('delete removes the file', () async {
    final stored = await storage.save(sourceFile('receipt.jpg'));

    await storage.delete(stored);

    expect((await storage.resolve(stored)).existsSync(), isFalse);
  });

  test('deleting a file that is already gone is not an error', () async {
    await expectLater(
      storage.delete('$receiptsDirectoryName/missing.jpg'),
      completes,
    );
  });

  test('a failure surfaces as a ReceiptStorageException', () async {
    final broken = ReceiptStorage(
      documentsDirectory: () async => throw const FileSystemException('nope'),
    );

    expect(
      () => broken.save(sourceFile('receipt.jpg')),
      throwsA(isA<ReceiptStorageException>()),
    );
  });
}
