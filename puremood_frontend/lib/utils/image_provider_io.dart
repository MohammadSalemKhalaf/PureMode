import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider buildLocalImageProvider(String path) {
  return FileImage(File(path));
}
