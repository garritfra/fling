import 'package:test/test.dart';
import 'package:fling_api/fling_api.dart';


/// tests for DefaultApi
void main() {
  final instance = FlingApi().getDefaultApi();

  group(DefaultApi, () {
    //Future<Health> v1HealthzGet() async
    test('test v1HealthzGet', () async {
      // TODO
    });

  });
}
