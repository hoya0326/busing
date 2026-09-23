#!/bin/bash
(while true; do xattr -cr build/ios 2>/dev/null; sleep 0.03; done) &
CLEANER_PID=$!
flutter run "$@"
kill $CLEANER_PID
