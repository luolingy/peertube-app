import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A small, dependency-free Markdown renderer.
///
/// PeerTube video and channel descriptions are Markdown. Only the subset that
/// actually appears in them is supported: headings, bold/italic/strikethrough,
/// inline code, links, autolinks, bullet and ordered lists, blockquotes and
/// horizontal rules. Anything else degrades to plain text.
class MarkdownText extends StatelessWidget {
  const MarkdownText({
    super.key,
    required this.data,
    this.baseStyle,
    this.maxLines,
    this.linkColor,
    this.selectable = false,
  });

  final String data;
  final TextStyle? baseStyle;
  final int? maxLines;
  final Color? linkColor;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = baseStyle ??
        theme.textTheme.bodyMedium!.copyWith(height: 1.5, color: theme.colorScheme.onSurface);
    final effectiveLinkColor = linkColor ?? theme.colorScheme.primary;

    final blocks = _parseBlocks(data);
    final widgets = <Widget>[];

    for (final block in blocks) {
      widgets.add(_buildBlock(context, block, style, effectiveLinkColor));
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );

    if (maxLines == null) return column;
    return _LimitedLines(maxLines: maxLines!, child: column);
  }

  Widget _buildBlock(
    BuildContext context,
    _Block block,
    TextStyle style,
    Color linkColor,
  ) {
    switch (block.type) {
      case _BlockType.heading:
        final sizes = <double>[24, 21, 18, 16, 15, 14];
        final size = sizes[(block.level - 1).clamp(0, sizes.length - 1)];
        return Padding(
          padding: EdgeInsets.only(top: block.level == 1 ? 6 : 12, bottom: 6),
          child: Text.rich(
            TextSpan(
              children: _inlineSpans(block.text, style.copyWith(
                fontSize: size,
                fontWeight: FontWeight.w700,
              ), linkColor),
            ),
          ),
        );
      case _BlockType.bullet:
      case _BlockType.ordered:
        return Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: block.type == _BlockType.ordered ? 26 : 18,
                child: Text(
                  block.marker,
                  style: style.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
              ),
              Expanded(
                child: Text.rich(TextSpan(children: _inlineSpans(block.text, style, linkColor))),
              ),
            ],
          ),
        );
      case _BlockType.quote:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
          ),
          child: Text.rich(
            TextSpan(
              children: _inlineSpans(
                block.text,
                style.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.outline,
                ),
                linkColor,
              ),
            ),
          ),
        );
      case _BlockType.rule:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1),
        );
      case _BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text.rich(TextSpan(children: _inlineSpans(block.text, style, linkColor))),
        );
    }
  }

  List<InlineSpan> _inlineSpans(String text, TextStyle style, Color linkColor) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'(\*\*|__)(.+?)\1'      // bold
      r'|(\*|_)(.+?)\3'        // italic
      r'|~~(.+?)~~'            // strikethrough
      r'|`([^`]+?)`'           // inline code
      r'|\[([^\]]+)\]\(([^)\s]+)\)' // link
      r'|(https?://[^\s<>()]+)' // autolink
      r'|(@[A-Za-z0-9_.-]+(?:@[A-Za-z0-9.-]+)?)', // mention
    );

    var index = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      index = match.end;

      final value = match.group(0)!;
      if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(5) != null) {
        spans.add(TextSpan(
          text: match.group(5),
          style: const TextStyle(decoration: TextDecoration.lineThrough),
        ));
      } else if (match.group(6) != null) {
        spans.add(TextSpan(
          text: match.group(6),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: linkColor.withValues(alpha: 0.08),
          ),
        ));
      } else if (match.group(7) != null && match.group(8) != null) {
        spans.add(_linkSpan(match.group(7)!, match.group(8)!, linkColor));
      } else if (match.group(9) != null) {
        spans.add(_linkSpan(match.group(9)!, match.group(9)!, linkColor));
      } else {
        spans.add(TextSpan(
          text: value,
          style: TextStyle(color: linkColor, fontWeight: FontWeight.w500),
        ));
      }
    }

    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }
    if (spans.isEmpty) spans.add(const TextSpan(text: ''));
    return spans;
  }

  InlineSpan _linkSpan(String label, String url, Color linkColor) {
    return TextSpan(
      text: label,
      style: TextStyle(
        color: linkColor,
        decoration: TextDecoration.underline,
        decorationColor: linkColor.withValues(alpha: 0.6),
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () => _openUrl(url),
    );
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Clamps a column of blocks to a number of lines by using a shader mask free
/// approach: simply renders inside an overflow box.
class _LimitedLines extends StatelessWidget {
  const _LimitedLines({required this.maxLines, required this.child});

  final int maxLines;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxLines * 22.0,
      child: ClipRect(child: child),
    );
  }
}

enum _BlockType { paragraph, heading, bullet, ordered, quote, rule }

class _Block {
  _Block(this.type, this.text, {this.level = 0, this.marker = ''});

  final _BlockType type;
  final String text;
  final int level;
  final String marker;
}

List<_Block> _parseBlocks(String source) {
  final blocks = <_Block>[];
  final lines = source.replaceAll('\r\n', '\n').split('\n');

  final paragraph = <String>[];

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add(_Block(_BlockType.paragraph, paragraph.join('\n')));
    paragraph.clear();
  }

  for (final rawLine in lines) {
    final line = rawLine.trimRight();
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      flushParagraph();
      continue;
    }

    if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(trimmed)) {
      flushParagraph();
      blocks.add(_Block(_BlockType.rule, ''));
      continue;
    }

    final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
    if (heading != null) {
      flushParagraph();
      blocks.add(_Block(
        _BlockType.heading,
        heading.group(2)!,
        level: heading.group(1)!.length,
      ));
      continue;
    }

    final bullet = RegExp(r'^[-*+]\s+(.*)$').firstMatch(trimmed);
    if (bullet != null) {
      flushParagraph();
      blocks.add(_Block(_BlockType.bullet, bullet.group(1)!, marker: '•'));
      continue;
    }

    final ordered = RegExp(r'^(\d+)[.)]\s+(.*)$').firstMatch(trimmed);
    if (ordered != null) {
      flushParagraph();
      blocks.add(_Block(
        _BlockType.ordered,
        ordered.group(2)!,
        marker: '${ordered.group(1)}.',
      ));
      continue;
    }

    final quote = RegExp(r'^>\s?(.*)$').firstMatch(trimmed);
    if (quote != null) {
      flushParagraph();
      blocks.add(_Block(_BlockType.quote, quote.group(1)!));
      continue;
    }

    paragraph.add(trimmed);
  }

  flushParagraph();
  return blocks;
}
