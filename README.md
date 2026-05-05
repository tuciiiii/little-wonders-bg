# Little Wonders BG / Summit Stories

Мобилно Flutter приложение за откриване, посещаване и споделяне на български природни и културно-исторически забележителности.

## Идея

Little Wonders BG насърчава потребителите да опознават България чрез интерактивна карта, туристически обекти, дневник на посещенията, система с точки, значки, нива, общност и класация.

## Основни функционалности

- Интерактивна карта с природни и културни забележителности
- Филтриране на обекти по категория
- Детайлен екран за всяко място
- GPS check-in при достигане на забележителност
- Добавяне на бележка и снимка чрез камера
- Дневник на посетените места
- Система с точки, нива и значки
- Профил с прогрес и последни приключения
- Общност с публикации, снимки, харесвания и коментари
- Класация на активните потребители

## Използвани технологии

- Flutter и Dart
- Riverpod за управление на състоянието
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Hive за локално съхранение
- Google Maps Flutter
- Geolocator и Permission Handler
- Image Picker
- Cached Network Image

## Данни

Обектите в приложението се зареждат от локален JSON файл: `assets/pois.json`.

## Снимки от приложението
###  Вход и регистрация
| Вход | Регистрация |
|------|------------|
| <img src="screenshots/login.png" width="200"> | <img src="screenshots/register.png" width="200"> |

---

###  Карта и откриване на места

| Карта | Избрана локация |
|------|-----------------|
| <img src="screenshots/map.png" width="200"> | <img src="screenshots/map_poi.png" width="200"> |

---

###  Детайли за място
<img src= "screenshots/poi_details.png" width="200">

---

###  Общност
<img src= "screenshots/feed.png" width="200">

---

###  Дневник на посещенията
<img src= "screenshots/journal.png" width="200">

---

###  Значки и постижения
<img src= "screenshots/badges.png" width="200">

---

###  Класация
<img src= "screenshots/leaderboard.png" width="200">

---

###  Профил
<img src= "screenshots/profile.png" width="200">


## Стартиране

```bash
flutter pub get
flutter run
