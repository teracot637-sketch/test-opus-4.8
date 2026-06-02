# test-opus-4.8

Android-приложение на Flutter.

## Что делает
- При запуске по центру экрана крупная выделенная надпись «Привет лох».
- Тап по экрану — загружаются новые случайные аниме-обои.
- Цвет текста подбирается автоматически по яркости картинки в центре.
- Вёрстка адаптивная под любые размеры экрана.

## Источник обоев
waifu.pics — `https://api.waifu.pics/sfw/<category>`.

## Сборка APK через Codemagic
Настроено в `codemagic.yaml` (workflow `android-build`):
1. Подключить репозиторий в Codemagic.
2. Запустить workflow `android-build`.
3. APK будет в артефактах: `build/app/outputs/flutter-apk/*.apk`.

## Локально
```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
