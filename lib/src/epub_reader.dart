import 'dart:async';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:epub/epub.dart';

import 'entities/epub_book.dart';
import 'entities/epub_byte_content_file.dart';
import 'entities/epub_chapter.dart';
import 'entities/epub_content.dart';
import 'entities/epub_content_file.dart';
import 'entities/epub_text_content_file.dart';
import 'readers/content_reader.dart';
import 'readers/schema_reader.dart';
import 'ref_entities/epub_book_ref.dart';
import 'ref_entities/epub_byte_content_file_ref.dart';
import 'ref_entities/epub_chapter_ref.dart';
import 'ref_entities/epub_content_file_ref.dart';
import 'ref_entities/epub_content_ref.dart';
import 'ref_entities/epub_text_content_file_ref.dart';
import 'schema/opf/epub_metadata_creator.dart';

abstract class IBookDecrypt {
  Future<Uint8List> decrypt(Uint8List input);
}

class EpubReader {
  /// Opens the book asynchronously without reading its content. Holds the handle to the EPUB file.
  static Future<EpubBookRef> openBook(List<int> bytes) async {
    Archive epubArchive = new ZipDecoder().decodeBytes(bytes);

    EpubBookRef bookRef = new EpubBookRef(epubArchive);
    bookRef.Schema = await SchemaReader.readSchema(epubArchive);
    bookRef.Title = bookRef.Schema.Package.Metadata.Titles
        .firstWhere((String name) => true, orElse: () => "");
    bookRef.AuthorList = bookRef.Schema.Package.Metadata.Creators
        .map((EpubMetadataCreator creator) => creator.Creator)
        .toList();
    bookRef.Author = bookRef.AuthorList.join(", ");
    bookRef.Content = await ContentReader.parseContentMap(bookRef);
    //bookRef.Schema.Package.Spine.Items[0].IdRef

    return bookRef;
  }

  /// Opens the book asynchronously and reads all of its content into the memory. Does not hold the handle to the EPUB file.
  static Future<EpubBook> readBook(
    List<int> bytes, {
    IBookDecrypt bookDecrypt,
  }) async {
    EpubBook result = new EpubBook();
    EpubBookRef epubBookRef = await openBook(bytes);
    result.Schema = epubBookRef.Schema;
    result.Title = epubBookRef.Title;
    result.AuthorList = epubBookRef.AuthorList;
    result.Author = epubBookRef.Author;
    result.Content = await readContent(
      epubBookRef.Content,
      bookDecrypt,
    );
    result.CoverImage = await epubBookRef.readCover();
    List<EpubChapterRef> chapterRefs = await epubBookRef.getChapters();
    result.Chapters = await readChapters(
      chapterRefs,
      bookDecrypt,
    );
    return result;
  }

  static Future<EpubContent> readContent(
    EpubContentRef contentRef,
    IBookDecrypt bookDecrypt,
  ) async {
    EpubContent result = new EpubContent();
    result.Html = await readTextContentFiles(
      contentRef.Html,
      bookDecrypt,
    );
    result.Css = await readTextContentFiles(
      contentRef.Css,
      null,
    ); //css ไม่เข้ารหัส
    result.Images = await readByteContentFiles(contentRef.Images);
    result.Fonts = await readByteContentFiles(contentRef.Fonts);
    result.AllFiles = new Map<String, EpubContentFile>();

    result.Html.forEach((String key, EpubTextContentFile value) {
      result.AllFiles[key] = value;
    });
    result.Css.forEach((String key, EpubTextContentFile value) {
      result.AllFiles[key] = value;
    });

    result.Images.forEach((String key, EpubByteContentFile value) {
      result.AllFiles[key] = value;
    });
    result.Fonts.forEach((String key, EpubByteContentFile value) {
      result.AllFiles[key] = value;
    });

    await Future.forEach(contentRef.AllFiles.keys, (key) async {
      if (!result.AllFiles.containsKey(key)) {
        result.AllFiles[key] =
            await readByteContentFile(contentRef.AllFiles[key]);
      }
    });

    return result;
  }

  static Future<Map<String, EpubTextContentFile>> readTextContentFiles(
    Map<String, EpubTextContentFileRef> textContentFileRefs,
    IBookDecrypt bookDecrypt,
  ) async {
    Map<String, EpubTextContentFile> result =
        new Map<String, EpubTextContentFile>();

    await Future.forEach(textContentFileRefs.keys, (key) async {
      EpubContentFileRef value = textContentFileRefs[key];
      bool isEncript = _isEncript(key, value.epubBookRef.Schema.Package);
      //print('----xxx->' + key + '  isEncript:' + isEncript.toString());
      EpubTextContentFile textContentFile = new EpubTextContentFile();
      textContentFile.FileName = value.FileName;
      textContentFile.ContentType = value.ContentType;
      textContentFile.ContentMimeType = value.ContentMimeType;
      textContentFile.Content = await value.readContentAsText(
        bookDecrypt: isEncript ? bookDecrypt : null,
      );
      result[key] = textContentFile;
    });
    return result;
  }

  static Future<Map<String, EpubByteContentFile>> readByteContentFiles(
      Map<String, EpubByteContentFileRef> byteContentFileRefs) async {
    Map<String, EpubByteContentFile> result =
        new Map<String, EpubByteContentFile>();
    await Future.forEach(byteContentFileRefs.keys, (key) async {
      result[key] = await readByteContentFile(byteContentFileRefs[key]);
    });
    return result;
  }

  static Future<EpubByteContentFile> readByteContentFile(
      EpubContentFileRef contentFileRef) async {
    EpubByteContentFile result = new EpubByteContentFile();

    result.FileName = contentFileRef.FileName;
    result.ContentType = contentFileRef.ContentType;
    result.ContentMimeType = contentFileRef.ContentMimeType;
    result.Content = await contentFileRef.readContentAsBytes();

    return result;
  }

  static Future<List<EpubChapter>> readChapters(
    List<EpubChapterRef> chapterRefs,
    IBookDecrypt bookDecrypt,
  ) async {
    List<EpubChapter> result = new List<EpubChapter>();
    await Future.forEach(chapterRefs, (EpubChapterRef chapterRef) async {
      EpubChapter chapter = new EpubChapter();
      chapter.Title = chapterRef.Title;
      chapter.ContentFileName = chapterRef.ContentFileName;
      chapter.Anchor = chapterRef.Anchor;
      chapter.HtmlContent = await chapterRef.readHtmlContent(
        bookDecrypt: bookDecrypt,
      );
      chapter.SubChapters = await readChapters(
        chapterRef.SubChapters,
        bookDecrypt,
      );
      result.add(chapter);
    });
    return result;
  }

  static bool _isEncript(String fileKey, EpubPackage pkg) {
    var manifestItems = pkg.Manifest.Items;
    var spinItems = pkg.Spine.Items;
    for (var manifestItem in manifestItems) {
      if (fileKey == Uri.decodeComponent(manifestItem.Href)) {
        for (var spinItem in spinItems) {
          //print(spinItem.IdRef + " == " + manifestItem.Id);
          if (spinItem.IdRef == manifestItem.Id) {
            return true;
          }
        }
        break;
      }
    }
    //}
    return false;
  }
}
