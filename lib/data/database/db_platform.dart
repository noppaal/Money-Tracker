import 'db_platform_io.dart'
    if (dart.library.js_interop) 'db_platform_web.dart'
    if (dart.library.html) 'db_platform_web.dart' as platform;

void initPlatformDatabase() => platform.initPlatformDatabase();
