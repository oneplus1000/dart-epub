import 'package:quiver/collection.dart' as collections;
import 'package:quiver/core.dart';

import 'epub_guide_reference.dart';

class EpubGuide {
  List<EpubGuideReference>? Items;

  EpubGuide() {
    Items = [];
  }

  @override
  int get hashCode {
    var objects = [];
    objects.addAll(Items!.map((item) => item.hashCode));
    return hashObjects(objects);
  }

  bool operator ==(other) {
    var otherAs = other as EpubGuide;
    if (otherAs == null) {
      return false;
    }

    return collections.listsEqual(Items, otherAs.Items);
  }
}
