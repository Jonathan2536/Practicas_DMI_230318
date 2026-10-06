import 'package:flutter_test/flutter_test.dart';
import 'package:practica4/presentation/providers/discover_provider.dart';

void main() {
  test('loads the initial video posts', () async {
    final provider = DiscoverProvider();

    await provider.loadNextPage();

    expect(provider.initialLoading, isFalse);
    expect(provider.videos, isNotEmpty);
  });
}
