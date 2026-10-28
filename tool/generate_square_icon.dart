import 'dart:io';
import 'package:image/image.dart';

void main() {
  final bytes = File('assets/images/logo.png').readAsBytesSync();
  final original = decodeImage(bytes)!;

  // 1. Buat square icon 1024x1024 untuk iOS dan Android legacy
  final iconSize = 1024;
  final squareIcon = Image(width: iconSize, height: iconSize);
  // Fill background white
  fill(squareIcon, color: ColorRgb8(255, 255, 255));

  // Scale logo agar muat dengan padding proporsional (lebar ~760px)
  final targetWidth = 760;
  final targetHeight = (original.height * (targetWidth / original.width)).round();
  final scaledLogo = copyResize(original, width: targetWidth, height: targetHeight, interpolation: Interpolation.cubic);

  final posX = (iconSize - targetWidth) ~/ 2;
  final posY = (iconSize - targetHeight) ~/ 2;

  compositeImage(squareIcon, scaledLogo, dstX: posX, dstY: posY);
  File('assets/images/app_icon.png').writeAsBytesSync(encodePng(squareIcon));
  print('Saved assets/images/app_icon.png (1024x1024)');

  // 2. Buat adaptive icon foreground (Android 8.0+)
  // Android adaptive icon memerlukan konten berada di dalam 66% safe zone (~670px)
  final fgIcon = Image(width: iconSize, height: iconSize, numChannels: 4);
  // Transparent background
  fill(fgIcon, color: ColorRgba8(0, 0, 0, 0));

  final fgTargetWidth = 620;
  final fgTargetHeight = (original.height * (fgTargetWidth / original.width)).round();
  final fgScaledLogo = copyResize(original, width: fgTargetWidth, height: fgTargetHeight, interpolation: Interpolation.cubic);

  final fgPosX = (iconSize - fgTargetWidth) ~/ 2;
  final fgPosY = (iconSize - fgTargetHeight) ~/ 2;

  compositeImage(fgIcon, fgScaledLogo, dstX: fgPosX, dstY: fgPosY);
  File('assets/images/app_icon_foreground.png').writeAsBytesSync(encodePng(fgIcon));
  print('Saved assets/images/app_icon_foreground.png (1024x1024)');
}
