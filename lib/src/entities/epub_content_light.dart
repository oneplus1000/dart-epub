import 'package:epub/src/entities/epub_byte_content_file_light.dart';
import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_content_file.dart';
import 'epub_text_content_file.dart';

class EpubContentLight {
  Map<String, EpubTextContentFile?>? Html;
  Map<String, EpubTextContentFile?>? Css;
  Map<String, EpubByteContentFileLight>? Images;
  Map<String, EpubByteContentFileLight>? Fonts;
  Map<String, EpubContentFile?>? AllFiles;

  EpubContent() {
    Html = new Map<String, EpubTextContentFile>();
    Css = new Map<String, EpubTextContentFile>();
    Images = new Map<String, EpubByteContentFileLight>();
    Fonts = new Map<String, EpubByteContentFileLight>();
    AllFiles = new Map<String, EpubContentFile?>();
  }

  @override
  int get hashCode {
    var objects = []
      ..addAll(Html!.keys.map((key) => key.hashCode))
      ..addAll(Html!.values.map((value) => value.hashCode))
      ..addAll(Css!.keys.map((key) => key.hashCode))
      ..addAll(Css!.values.map((value) => value.hashCode))
      ..addAll(Images!.keys.map((key) => key.hashCode))
      ..addAll(Images!.values.map((value) => value.hashCode))
      ..addAll(Fonts!.keys.map((key) => key.hashCode))
      ..addAll(Fonts!.values.map((value) => value.hashCode))
      ..addAll(AllFiles!.keys.map((key) => key.hashCode))
      ..addAll(AllFiles!.values.map((value) => value.hashCode));

    return hashObjects(objects);
  }

  bool operator ==(other) {
    var otherAs = other as EpubContentLight;
    if (otherAs == null) {
      return false;
    }

    return collections.mapsEqual(Html, otherAs.Html) &&
        collections.mapsEqual(Css, otherAs.Css) &&
        collections.mapsEqual(Images, otherAs.Images) &&
        collections.mapsEqual(Fonts, otherAs.Fonts) &&
        collections.mapsEqual(AllFiles, otherAs.AllFiles);
  }
}
