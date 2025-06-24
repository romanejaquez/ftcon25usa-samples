import 'package:rive_native/rive_text.dart';

// Anything less than ASCII 32 (space) we can consider to be an empty glyph.
// 0x2028 is a line separator without making a paragraph (like on web).
// https://stackoverflow.com/questions/3072152/what-is-unicode-character-2028-ls-line-separator-used-for
bool isWhiteSpace(int c) {
  return c <= 32 || c == 0x2028;
}

/// Stores the glyphId/Index representing the unicode point at i.
class GlyphLookup {
  final List<int> indices;

  GlyphLookup(this.indices);

  factory GlyphLookup.fromShape(TextShapeResult shape, int codeUnitCount) {
    var glyphIndices = List<int>.filled(codeUnitCount + 1, 0);
    // Build a mapping of codePoints to glyphs indices.
    int glyphIndex = 0;
    int lastTextIndex = 0;
    for (final paragraph in shape.paragraphs) {
      for (final run in paragraph.runs) {
        for (int i = 0; i < run.glyphCount; i++) {
          var textIndex = run.textIndexAt(i);
          for (int j = lastTextIndex; j < textIndex; j++) {
            glyphIndices[j] = glyphIndex - 1;
          }
          lastTextIndex = textIndex;
          glyphIndex++;
        }
      }
    }
    for (int i = lastTextIndex; i < codeUnitCount; i++) {
      glyphIndices[i] = glyphIndex - 1;
    }
    // Store a fake unreachable glyph at the end to allow selecting the last
    // one.
    glyphIndices[codeUnitCount] =
        codeUnitCount == 0 ? 0 : glyphIndices[codeUnitCount - 1] + 1;
    return GlyphLookup(glyphIndices);
  }

  /// How far this codePoint index is within the glyph.
  double advanceFactor(int index, bool inv) {
    if (index >= indices.length) {
      return 0;
    }
    var glyphIndex = indices[index];
    int start = index;
    while (start > 0) {
      if (indices[start - 1] != glyphIndex) {
        break;
      }
      start--;
    }
    int end = index;
    while (end < indices.length - 1) {
      if (indices[end + 1] != glyphIndex) {
        break;
      }
      end++;
    }

    var f = (index - start) / (end - start + 1);
    if (inv) {
      return 1.0 - f;
    }
    return f;
  }

  int count(int index) {
    var value = indices[index];
    int count = 1;
    // ignore: parameter_assignments
    while (++index < indices.length && indices[index] == value) {
      count++;
    }
    return count;
  }
}
