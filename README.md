# Dart Gh-Pages Generator

This project allows to create/update the _gh-pages_ branch based on _examples_,
_dartdoc_, _docs_, _web_ and/or custom files.

Basically a new commit is done in the _gh-pages_ branch with updated files
generated. Then you only need to _push_ this branch on _github_.

## Usage

### Running it

The package exposes a simple command-line wrapper around the core generating
library. The easiest way to invoke it is to
[globally activate](https://www.dartlang.org/tools/pub/cmd/pub-global.html) the
package and let pub put its executable on your path:

    $ pub global activate ghpages_generator
    $ generate_ghpages ...

If you don't want `generate_ghpages` on your path, you can run it explicitly:

    $ pub global activate ghpages_generator --no-executables
    $ pub global run ghpages_generator:generate ...

#### update with web

    # update the gh-pages branch with the result of `pub build web`
    $> generate_ghpages_with_web

#### custom

You can use `generate_ghpages` with several options/flags to update the
gh-pages (See `generate_ghpages -h`).

If you need more fine controls on the generation you have to use the api as
described bellow.

### Using the API

1. Add a `dev_dependency` in your `pubspec.yaml` to _ghpages_generator_.
1. Create a Dart script to define how is built you ghpages.

#### create dartdoc

Here's how is generated
gh-pages for this package](http://a14n.github.io/dart-ghpages-generator) :

```dart
import 'package:ghpages_generator/ghpages_generator.dart' as gh;

main() {
  new gh.Generator()
      ..setDartDoc(['lib/ghpages_generator.dart'], includeSdk: false,
          excludedLibs: ['path'], startPage: 'ghpages_generator')
      ..generate(doCustomTask: gh.moveDartDocAtRoot);
}
```

### Actions

Here's the available actions :

- generate the _dartdoc_ with `setDartDoc`
- compile and deploy the _example_ directory with `withExamples`
- compile and deploy the _web_ directory with `withWeb`
- add the `docs` directory with `withDocs`
- add the `index.html` files with `withIndexGeneration`
- add static files with `templateDir` : all files in the template directory are
pasted to the _gh-pages_ branch

## License ##
Apache 2.0
