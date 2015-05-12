// Copyright (c) 2015, Alexandre Ardhuin
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

import 'package:args/args.dart';
import 'package:ghpages_generator/ghpages_generator.dart';

ArgParser get argParser => new ArgParser()
  ..addOption('root-dir')
  ..addOption('template-dir')
  ..addFlag('with-examples', negatable: false)
  ..addFlag('with-web', negatable: false)
  ..addFlag('with-docs', negatable: false)
  ..addFlag('with-index-generation', negatable: false);

main(List<String> args) {
  final argResult = argParser.parse(args);
  final generator = new Generator(rootDir: argResult['root-dir'])
    ..templateDir = argResult['template-dir']
    ..withExamples = argResult['with-examples']
    ..withWeb = argResult['with-web']
    ..withDocs = argResult['with-docs']
    ..withIndexGeneration = argResult['with-index-generation'];
  generator.generate();
}
