export 'platform_image_save_stub.dart'
    if (dart.library.html) 'platform_image_save_web.dart'
    if (dart.library.io) 'platform_image_save_io.dart';
