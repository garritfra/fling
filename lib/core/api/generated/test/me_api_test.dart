import 'package:test/test.dart';
import 'package:fling_api/fling_api.dart';


/// tests for MeApi
void main() {
  final instance = FlingApi().getMeApi();

  group(MeApi, () {
    //Future<Me> v1MeGet() async
    test('test v1MeGet', () async {
      // TODO
    });

    //Future<Me> v1MePatch(PatchMe patchMe) async
    test('test v1MePatch', () async {
      // TODO
    });

  });
}
