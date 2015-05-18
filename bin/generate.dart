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

final argParser = new ArgParser()
  ..addOption('root-dir', help: 'The path of the package directory.')
  ..addOption('template-dir',
      help: 'Indicates a template directory from which all files will be paste in "gh-pages".')
  ..addFlag('help', abbr: 'h', negatable: false, help: 'Display usage')
  ..addFlag('with-examples',
      negatable: false,
      help: 'Specify that the build of `example` directory have to be paste in "gh-pages".')
  ..addFlag('with-web',
      negatable: false,
      help: 'Specify that the build of `web` directory have to be paste in "gh-pages".')
  ..addFlag('with-docs',
      negatable: false,
      help: 'Specify that the `doc` directory have to be paste in "gh-pages".')
  ..addFlag('with-index-generation',
      negatable: false,
      help: 'Specify that your script has to generate index pages automatically if there does not exist');

main(List<String> args) {
  final argResult = argParser.parse(args);
  if (argResult['help']) {
    print(argParser.usage);
    return;
  }
  final generator = new Generator(rootDir: argResult['root-dir'])
    ..templateDir = argResult['template-dir']
    ..withExamples = argResult['with-examples']
    ..withWeb = argResult['with-web']
    ..withDocs = argResult['with-docs']
    ..withIndexGeneration = argResult['with-index-generation'];
  generator.generate();
}
