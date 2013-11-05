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

/**
 * This class allows to generate a new version of gh-pages. You can choose
 * what you want to put in gh-pages : examples, dartdoc, docs and/or custom
 * files.
 *
 * As sample here's how the gh-pages for this package is generated :
 *
 *     new gh.Generator()
 *     ..setDartDoc(['lib/ghpages_generator.dart'], excludedLibs: ['path'])
 *     ..templateDir = 'gh-pages-template'
 *     ..generate();
 */
class Generator {
  String _rootDir;
  String _workDir;
  String _gitRemoteOnRoot;

  String _dartdocOutDir;
  List<String> _dartdocOptions;
  List<String> _dartdocFiles;

  bool _examples = false;
  bool _examplesCompileDart;

  bool _docs = false;
  String _templateDir;

  /**
   * Create a [Generator] based on the current directory where script is launch.
   * You can customize the name of the directory with the [rootDir] named
   * parameter.
   */
  Generator({String rootDir}) {
    final timestamp = new DateTime.now().millisecondsSinceEpoch;
    _rootDir = rootDir != null ? rootDir : path.dirname(path.absolute(Platform.script.path));
    _workDir = path.join(_rootDir, '../${path.basename(_rootDir)}-ghpages-${timestamp}');
    _gitRemoteOnRoot = 'origin-${timestamp}';
  }

  /// The directory use to build the gh-pages branch.
  String get workDir => _workDir;

  /**
   * Specify that _dartdoc_ have to be generated for the given [files].
   * [dartdoc](http://www.dartlang.org/docs/dart-up-and-running/contents/ch04-tools-dartdoc.html)
   * options can be set through the named parameters. By default, _dartdoc_ is
   * generated in `docs/dartdoc` in _static_ mode and without code.
   */
  setDartDoc(List<String> files, {String outDir: 'docs/dartdoc',
      bool code: false, List<String> excludedLibs, bool omitGenerationTime,
      String mode: 'static'}) {
    _dartdocFiles = files;
    _dartdocOptions = ['--package-root=packages'];
    if (outDir != null) {
      _dartdocOutDir = outDir;
      _dartdocOptions.add('--out=$outDir');
    }
    if (code != null && !code) {
      _dartdocOptions.add('--no-code');
    }
    if (excludedLibs != null) {
      excludedLibs.forEach((e) => _dartdocOptions.add('--exclude-lib=$e'));
    }
    if (omitGenerationTime != null && omitGenerationTime){
      _dartdocOptions.add('--omit-generation-time');
    }
    if (mode != null) {
      _dartdocOptions.add('--mode=$mode');
    }
  }

  /// Specify that examples have to be compiled and included in _gh-pages_.
  setExamples(bool value, {compileDart: true}) {
    _examples = value;
    _examplesCompileDart = compileDart;
  }

  /// Specify that the `docs` directory have to be paste in _gh-pages_.
  set withDocs(bool value) => _docs = value;

  /// Indicates a template directory from which all files will be paste in
  /// _gh-pages_.
  set templateDir(String templateDir) => _templateDir = templateDir;

  /// Generate gh-pages. A [doCustomTask] method can be set to perform custom
  /// operations just before committing files.
  Future<dynamic> generate({doCustomTask()}) {
    new Directory(_workDir).createSync();
    _copy(_rootDir, _workDir, ['.git']);

    // git clone
    return Process.run('git', ['reset', '--hard'], workingDirectory: _workDir)
      .then((_) => Process.run('git', ['remote', 'add', _gitRemoteOnRoot, _rootDir], workingDirectory: _workDir))
      .then((_) => Process.run('git', ['checkout', 'gh-pages'], workingDirectory: _workDir)
          .then((pr) {
            if (pr.exitCode != 0) {
              return Process.run('git', ['checkout', '--orphan', 'gh-pages'], workingDirectory: _workDir);
            }
          }))
      .then((_) => Process.run('git', ['rm', '-rf', '.'], workingDirectory: _workDir))
      .then((_){
        // copy of directories
        final elementsToCopy = ['pubspec.yaml', 'pubspec.lock', 'lib'];
        if (_examples) elementsToCopy.add('example');
        if (_docs) elementsToCopy.add('docs');
        _copy(_rootDir, _workDir, elementsToCopy,
            accept: (pathToCopy) => path.basename(pathToCopy) != 'packages');
      })
      .then((_) => Process.run('pub', ['install'], workingDirectory: _workDir))
      .then((_){
        if (!_examples) return null;

        print('examples compilation...');

        // move example to web to use 'pub build'
        new Directory(path.join(_workDir, 'example'))
          .renameSync(path.join(_workDir, 'web'));
        return Process
          .run('pub', ['build'], workingDirectory: _workDir)
          .then((_){
            // move build to example and remove web
            new Directory(path.join(_workDir, 'build'))
              .renameSync(path.join(_workDir, 'example'));
            _delete(_workDir, ['web']);
          })
          .then((_){
            if (_examplesCompileDart != null && _examplesCompileDart) return;

            // copy origin files
            _copy(_rootDir, _workDir, ['example']);
          });
      })
      .then((_) {
        if (_dartdocFiles == null || _dartdocFiles.isEmpty) return null;

        print('dartdoc generation...');
        new Directory(path.join(_workDir, _dartdocOutDir)).createSync(recursive: true);
        return Process.run('dartdoc',
            []..addAll(_dartdocOptions)
              ..addAll(_dartdocFiles),
            workingDirectory: _workDir);
      })
      .then((_) {
        _delete(_workDir, ['packages', 'lib', 'pubspec.yaml', 'pubspec.lock']);
      })
      .then((_) {
        if (_templateDir != null) {
          final template = path.join(_rootDir, _templateDir);
          _copy(template, _workDir, new Directory(template).listSync().map((e) => path.basename(e.path)));
        }
      })
      .then((_) {
        if (doCustomTask != null) return doCustomTask();
      })
      .then((_) => Process.run('git', ['add', '.'], workingDirectory: _workDir))
      .then((_) => Process.run('git', ['commit', '-m', '"update gh-pages"'], workingDirectory: _workDir))
      .then((_) => Process.run('git', ['push', _gitRemoteOnRoot, 'gh-pages'], workingDirectory: _workDir))
      .then((_) {
        print("Your gh-pages has been updated.");
        print("You can now push it on github.");
      })
      .whenComplete((){
        new Directory(_workDir).deleteSync(recursive: true);
      })
      ;
  }

  void _delete(String dir, List<String> elements) {
    elements.forEach((e){
      final name = path.join(dir, e);
      if (FileSystemEntity.isDirectorySync(name)) new Directory(name).deleteSync(recursive: true);
      else if (FileSystemEntity.isFileSync(name)) new File(name).deleteSync();
    });
  }

  void _copy(String sourceDirPath, String targetDirPath,
             Iterable<String> elementsToCopy,
             {bool accept(String sourcePath)}) {
    for (final element in elementsToCopy) {
      final sourcePath = path.join(sourceDirPath, element);

      // next if not acceptable
      if (accept != null && !accept(sourcePath)) continue;

      // copy
      final targetPath = path.join(targetDirPath, element);
      if (FileSystemEntity.isDirectorySync(sourcePath)) {
        new Directory(targetPath).createSync();
        _copy(sourcePath, targetPath,
            new Directory(sourcePath).listSync().map((e) => path.basename(e.path)),
            accept: accept);
      } else if (FileSystemEntity.isFileSync(sourcePath)) {
        new File(targetPath)
          ..createSync()
          ..writeAsBytesSync(new File(sourcePath).readAsBytesSync());
      }
    }
  }
}