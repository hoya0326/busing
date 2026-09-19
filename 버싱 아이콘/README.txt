앱 아이콘 세트 — kmagpie.com/tools/app-icon/

[안드로이드]
android/res/ 안의 폴더를 app/src/main/res/ 에 그대로 덮어쓰세요.
적응형 아이콘을 쓰신다면 mipmap-anydpi-v26/ 도 함께 복사해야 합니다.
적응형 전경 레이어에는 세이프존(66/108)이 이미 적용되어 있습니다.
안드로이드 13+ 테마 아이콘을 쓰려면 단색 실루엣 drawable을 직접 만들어
ic_launcher.xml 에 <monochrome> 줄을 추가하세요.

[Play 스토어]
android/playstore/ic_launcher-512.png 를 스토어 등록정보에 올리세요.
모서리와 그림자는 직접 넣지 마세요. Play가 자체 마스크와 그림자를 입힙니다.

[iOS]
ios/AppIcon.appiconset 폴더를 Assets.xcassets 안의 같은 이름 폴더와 교체하세요.
Xcode 14 이상이면 1024px 한 장만 넣어도 나머지는 빌드 시 생성됩니다.

[웹]
web/ 안의 파일을 사이트 루트에 올리고 head-snippet.html 내용을 <head>에 넣으세요.
