import 'package:epub/src/entities/epub_content_light.dart';
import 'package:image/image.dart';
import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_chapter.dart';
import 'epub_schema.dart';

class EpubBookLight {
  String Title;
  String Author;
  List<String> AuthorList;
  EpubSchema Schema;
  EpubContentLight Content;
  Image CoverImage;
  List<EpubChapter> Chapters;

  @override
  int get hashCode => hashObjects([
        Title.hashCode,
        Author.hashCode,
        AuthorList.hashCode,
        Schema.hashCode,
        Content.hashCode,
        CoverImage.hashCode,
        Chapters.hashCode
      ]);

  bool operator ==(other) {
    var otherAs = other as EpubBookLight;
    if (otherAs == null) {
      return false;
    }

    return Title == otherAs.Title &&
        Author == otherAs.Author &&
        collections.listsEqual(AuthorList, otherAs.AuthorList) &&
        Schema == otherAs.Schema &&
        Content == otherAs.Content &&
        collections.listsEqual(
            CoverImage.getBytes(), otherAs.CoverImage.getBytes()) &&
        collections.listsEqual(Chapters, otherAs.Chapters);
  }
}
