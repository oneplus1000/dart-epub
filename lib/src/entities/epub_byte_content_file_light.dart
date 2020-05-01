import 'dart:async';

import 'package:epub/src/ref_entities/epub_content_file_ref.dart';
import 'package:quiver/core.dart';

import 'epub_content_file.dart';

class EpubByteContentFileLight extends EpubContentFile {
  final EpubContentFileRef contentFileRef;
  EpubByteContentFileLight(this.contentFileRef);

  Future<List<int>> get Content async {
    return contentFileRef.readContentAsBytes();
  }

  @override
  int get hashCode =>
      hash3(FileName.hashCode, ContentMimeType.hashCode, ContentType.hashCode);

  bool operator ==(other) {
    var otherAs = other as EpubByteContentFileLight;
    if (otherAs == null) {
      return false;
    }
    return ContentMimeType == otherAs.ContentMimeType &&
        ContentType == otherAs.ContentType &&
        FileName == otherAs.FileName;
  }
}
