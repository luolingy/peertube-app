import 'package:flutter_test/flutter_test.dart';
import 'package:peertube_app/core/formatters.dart';
import 'package:peertube_app/data/api_section.dart';
import 'package:peertube_app/models/json_utils.dart';
import 'package:peertube_app/models/paged.dart';
import 'package:peertube_app/models/video.dart';

void main() {
  group('csv', () {
    test('joins values and drops empties', () {
      expect(csv(<int>[1, 2, 3]), '1,2,3');
      expect(csv(<String>['a', '', 'b']), 'a,b');
      expect(csv(null), isNull);
      expect(csv(const <int>[]), isNull);
    });
  });

  group('json_utils', () {
    test('reads defensively', () {
      expect(jsonInt('42'), 42);
      expect(jsonInt(null, 7), 7);
      expect(jsonStringOrNull('x'), 'x');
      expect(jsonBoolOrNull('yes'), isNull);
      expect(jsonMapList(null), isEmpty);
    });
  });

  group('PagedResult', () {
    test('parses total and data', () {
      final page = PagedResult<Video>.fromJson(<String, dynamic>{
        'total': 2,
        'data': <dynamic>[
          <String, dynamic>{'id': 1, 'uuid': 'u1', 'shortUUID': 's1', 'name': 'a'},
          <String, dynamic>{'id': 2, 'uuid': 'u2', 'shortUUID': 's2', 'name': 'b'},
        ],
      }, Video.fromJson);

      expect(page.total, 2);
      expect(page.data.length, 2);
      expect(page.data.first.name, 'a');
    });
  });

  group('formatters', () {
    test('formats durations and counts', () {
      expect(formatDuration(65), '1:05');
      expect(formatDuration(3661), '1:01:01');
      expect(formatCount(999), '999');
      expect(formatCount(1234), '1.2k');
      expect(formatCount(15000), contains('万'));
      expect(formatBytes(0), '0 B');
      expect(formatBytes(2048), contains('KB'));
    });
  });

  group('VideoConstant', () {
    test('keeps string ids (languages)', () {
      final constant = VideoConstant.fromJson(<String, dynamic>{
        'id': 'zh-Hans',
        'label': '简体中文',
      });
      expect(constant.key, 'zh-Hans');
      expect(constant.id, isNull);
      expect(constant.label, '简体中文');
    });

    test('keeps numeric ids (categories)', () {
      final constant = VideoConstant.fromJson(<String, dynamic>{'id': 5, 'label': '音乐'});
      expect(constant.key, '5');
      expect(constant.id, 5);
    });
  });
}
