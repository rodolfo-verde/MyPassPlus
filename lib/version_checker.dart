import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionChecker {
  static Future<Map<String, String>?> hasNewerVersion() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.github.com/repos/rodolfo-verde/MyPassPlus/releases/latest'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name'].toString().replaceAll('v', '');

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_compareVersions(latestVersion, currentVersion) > 0) {
          return {
            'currentVersion': currentVersion,
            'latestVersion': latestVersion,
          };
        }
      }
    } catch (e) {
      // Silently fail on error
    }
    return null;
  }

  static int _compareVersions(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map(int.parse).toList();
    List<int> v2Parts = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < v1Parts.length && i < v2Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }
    return v1Parts.length.compareTo(v2Parts.length);
  }
}
