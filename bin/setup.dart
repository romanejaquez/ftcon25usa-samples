// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';

import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:args/args.dart';

const packageName = 'rive_native';

// Flags
const flagBuild = 'build';
const flagClean = 'clean';
const flagVerbose = 'verbose';
const flagPlatform = 'platform';

enum TargetPlatform {
  android,
  ios,
  macos,
  windows,
  linux,
  web,
}

// Global state
bool verboseDebugEnabled = false;

void main(List<String> arguments) async {
  exitCode = 0; // Presume success

  final parser = ArgParser()
    ..addFlag(flagBuild,
        negatable: false,
        abbr: 'b',
        help: 'Build libraries instead of downloading')
    ..addFlag(flagClean,
        negatable: false, abbr: 'c', help: 'Clean the provided platforms')
    ..addFlag(flagVerbose,
        negatable: false, abbr: 'v', help: 'Enable verbose logging')
    ..addFlag('help',
        negatable: false, abbr: 'h', help: 'Display this help message')
    ..addMultiOption(flagPlatform,
        allowed: TargetPlatform.values.map((p) => p.name),
        abbr: 'p',
        help:
            'Target platforms to setup (${TargetPlatform.values.map((p) => p.name).join(", ")})');

  ArgResults results = parser.parse(arguments);

  // List of package paths that should not run this setup
  const excludedPaths = [
    'rive/packages/editor',
    // Add more paths here as needed
  ];
  if (excludedPaths.any((path) => Directory.current.path.endsWith(path))) {
    Print.standard(
      '''Exiting: `rive_native` setup.dart won't run from excluded local packages. Build `rive_native` from the `rive_native/native` directory for local development.''',
      color: Print.green,
      showPackage: false,
    );
    exit(0);
  }

  if (results['help']) {
    Print.standard(
      '\nRive Native Setup Tool\n',
      color: Print.green,
      showPackage: false,
    );
    Print.standard(parser.usage, showPackage: false);
    Print.standard('\nDownload example (comma separated platforms):',
        showPackage: false);
    Print.standard(
        '    dart run rive_native:setup --verbose --clean -p ios,macos',
        color: Print.blue,
        showPackage: false);
    Print.standard('\nBuild example (comma separated platforms):',
        showPackage: false);
    Print.standard(
        '    dart run rive_native:setup --build --verbose --clean -p android,windows',
        color: Print.blue,
        showPackage: false);
    Print.standard('', showPackage: false);

    exit(0);
  }

  Print.standard('Starting Rive Native Setup...\n');

  verboseDebugEnabled = results.flag(flagVerbose);

  final riveSetup = RiveSetup(
    platforms: results
        .multiOption(flagPlatform)
        .map((p) => TargetPlatform.values.byName(p))
        .toList(),
    buildLibraries: results.flag(flagBuild),
    cleanEnabled: results.flag(flagClean),
  );

  try {
    await riveSetup.init();
  } on Exception catch (e, st) {
    Print.error(e.toString());
    Print.error(st.toString());
    exit(1);
  }
}

class RiveSetup {
  /// List of platforms to setup
  final List<TargetPlatform> platforms;

  /// Clean the provided [platforms]
  final bool cleanEnabled;

  /// Build the libraries instead of downloading
  final bool buildLibraries;

  late String _packagePath;

  /// Setup Rive Native in a new environment where the Rive binaries have not
  /// been built or donwloaded. This only needs to be called once. However,
  /// it can be called multiple times to rebuild/redownload.
  ///
  /// - Provide list of [platforms]  to setup.
  /// - Set [cleanEnabled] to `true` to clean the provided platform.
  /// - Set [buildLibraries] to `true` to build libraries instead of download.
  RiveSetup({
    required this.platforms,
    this.cleanEnabled = false,
    this.buildLibraries = false,
  }) {
    try {
      _packagePath = _findPackageLocation();

      if (platforms.isEmpty) {
        platforms.add(runningPlatform);
      }
    } on Exception catch (e, st) {
      Print.error(e.toString());
      Print.error(st.toString());
      exit(1);
    }
  }

  Future<void> init() async {
    if (cleanEnabled) {
      List<Future<void>> cleanFutures = [];
      for (final platform in platforms) {
        cleanFutures.add(_clean(platform));
      }
      await Future.wait(cleanFutures);
    }

    for (final platform in platforms) {
      if (!cleanEnabled && await _markerFileExists(platform)) {
        Print.standard(
            '$packageName libraries already present for ${platform.name}. Not building/downloading libraries.',
            color: Print.yellow);
        Print.standard('', color: Print.yellow);
        Print.standard('To force a rebuild/download, run with `--clean`',
            color: Print.yellow);
        return;
      }

      Print.verbose(
          '''Initializing Rive Native for $platform. This may take some time the first time it is run.''');

      if (buildLibraries) {
        await _buildBinaries(platform);
      } else {
        await _downloadBinaries(platform);
      }
    }
  }

  Future<void> _clean(TargetPlatform platform) async {
    Print.standard('Cleaning $packageName ${platform.name}', color: Print.cyan);

    if (await _downloadMarkerFile(platform).exists()) {
      await _downloadMarkerFile(platform).delete();
    }

    if (await _developerMarkerFile(platform).exists()) {
      await _developerMarkerFile(platform).delete();
    }

    if (await _destinationDirectory(platform).exists()) {
      await _destinationDirectory(platform).delete(recursive: true);
    }
  }

  String _findPackageLocation() {
    // Assumed package root
    var root = Directory.current.uri;

    // Resolved package location running from build scripts
    if (root.path.endsWith('/macos/Pods/') ||
        root.path.endsWith('/ios/Pods/')) {
      root = root.resolve('../..');
    }

    final pubspecFile = File.fromUri(root.resolve('pubspec.yaml'));
    if (pubspecFile.existsSync()) {
      // Check if the pubspec.yaml contains a workspace resolution
      final pubspecContent = pubspecFile.readAsStringSync();
      if (pubspecContent.contains('resolution: workspace')) {
        final workspacePackagesOutput = Process.runSync(
          'dart',
          ['pub', 'workspace', 'list'],
          workingDirectory: root.toFilePath(),
        ).stdout.toString();
        final lines = workspacePackagesOutput.split('\n');
        if (lines.length > 1) {
          final tokens = lines[1]
              .split(RegExp(r'\s+'))
              .where((token) => token.isNotEmpty)
              .toList();
          if (tokens.length > 1) {
            final firstPackagePath = tokens[1];
            root = root.resolveUri(Uri.directory(firstPackagePath));
          } else {
            Print.error('Unable to parse workspace package path.');
          }
        } else {
          Print.error('Workspace yaml file not formated correctly.');
        }
        Print.verbose(
            'Workspace project root detected. Building $packageName with adjusted project root in:');
      } else {
        Print.verbose('Building $packageName with assumed project root in:');
      }
    } else {
      Print.error('Pubspec.yaml not found. Please run from the package root.');
    }
    Print.verbose('${root.toFilePath()}\n');

    final packageConfigFile =
        File.fromUri(root.resolve('.dart_tool/package_config.json'));

    if (!packageConfigFile.existsSync()) {
      throw Exception('Package config file not found.');
    }

    Map<String, dynamic> packageConfig;
    try {
      packageConfig = json.decode(packageConfigFile.readAsStringSync());
    } on FileSystemException {
      const errorMessage = '''
Missing .dart_tool/package_config.json
Run `flutter pub get` first.
      ''';
      throw Exception(errorMessage);
    } on FormatException {
      const message = '''
Invalid .dart_tool/package_config.json
Run `flutter pub get` first.
''';
      throw Exception(message);
    }

    final pkg = (packageConfig['packages'] ?? []).firstWhere(
      (e) => e['name'] == packageName,
      orElse: () => null,
    );
    if (pkg == null) {
      throw Exception('dependency on package:$packageName is required');
    }
    final packageRoot = packageConfigFile.uri.resolve(pkg['rootUri'] ?? '');
    Print.verbose(
        'Using package:$packageName from ${packageRoot.toFilePath()}');

    return packageRoot.toFilePath();
  }

  Future<void> _buildBinaries(TargetPlatform platform) async {
    Print.standard('Building $packageName ${platform.name}');

    try {
      _validatePlatformBuild(platform);
      await _runBuildScript(platform);
      await _markComplete(platform);
    } on Exception catch (e, st) {
      Print.error(e.toString());
      Print.error(st.toString());
      exit(1);
    }
  }

  void _validatePlatformBuild(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.macos:
        if (!Platform.isMacOS) {
          throw Exception('You can only build for macOS on macOS');
        }
      case TargetPlatform.ios:
        if (!Platform.isMacOS) {
          throw Exception('You can only build for iOS on macOS');
        }
      case TargetPlatform.linux:
        if (!Platform.isLinux) {
          throw Exception('You can only build for Linux on Linux');
        }
      case TargetPlatform.windows:
        if (!Platform.isWindows) {
          throw Exception('You can only build for Windows on Windows');
        }
      // Can build android and web on any OS
      case TargetPlatform.android:
      case TargetPlatform.web:
    }
  }

  Future<void> _runBuildScript(TargetPlatform platform) async {
    Print.verbose('Running build script for ${platform.name}');
    const String setup = 'cd native';
    final clean = cleanEnabled ? 'clean' : '';

    List<String> buildCommands = [];

    var flags = "flutter-runtime $clean";

    switch (platform) {
      case TargetPlatform.macos:
        buildCommands.add('$setup && ./build.sh release $flags');
        buildCommands.add('$setup && ./build.sh shared $flags');
        break;
      case TargetPlatform.ios:
        buildCommands.add('$setup && ./build.sh release ios $flags');
        buildCommands.add('$setup && ./build.sh release ios emulator $flags');
        break;
      case TargetPlatform.windows:
        buildCommands.add('$setup && ./build.sh $flags');
        buildCommands.add('$setup && ./build.sh release $flags');
      case TargetPlatform.linux:
        buildCommands.add('$setup && ./build.sh release $flags');
      case TargetPlatform.android:
        buildCommands.add('$setup && ./build.sh release android $flags');
      case TargetPlatform.web:
        buildCommands.add('$setup && ./build.sh wasm $flags');
    }

    Print.verbose('Running build commands for ...');
    for (final command in buildCommands) {
      Print.verbose(command);
    }
    Print.standard('');
    Print.standard('This may take some time.');

    for (final command in buildCommands) {
      final process = await Process.start(
        'bash',
        ['-c', command],
        workingDirectory: _packagePath,
      );

      process.stdout.transform(utf8.decoder).listen((data) {
        if (verboseDebugEnabled) {
          stdout.write(data);
        }
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        stderr.write(data);
      });

      // Wait for the process to complete
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw Exception('Failed to run build script. Exit code: $exitCode');
      }
    }
  }

  Future<void> _downloadBinaries(TargetPlatform platform) async {
    final versionFile = File('$_packagePath/version.txt');
    if (!versionFile.existsSync()) {
      throw Exception('$packageName version file not found.');
    }
    final version = (await versionFile.readAsString()).trim();

    final encodedVersion = Uri.encodeComponent(version);
    final encodedPlatform = Uri.encodeComponent(platform.name);
    final zipUrl =
        'https://rive-flutter-artifacts.rive.app/rive_native_versions/$encodedVersion/rive_native_artifacts_$encodedPlatform.zip';
    Print.standard(
        'Downloading "${platform.name}" libraries for version "$version"',
        color: Print.cyan);
    Print.verbose('URL: $zipUrl');

    final hashJsonFile = File('$_packagePath/hash.txt');
    if (!hashJsonFile.existsSync()) {
      throw Exception('Hash file not found.');
    }
    final hashJson = json.decode(await hashJsonFile.readAsString());
    final expectedHash = hashJson[platform.name];

    if (expectedHash == null) {
      throw Exception(
          'Hash for platform ${platform.name} not found in hash.txt.');
    }

    Directory destinationDir = _destinationDirectory(platform);

    // Get the temporary directory path in a cross-platform way
    final tempDir = Directory.systemTemp.path;

    final zipFile = File('$tempDir/file.zip');
    final zipResponse = await http.get(Uri.parse(zipUrl));
    await zipFile.writeAsBytes(zipResponse.bodyBytes);

    // Compute and verify hashes
    final computedHash = await _calculateShaSum(zipFile.path);
    if (computedHash != expectedHash.trim()) {
      await zipFile.delete();
      throw Exception('Hash verification failed. Exiting script.');
    }

    await destinationDir.create(recursive: true);
    await _unzipFile(zipFile.path, destinationDir.path);

    _markComplete(platform);

    await zipFile.delete();
  }

  /// Mark setup as complete
  Future<void> _markComplete(TargetPlatform platform) async {
    final name = platform.name;
    final setupCompleteMarker =
        File('$_packagePath/$name/rive_marker_${name}_setup_complete');
    await setupCompleteMarker.create();
  }

  Future<String> _calculateShaSum(String filePath,
      {int algorithm = 512}) async {
    ProcessResult result;

    if (Platform.isWindows) {
      String algoFlag;
      switch (algorithm) {
        case 256:
          algoFlag = 'SHA256';
          break;
        case 512:
          algoFlag = 'SHA512';
          break;
        default:
          throw UnsupportedError(
              'Algorithm not supported on Windows: SHA-$algorithm');
      }
      result = await Process.run('CertUtil', ['-hashfile', filePath, algoFlag]);
      if (result.exitCode != 0) {
        throw Exception(
            'Failed to calculate SHA checksum on Windows: ${result.stderr}');
      }
      // The output is in the form:
      // SHA<algo> hash of filePath:
      // <checksum>
      // CertUtil: -hashfile command completed successfully.
      // We need to extract the checksum from the second line of the output.
      String checksum = result.stdout.toString().split('\n')[1].trim();
      return checksum;
    } else {
      result = await Process.run('shasum', ['-a', '$algorithm', filePath]);
      if (result.exitCode != 0) {
        throw Exception(
            'Failed to calculate SHA checksum on Unix-like systems: ${result.stderr}');
      }
      String checksum = result.stdout.toString().split(' ').first.trim();
      return checksum;
    }
  }

  Future<void> _unzipFile(String zipFilePath, String destinationPath) async {
    if (Platform.isMacOS || Platform.isLinux) {
      final result = await Process.run(
          'unzip', ['-o', zipFilePath, '-d', destinationPath]);
      if (result.exitCode != 0) {
        throw Exception('Failed to unzip the file: ${result.stderr}');
      }
    } else if (Platform.isWindows) {
      final result = await Process.run('powershell', [
        'Expand-Archive',
        '-Path',
        zipFilePath,
        '-DestinationPath',
        destinationPath,
        '-Force'
      ]);
      if (result.exitCode != 0) {
        throw Exception('Failed to unzip the file: ${result.stderr}');
      }
    } else {
      throw UnsupportedError('Unzipping not supported on this platform');
    }
  }

  TargetPlatform get runningPlatform {
    TargetPlatform platform;
    if (Platform.isMacOS) {
      platform = TargetPlatform.macos;
    } else if (Platform.isWindows) {
      platform = TargetPlatform.windows;
    } else if (Platform.isLinux) {
      platform = TargetPlatform.linux;
    } else {
      throw Exception('$packageName current operating system is not supported');
    }
    return platform;
  }

  File _developerMarkerFile(TargetPlatform platform) {
    final name = platform.name;
    return File('$_packagePath/$name/rive_marker_${name}_development');
  }

  File _downloadMarkerFile(TargetPlatform platform) {
    final name = platform.name;
    return File('$_packagePath/$name/rive_marker_${name}_setup_complete');
  }

  Future<bool> _markerFileExists(TargetPlatform platform) async =>
      await _developerMarkerFile(platform).exists() ||
      await _downloadMarkerFile(platform).exists();

  Directory _destinationDirectory(TargetPlatform platform) {
    String packagePath =
        _packagePath.endsWith('/') || _packagePath.endsWith('\\')
            ? _packagePath.substring(0, _packagePath.length - 1)
            : _packagePath;

    Directory destinationDir;

    switch (platform) {
      case TargetPlatform.macos:
        destinationDir = Directory('$packagePath/native/build/macosx/bin/');
        break;
      case TargetPlatform.windows:
        destinationDir = Directory('$packagePath/windows/bin/');
        break;
      case TargetPlatform.ios:
        destinationDir = Directory('$packagePath/native/build/iphoneos/bin/');
        break;
      case TargetPlatform.android:
        destinationDir = Directory('$packagePath/android/src/main/jniLibs/');
      default:
        throw Exception('$platform not yet supported');
    }

    return destinationDir;
  }
}

abstract class Print {
  // ANSI Color Codes
  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _white = '\x1B[37m';

  // Optional colors for standard print
  static const none = '';
  static const cyan = '\x1B[36m';
  static const yellow = '\x1B[33m';
  static const green = '\x1B[32m';
  static const blue = '\x1B[34m';
  static const magenta = '\x1B[35m';

  static bool get _supportsColor {
    if (stdout.hasTerminal) {
      return stdout.supportsAnsiEscapes;
    }
    return false;
  }

  static String _withColor(String message, String color) {
    if (_supportsColor && color.isNotEmpty) {
      return '$color$message$_reset';
    }
    return message;
  }

  static void verbose(String message) {
    if (verboseDebugEnabled) {
      standard(message, color: _white);
    }
  }

  static void standard(String message,
      {String color = '', bool showPackage = true}) {
    final prefix = showPackage ? '[$packageName]   ' : '';
    print(_withColor('$prefix$message', color));
  }

  static void error(String message) {
    standard(message, color: _red);
  }
}
