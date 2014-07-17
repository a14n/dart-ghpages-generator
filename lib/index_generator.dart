library ghpages_generator.index_generator;

import 'dart:io';
import 'dart:async';

import 'package:path/path.dart' as path;

/**
 * A generator for index pages such as 'index.html'.
 *
 * The following example code generates gh-pages and
 * automatically generates `index.html` if `index.html` doesn't exist
 * in the `example` directory:
 *
 *     new gh.Generator()
 *       ..withExamples = true;
 *       ..generate(doCustomTask: (workDir) {
 *         gh.moveExampleAtRoot(workDir);
 *         return new IndexGenerator.fromPath(workDir).generate();
 *       });
 *
 */
class IndexGenerator {
  static const _NOTHING = const Object();

  static const DEFAULT_INDEX_FILE_NAME = 'index.html';
  static const DEFAULT_EXCLUDES = const ['packages', '.git'];

  /// The target directory.
  Directory baseDir;

  List<File> _indexes;

  /**
   * The generated index files.
   * This value is `null` if [generate] wasn't executed.
   */
  List<File> get indexes => _indexes;

  /**
   * The index page name.
   * default: `index.html`
   */
  String indexFileName = DEFAULT_INDEX_FILE_NAME;

  /**
   * The flag whether this generator overwrite existing index pages.
   * default: `false`
   */
  bool overwrite = false;

  /**
   * The flag whether this generator generates all index pages in all sub directories.
   * default: `true`
   */
  bool recursive = true;

  /**
   * The directory names which are not indexed.
   * default: `[DEFAULT_EXCLUDES]`
   */
  List<Pattern> excludes = DEFAULT_EXCLUDES;

  /**
   * The index page content builder
   * default: [defaultHtmlWriter]
   */
  HtmlWriter htmlWriter = defaultHtmlWriter;

  // constructors

  IndexGenerator(this.baseDir);
  IndexGenerator.fromPath(String path): this(new Directory(path));

  // public methods

  /**
   * Generates index files which named [indexFileName].
   * Return a future of generated files.
   */
  Future<List<File>> generate() {
    if (_indexes != null) {
      print('Warning: you might generate more than once.');
    }
    Stream<Directory> dirs =
        recursive ? _dirs : new Stream.fromIterable([baseDir]);
    return _generate(dirs);
  }

  /**
   * Deletes index files generated with [generate].
   * Return a future of deleted (generated) files.
   */
  Future<List<File>> delete() {
    if (_indexes == null) {
      throw new StateError('Cannot delete: you might not generate index pages');
    }
    var deleteds = _indexes.map((f) {
      print('Delete index page: ${f.path}');
      return f.delete();
    });
    return Future.wait(deleteds);
  }

  // private methods

  Future<List<File>> _generate(Stream<Directory> dirs) {
    Stream<File> targetIndexes = dirs
        .map((d) => new File(path.join(d.path, indexFileName)));

    if (!overwrite) {
      targetIndexes =
        targetIndexes.asyncExpand(_removeIfExists);
    }

    return targetIndexes
        .asyncExpand((f) => _generateIndex(f).asStream())
        .toList()
        .then((i) {_indexes = i; return _indexes;});
  }

  Future<File> _generateIndex(File idx) {
    print('Create index page: ${idx.path}');

    var filesFuture = idx.parent.list().toList();
    var outputFuture = idx.open(mode: FileMode.WRITE);

    return Future.wait([filesFuture, outputFuture])
        .then((List args) {
          List<File> files = args[0];
          RandomAccessFile output = args[1];
          return htmlWriter(output, baseDir, idx.parent, files)
              .then((_) => output.close());
        })
        .then((_) => idx);
  }

  Stream<Directory> get _dirs {
    var subs = baseDir.list(recursive: true)
      .where((e) => e is Directory)
      .where((d) => !_isInExcludes(d.path));
    var base = new Stream.fromIterable([baseDir]);

    return _mergeStream([base, subs]);
  }

  bool _isInExcludes(String p) {
    var relPath = path.split(path.relative(p, from: baseDir.path));
    return excludes.any((e) => relPath.any((rp) =>
        e.allMatches(rp).length == 0
    ));
  }

  Stream _mergeStream(Iterable<Stream> streams) {
    int openStreams = streams.length;
    StreamController c = new StreamController();
    streams.forEach((s) {
      s.listen(c.add)
        ..onError(c.addError)
        ..onDone((){
          openStreams--;
          if (openStreams == 0) c.close();
        });
    });
    return c.stream;
  }

  Stream<File> _removeIfNotExists(File file) =>
      _removeIf(file.exists(), file);

  Stream<File> _removeIfExists(File file) =>
      _removeIf(file.exists().then((b) => !b), file);

  Stream _removeIf(Future<bool> condition, element) =>
      condition
        .then((e) => e ? element : _NOTHING)
        .asStream()
        .where((i) => i != _NOTHING);

  static Future defaultHtmlWriter(RandomAccessFile output, Directory base, Directory target, List<FileSystemEntity> children) {
    var p = (target.path == base.path) ?
        '/' : path.relative(target.path, from: base.path);
    var title = 'Index of $p';

    List<Pattern> ignoreds =
        [r'^packages/$', r'^\.git/$', r'\.precompiled\.js$', r'\.part\.js$',
         r'^index\.html$'
         ].map((p) => new RegExp(p)).toList(growable: true);
    List<String> childNames = children
        .map((e) => path.basename(e.path) + ((e is Directory) ? '/' : ''))
        .where((n) => ignoreds.every((i) => i.allMatches(n).isEmpty))
        .toList(growable: false);

    var content = new StringBuffer()
      ..writeln('<!doctype html>')
      ..writeln('<meta charset="utf-8">')
      ..writeln('<title>$title</title>')
      ..writeln('<h1>$title</h1>');

    if (childNames.isEmpty) {
      content.writeln('<p>No contents</p>');
    } else {
      content
          ..writeln('<ul>')
          ..writeAll(
              childNames.map((f) => '<li><a href="$f">$f</a></li>'), '\n')
          ..writeln('</ul>');
    }
    return output.writeString(content.toString());
  }
}

typedef Future HtmlWriter(RandomAccessFile output, Directory base, Directory target, List<FileSystemEntity> children);
