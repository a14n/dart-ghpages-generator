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

library publish_ghpages;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

class Publisher {
  String _rootDir;
  String _workDir;

  List<String> docOptions;
  List<String> docExclude;
  List<String> docFiles;

  bool examples = false;

  Publisher({String rootDir}) {
    _rootDir = rootDir != null ? rootDir : path.dirname(path.absolute(new Options().script));
    _workDir = path.join(_rootDir, '../${path.basename(_rootDir)}-ghpages-${new DateTime.now().millisecondsSinceEpoch}');
  }

  addDartDoc(List<String> files, {List<String> options : const ['--no-code', '--mode=static'],
      List<String> exclude}) {
    docFiles = files;
    docOptions = options;
    docExclude = exclude;
  }

  addExamples() {
    examples = true;
  }

  Future<dynamic> publish() {
    new Directory(_workDir).createSync();

    // git clone
    return Process.run('git', ['clone', '.', _workDir], workingDirectory: _rootDir)
      .then((_) => Process.run('git', ['checkout', 'gh-pages'], workingDirectory: _workDir))
      .then((_){
        // remove content
        new Directory(_workDir).listSync(followLinks: false)
          .where((e) => path.basename(e.path) != '.git')
          .forEach((e) =>
              e is Directory ? e.deleteSync(recursive: true) : e.deleteSync());
      })
      .then((_){
        // copy of directories
        final elementsToCopy = ['pubspec.yaml', 'lib'];
        if (examples) elementsToCopy.add('example');
        _copyTo(_rootDir, _workDir, elementsToCopy);
      })
      .then((_){
        if (!examples) return;

        print('examples compilation...');

        // move example to web to use 'pub deploy'
        new Directory(path.join(_workDir, 'example'))
          .renameSync(path.join(_workDir, 'web'));
        return Process
          .run('pub', ['install'], workingDirectory: _workDir)
          .then((_) => Process.run('pub', ['deploy'], workingDirectory: _workDir))
          .then((_){
            // move deploy to example and remove web
            new Directory(path.join(_workDir, 'deploy'))
              .renameSync(path.join(_workDir, 'example'));
            _delete(_workDir, ['web']);
          });
      })
      .then((_) {
        if (docFiles == null || docFiles.isEmpty) return;

        print('dartdoc generation...');

        return Process.run('dartdoc',
            ['--out=dartdoc']..addAll(docOptions)
              ..addAll(docExclude.map((e) => '--exclude-lib=$e'))
              ..addAll(docFiles),
            workingDirectory: _workDir);
      })
      .then((_) {
        _delete(_workDir, ['packages', 'lib', 'pubspec.yaml', 'pubspec.lock']);
      })
      .then((_) => Process.run('git', ['add', '-u', '.'], workingDirectory: _workDir))
      .then((_) => Process.run('git', ['commit', '-m', '"update ghpages"'], workingDirectory: _workDir))
      ;
  }

  void _delete(String dir, List<String> elements) {
    elements.forEach((e){
      final name = path.join(dir, e);
      if (FileSystemEntity.isDirectorySync(name)) new Directory(name).deleteSync(recursive: true);
      else if (FileSystemEntity.isFileSync(name)) new File(name).deleteSync();
    });
  }

  void _copyTo(String sourceDirPath, String targetDirPath, Iterable<String> elementsToCopy) {
    for (final element in elementsToCopy) {
      final sourcePath = path.join(sourceDirPath, element);
      final targetPath = path.join(targetDirPath, element);
      if (FileSystemEntity.isDirectorySync(sourcePath) && element != 'packages') {
        new Directory(targetPath).createSync();
        _copyTo(sourcePath, targetPath, new Directory(sourcePath).listSync().map((e) => path.basename(e.path)));
      } else if (FileSystemEntity.isFileSync(sourcePath)) {
        new File(targetPath)
          ..createSync()
          ..writeAsBytesSync(new File(sourcePath).readAsBytesSync());
      }
    }
  }
}