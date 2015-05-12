// Copyright (c) 2013, Alexandre Ardhuin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library ghpages_generator;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'index_generator.dart' deferred as ig;

/// Update the gh-pages branch with the pub build of web folder.
Future updateWithWebOnly({doCustomTask(String workDir)}) {
  final generator = new Generator()..withWeb = true;
  return generator.generate(doCustomTask: (String workDir) {
    moveWebAtRoot(workDir);
    if (doCustomTask != null) return doCustomTask(workDir);
  });
}

/// Move the dartdoc folder at the root.
void moveDartDocAtRoot(String workDir) {
  _moveContent(workDir, 'dartdoc');
}

/// Move the web folder at the root.
void moveWebAtRoot(String workDir) {
  _moveContent(workDir, 'web');
}

/// Move the example folder at the root.
void moveExampleAtRoot(String workDir) {
  _moveContent(workDir, 'example');
}

/// Move all files and directory  from a [from] folderinto the [base] folder.
/// The [from] folder must be a direct child of [base].
/// For instance :
///
///     _moveContent(workDir, 'web');
void _moveContent(String base, String from) {
  new Directory(path.join(base, from))
      .listSync()
      .forEach((e) => e.renameSync(path.join(base, path.basename(e.path))));
  _delete(base, [from]);
}

/// This class allows to generate a new version of gh-pages. You can choose
/// what you want to put in gh-pages : examples, dartdoc, docs and/or custom
/// files.
///
/// As sample here's how the gh-pages for this package is generated :
///
///     new gh.Generator()
///     ..setDartDoc(['lib/ghpages_generator.dart'], excludedLibs: ['path'])
///     ..templateDir = 'gh-pages-template'
///     ..generate();
///
class Generator {
  String _rootDir;
  String _workDir;
  String _gitRemoteOnRoot;

  List<String> _docGenOptions;
  List<String> _docGenFiles;

  bool _examples = false;
  bool _web = false;
  bool _docs = false;
  String _templateDir;
  bool _indexGeneration = false;

  /// Create a [Generator] based on the current directory where script is
  /// launched.
  ///
  /// You can customize the name of the directory with the [rootDir] named
  /// parameter.
  Generator({String rootDir}) {
    final timestamp = new DateTime.now().millisecondsSinceEpoch;
    _rootDir = rootDir != null
        ? rootDir
        : path.dirname(path.absolute(Platform.script.toFilePath()));
    _workDir = path.join(
        _rootDir, '../${path.basename(_rootDir)}-ghpages-${timestamp}');
    _gitRemoteOnRoot = 'origin-${timestamp}';
  }

  /// The directory use to build the gh-pages branch.
  String get workDir => _workDir;

  /// Specify that _dartDoc_ have to be generated for the given [files] using
  /// the `docgen` command line tool.
  ///
  /// Options can be set through the named parameters. By default, _dartDoc_ is
  /// generated in `docs/dartdoc`.
  setDartDoc(List<String> files, {bool includePrivate, bool includeSdk,
      bool parseSdk, String introduction, List<String> excludedLibs,
      bool includeDependentPackages, String startPage}) {
    _docGenFiles = files;
    _docGenOptions = ['--compile', '--package-root=packages'];
    if (includePrivate == true) {
      _docGenOptions.add('--include-private');
    }
    if (includeSdk == true) {
      _docGenOptions.add('--include-sdk');
    }
    if (parseSdk == true) {
      _docGenOptions.add('--parse-sdk');
    }
    if (introduction != null) {
      _docGenOptions.add('--introduction=$introduction');
    }
    if (excludedLibs != null) {
      excludedLibs.forEach((e) => _docGenOptions.add('--exclude-lib=$e'));
    }
    if (includeDependentPackages == true) {
      _docGenOptions.add('--include-dependent-packages');
    }
    if (startPage != null) {
      _docGenOptions.add('--start-page=$startPage');
    }
  }

  /// Specify that the `example` directory have to be paste in _gh-pages_.
  set withExamples(bool value) => _examples = value;

  /// Specify that the `web` directory have to be paste in _gh-pages_.
  set withWeb(bool value) => _web = value;

  /// Specify that the `docs` directory have to be paste in _gh-pages_.
  set withDocs(bool value) => _docs = value;

  /// Indicates a template directory from which all files will be paste in
  /// _gh-pages_.
  set templateDir(String templateDir) => _templateDir = templateDir;

  /// Specify that your script has to generate index pages automatically
  /// if there does not exist in [_workDir] and sub-directories of [_workDir]
  set withIndexGeneration(bool value) => _indexGeneration = value;

  /// Generate gh-pages. A [doCustomTask] method can be set to perform custom
  /// operations just before committing files.
  Future generate({doCustomTask(String workDir)}) async {
    new Directory(_workDir).createSync();
    try {
      _copy(_rootDir, _workDir, ['.git']);

      // git clone and preparation of the gh-pages branch
      await _run('git', ['reset', '--hard']);
      await _run('git', ['remote', 'add', _gitRemoteOnRoot, _rootDir]);
      final resultCheckout = await _run('git', ['checkout', 'gh-pages']);
      if (resultCheckout.exitCode != 0) {
        await _run('git', ['checkout', '--orphan', 'gh-pages']);
      }
      await _run('git', ['rm', '-rf', '.']);

      // copy of directories
      final elementsToCopy = ['pubspec.yaml', 'pubspec.lock', 'lib'];
      if (_examples) elementsToCopy.add('example');
      if (_web) elementsToCopy.add('web');
      if (_docs) elementsToCopy.add('docs');
      _copy(_rootDir, _workDir, elementsToCopy,
          accept: (pathToCopy) => path.basename(pathToCopy) != 'packages');

      // get deps
      await _run('pub', ['get']);

      if (_examples) {
        print('examples compilation...');

        await _run('pub', ['build', 'example']);

        // move build to example and remove web
        _delete(_workDir, ['example']);
        new Directory(path.join(_workDir, 'build', 'example'))
            .renameSync(path.join(_workDir, 'example'));
      }

      if (_web) {
        print('web compilation...');

        await _run('pub', ['build', 'web']);

        // move build to example and remove web
        _delete(_workDir, ['web']);
        new Directory(path.join(_workDir, 'build', 'web'))
            .renameSync(path.join(_workDir, 'web'));
      }

      if (_docGenFiles != null && _docGenFiles.isNotEmpty) {
        print('dartDoc generation...');
        await _run('docgen', []
          ..addAll(_docGenOptions)
          ..addAll(_docGenFiles));

        new Directory(
                path.join(_workDir, 'dartdoc-viewer', 'client', 'out', 'web'))
            .renameSync(path.join(_workDir, 'dartdoc'));
        new Directory(path.join(_workDir, 'dartdoc', 'packages')).deleteSync(
            recursive: true);
        new Directory(path.join(
                _workDir, 'dartdoc-viewer', 'client', 'out', 'packages'))
            .renameSync(path.join(_workDir, 'dartdoc', 'packages'));
      }

      _delete(_workDir, [
        'build',
        'packages',
        'lib',
        'pubspec.yaml',
        'pubspec.lock',
        'dartdoc-viewer',
        '.pub'
      ]);

      if (_templateDir != null) {
        final template = path.join(_rootDir, _templateDir);
        _copy(template, _workDir, new Directory(template)
            .listSync()
            .map((e) => path.basename(e.path)));
      }

      if (_indexGeneration) {
        await ig.loadLibrary();
        await new ig.IndexGenerator.fromPath(_workDir).generate();
      }

      if (doCustomTask != null) await doCustomTask(_workDir);

      await _run('git', ['add', '-f', '.']);
      await _run('git', ['commit', '-m', 'update gh-pages']);
      await _run('git', ['push', _gitRemoteOnRoot, 'gh-pages']);

      print("Your gh-pages has been updated.");
      print("You can now push it on github.");
    } finally {
      new Directory(_workDir).deleteSync(recursive: true);
    }
  }

  Future<ProcessResult> _run(String executable, List<String> arguments) =>
      Process.run(executable, arguments, workingDirectory: _workDir);
}

void _delete(String dir, List<String> elements) {
  elements.forEach((e) {
    final name = path.join(dir, e);
    if (FileSystemEntity.isDirectorySync(name)) {
      new Directory(name).deleteSync(recursive: true);
    } else if (FileSystemEntity.isFileSync(name)) {
      new File(name).deleteSync();
    }
  });
}

void _copy(
    String sourceDirPath, String targetDirPath, Iterable<String> elementsToCopy,
    {bool accept(String sourcePath)}) {
  for (final element in elementsToCopy) {
    final sourcePath = path.join(sourceDirPath, element);

    // next if not acceptable
    if (accept != null && !accept(sourcePath)) continue;

    // copy
    final targetPath = path.join(targetDirPath, element);
    if (FileSystemEntity.isDirectorySync(sourcePath)) {
      new Directory(targetPath).createSync();
      _copy(sourcePath, targetPath, new Directory(sourcePath)
          .listSync()
          .map((e) => path.basename(e.path)), accept: accept);
    } else if (FileSystemEntity.isFileSync(sourcePath)) {
      new File(targetPath)
        ..createSync()
        ..writeAsBytesSync(new File(sourcePath).readAsBytesSync());
    }
  }
}
