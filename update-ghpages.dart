import 'package:ghpages_generator/ghpages_generator.dart' as gh;

main() {
  new gh.Generator()
  ..setDartDoc(['lib/ghpages_generator.dart'], excludedLibs: ['path'])
  ..templateDir = 'gh-pages-template'
  ..generate();
}