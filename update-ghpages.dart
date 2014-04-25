import 'package:ghpages_generator/ghpages_generator.dart' as gh;

main() {
  new gh.Generator()
      ..setDartDoc(['lib/ghpages_generator.dart'], includeSdk: false,
          excludedLibs: ['path'], startPage: 'ghpages_generator')
      ..templateDir = 'gh-pages-template'
      ..generate();
}
