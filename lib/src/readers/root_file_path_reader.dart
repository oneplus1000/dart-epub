import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
//import 'package:dart2_constant/convert.dart' as convert;
import 'package:collection/collection.dart' show IterableExtension;
import 'package:xml/xml.dart' as xml;
import 'package:xml/xml.dart';

class RootFilePathReader {
  static Future<String?> getRootFilePath(Archive epubArchive) async {
    const String EPUB_CONTAINER_FILE_PATH = "META-INF/container.xml";

    ArchiveFile? containerFileEntry = epubArchive.files.firstWhereOrNull(
        (ArchiveFile file) => file.name == EPUB_CONTAINER_FILE_PATH);
    if (containerFileEntry == null) {
      throw new Exception(
          "EPUB parsing error: ${EPUB_CONTAINER_FILE_PATH} file not found in archive.");
    }

    xml.XmlDocument containerDocument =
        xml.parse(utf8.decode(containerFileEntry.content));
    xml.XmlElement? packageElement = containerDocument
        .findAllElements("container",
            namespace: "urn:oasis:names:tc:opendocument:xmlns:container")
        .firstWhereOrNull((xml.XmlElement elem) => elem != null);
    if (packageElement == null) {
      throw new Exception("EPUB parsing error: Invalid epub container");
    }

    xml.XmlElement rootFileElement = packageElement.descendants
        .firstWhereOrNull((xml.XmlNode testElem) =>
            (testElem is xml.XmlElement) &&
            "rootfile" == testElem.name.local) as XmlElement;

    return rootFileElement.getAttribute("full-path");
  }
}
