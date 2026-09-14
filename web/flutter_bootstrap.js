{{flutter_js}}
{{flutter_build_config}}
// A single offline worker is registered by index.html after the build.
// Do not register Flutter's legacy worker for the same scope.
_flutter.loader.load({config: {canvasKitBaseUrl: 'canvaskit/'}});
