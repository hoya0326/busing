#!/bin/bash
(while true; do xattr -cr build 2>/dev/null; sleep 0.02; done) &
CLEANER_PID=$!
flutter run "$@"
kill $CLEANER_PID
