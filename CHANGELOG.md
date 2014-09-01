
# v0.2.2 (2014-09-01)

Switch to the new deferred loading syntax (needs DartSDK >= 1.6).

# v0.2.1 (2014-07-18)

Add a generator of index.html files with `withIndexGeneration`.

# v0.2.0 (2014-07-11)

Add utility functions to simplify the publication of examples at root with :

```dart
  new gh.Generator()
      ..withExamples = true
      ..generate(doCustomTask: gh.moveExampleAtRoot);
```

## breaking change

`setExamples` has been replaced by `withExamples`.

# v0.1.2 (2014-07-11)

Use `git -f add` to avoid problem with global .gitignore containing `packages`

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
