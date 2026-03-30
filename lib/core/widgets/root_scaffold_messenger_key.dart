import 'package:flutter/material.dart';

/// Attached to [MaterialApp.scaffoldMessengerKey] — also used to find [Overlay] for top banners.
final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>(debugLabel: 'globalSnackbar');
