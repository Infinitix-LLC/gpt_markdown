import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gpt_markdown/markdown_component.dart';

/// It creates a markdown widget closed to each other.
class MdWidget extends StatelessWidget {
  const MdWidget(this.exp,
      {super.key,
      this.style,
      this.textDirection = TextDirection.ltr,
      this.onLinkTab,
      this.textAlign,
      this.textScaler,
      this.latexWorkaround,
      this.latexBuilder,
      this.followLinkColor = false});
  final String exp;
  final TextDirection textDirection;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextScaler? textScaler;
  final void Function(String url, String title)? onLinkTab;
  final String Function(String tex)? latexWorkaround;
  final Widget Function(BuildContext context, String tex)? latexBuilder;
  final bool followLinkColor;

  @override
  Widget build(BuildContext context) {
    List<InlineSpan> list = [];
    exp.trim().splitMapJoin(
      RegExp(r"\n\n+"),
      onMatch: (p0) {
        list.add(
          TextSpan(
            text: "\n\n\n\n",
            style: TextStyle(
              fontSize: 6,
              color: style?.color,
            ),
          ),
        );
        return "";
      },
      onNonMatch: (eachLn) {
        final RegExp table = RegExp(
          r"^(((\|[^\n\|]+\|)((([^\n\|]+\|)+)?))(\n(((\|[^\n\|]+\|)(([^\n\|]+\|)+)?)))+)$",
        );
        if (table.hasMatch(eachLn.trim())) {
          final List<Map<int, String>> value = eachLn
              .trim()
              .split('\n')
              .map<Map<int, String>>(
                (e) => e
                    .split('|')
                    .where((element) => element.isNotEmpty)
                    .toList()
                    .asMap(),
              )
              .toList();
          bool heading = RegExp(
            r"^\|.*?\|\n\|-[-\\ |]*?-\|$",
            multiLine: true,
          ).hasMatch(eachLn.trim());
          int maxCol = 0;
          for (final each in value) {
            if (maxCol < each.keys.length) {
              maxCol = each.keys.length;
            }
          }
          list.addAll(
            [
              TextSpan(
                text: "\n ",
                style: TextStyle(height: 0, fontSize: 0, color: style?.color),
              ),
              WidgetSpan(
                child: Table(
                  textDirection: textDirection,
                  defaultColumnWidth: CustomTableColumnWidth(),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder.all(
                    width: 1,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  children: value
                      .asMap()
                      .entries
                      .map<TableRow>(
                        (entry) => TableRow(
                          decoration: (heading)
                              ? BoxDecoration(
                                  color: (entry.key == 0)
                                      ? Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant
                                      : null,
                                )
                              : null,
                          children: List.generate(
                            maxCol,
                            (index) {
                              var e = entry.value;
                              String data = e[index] ?? "";
                              if (RegExp(r"^--+$").hasMatch(data.trim()) ||
                                  data.trim().isEmpty) {
                                return const SizedBox();
                              }

                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: MdWidget(
                                    (e[index] ?? "").trim(),
                                    textDirection: textDirection,
                                    onLinkTab: onLinkTab,
                                    style: style,
                                    latexWorkaround: latexWorkaround,
                                    latexBuilder: latexBuilder,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              TextSpan(
                text: "\n ",
                style: TextStyle(height: 0, fontSize: 0, color: style?.color),
              ),
            ],
          );
        } else {
          list.addAll(
            MarkdownComponent.generate(
              context,
              eachLn.replaceAllMapped(
                  RegExp(
                    r"\\\[(.*?)\\\]|(\\begin.*?\\end{.*?})",
                    multiLine: true,
                    dotAll: true,
                  ), (match) {
                //
                String body =
                    (match[1] ?? match[2])?.replaceAll("\n", " ") ?? "";
                return "\\[$body\\]";
              }),
              style,
              textDirection,
              onLinkTab,
              latexWorkaround,
              latexBuilder,
            ),
          );
        }
        return "";
      },
    );
    return Text.rich(
      TextSpan(
        children: list,
        style: style?.copyWith(),
      ),
      textDirection: textDirection,
      textScaler: textScaler,
      textAlign: textAlign,
    );
  }
}

class CustomTableColumnWidth extends TableColumnWidth {
  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    double width = 50;
    for (var each in cells) {
      each.layout(const BoxConstraints(), parentUsesSize: true);
      width = max(width, each.size.width);
    }
    return min(containerWidth, width);
  }

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return 50;
  }
}