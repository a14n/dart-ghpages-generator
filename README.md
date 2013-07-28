Dart Gh-Pages Generator
=======================
This project allows to create/update the _gh-pages_ branch based on _examples_, _dartdoc_,
_docs_ and/or custom files.

Basically a new commit is done in the _gh-pages_ branch with updated files
generated. Then you only need to _push_ this branch on _github_.

## Usage ##

Here's how is generated [gh-pages for this package](http://a14n.github.io/dart-ghpages-generator) :

```dart
import 'package:ghpages_generator/ghpages_generator.dart' as gh;

main() {
  new gh.Generator()
  ..setDartDoc(['lib/ghpages_generator.dart'], excludedLibs: ['path'])
  ..templateDir = 'gh-pages-template'
  ..generate();
}
```

## Actions ##

Here's the available actions :

- generate the _dartdoc_ with `setDartDoc`
- compile and deploy the _examples_ with `setExamples`
- add the `docs` directory with `withDocs`
- add static files with `templateDir` : all files in the template directory are
pasted to the _gh-pages_ branch

## License ##
Apache 2.0
