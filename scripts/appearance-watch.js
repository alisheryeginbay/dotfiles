#!/usr/bin/osascript -l JavaScript
// Runs the given command each time macOS switches light/dark mode.
// Usage: osascript -l JavaScript appearance-watch.js <command> [args...]
//
// Watches the AppleInterfaceStyle default directly. The
// AppleInterfaceThemeChangedNotification broadcast isn't delivered to
// background processes like this one, but defaults changes are.
ObjC.import("Foundation");

function run(argv) {
  if (argv.length === 0) throw new Error("usage: appearance-watch.js <command> [args...]");

  ObjC.registerSubclass({
    name: "AppearanceObserver",
    methods: {
      "observeValueForKeyPath:ofObject:change:context:": {
        types: ["void", ["id", "id", "id", "void *"]],
        implementation: function () {
          const task = $.NSTask.alloc.init;
          task.executableURL = $.NSURL.fileURLWithPath(argv[0]);
          task.arguments = $(argv.slice(1));
          task.launchAndReturnError(null);
        },
      },
    },
  });

  $.NSUserDefaults.standardUserDefaults.addObserverForKeyPathOptionsContext(
    $.AppearanceObserver.alloc.init,
    "AppleInterfaceStyle",
    0,
    null
  );

  $.NSRunLoop.currentRunLoop.run;
}
