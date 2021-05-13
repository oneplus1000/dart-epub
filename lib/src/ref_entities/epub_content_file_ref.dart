import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
//import 'package:dart2_constant/convert.dart' as convert;
import 'package:epub/epub.dart';
import 'package:quiver/core.dart';

import '../entities/epub_content_type.dart';
import '../utils/zip_path_utils.dart';
import 'epub_book_ref.dart';

abstract class EpubContentFileRef {
  EpubBookRef epubBookRef;

  String FileName;

  EpubContentType ContentType;
  String ContentMimeType;
  EpubContentFileRef(EpubBookRef epubBookRef) {
    this.epubBookRef = epubBookRef;
  }

  @override
  int get hashCode =>
      hash3(FileName.hashCode, ContentMimeType.hashCode, ContentType.hashCode);

  bool operator ==(other) {
    return (other is EpubContentFileRef &&
        other.FileName == FileName &&
        other.ContentMimeType == ContentMimeType &&
        other.ContentType == ContentType);
  }

  ArchiveFile getContentFileEntry() {
    String contentFilePath =
        ZipPathUtils.combine(epubBookRef.Schema.ContentDirectoryPath, FileName);
    ArchiveFile contentFileEntry = epubBookRef.EpubArchive().files.firstWhere(
        (ArchiveFile x) => x.name == contentFilePath,
        orElse: () => null);
    if (contentFileEntry == null)
      throw new Exception(
          "EPUB parsing error: file ${contentFilePath} not found in archive.");
    return contentFileEntry;
  }

  List<int> getContentStream() {
    return openContentStream(getContentFileEntry());
  }

  List<int> openContentStream(ArchiveFile contentFileEntry) {
    List<int> contentStream = <int>[];
    if (contentFileEntry.content == null)
      throw new Exception(
          'Incorrect EPUB file: content file \"${FileName}\" specified in manifest is not found.');
    contentStream.addAll(contentFileEntry.content);
    return contentStream;
  }

  Future<List<int>> readContentAsBytes() async {
    ArchiveFile contentFileEntry = getContentFileEntry();
    var content = openContentStream(contentFileEntry);
    return content;
  }

  Future<String> readContentAsText({IBookDecrypt bookDecrypt}) async {
    List<int> contentStream = getContentStream();
    if (bookDecrypt == null) {
      String result = utf8.decode(contentStream);
      return result;
    }
    //print('contentStream:' + contentStream.toString());
    //var digest = sha1.convert(contentStream);
    //print('digest = $digest');
    Uint8List buff1 = Uint8List.fromList(contentStream);
    var buff2 = await bookDecrypt.decrypt(buff1);
    //var len = buff2.length;
    String result = utf8.decode(buff2);
    return result;
  }
}
