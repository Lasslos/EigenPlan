import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_subject_color.freezed.dart';
part 'custom_subject_color.g.dart';

@freezed
abstract class CustomSubjectColor with _$CustomSubjectColor {
  const factory CustomSubjectColor(
    String courseKey,
    @ColorConverter() Color color,
    @ColorConverter() Color textColor,
  ) = _CustomSubjectColor;

  const CustomSubjectColor._();

  factory CustomSubjectColor.fromJson(Map<String, dynamic> json) =>
      _$CustomSubjectColorFromJson(json);

  static const CustomSubjectColor regularColor = CustomSubjectColor(
    '',
    Colors.lightGreen,
    Colors.white,
  );
  static final CustomSubjectColor examColor = CustomSubjectColor(
    '',
    Colors.red[900]!,
    Colors.white,
  );
  static const CustomSubjectColor irregularColor = CustomSubjectColor(
    '',
    Colors.orange,
    Colors.white,
  );
  static const CustomSubjectColor cancelledColor = CustomSubjectColor(
    '',
    Colors.red,
    Colors.white,
  );
  static const CustomSubjectColor emptyColor = CustomSubjectColor(
    '',
    Colors.grey,
    Colors.black,
  );
}

class ColorConverter extends JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) {
    return Color(json);
  }

  @override
  int toJson(Color object) {
    //
    return object.toARGB32();
  }
}
