
# v0.1.1 (2014-05-09)

Add utility functions to simplify the publication of dartdoc at root with :

```dart
  new gh.Generator()
      ..setDartDoc(['lib/ghpages_generator.dart'], includeSdk: false,
          excludedLibs: ['path'], startPage: 'ghpages_generator')
      ..generate(doCustomTask: gh.moveDartDocAtRoot);
```

# Semantic Version Conventions

http://semver.org/

- *Stable*:  All even numbered minor versions are considered API stable:
  i.e.: v1.0.x, v1.2.x, and so on.
- *Development*: All odd numbered minor versions are considered API unstable:
  i.e.: v0.9.x, v1.1.x, and so on.
