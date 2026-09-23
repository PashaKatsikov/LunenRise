# Lumen Rise

Нативная башня и отдельный слой запуска. Игра открывается только когда решатель выбирает исход «стол». WebView, оффлайн-экран и атрибуция живут в других каталогах и не вызывают игровую логику.

## Что подставить

Пока пусты ключ кампании и номер проекта, приложение сразу входит в башню и не ходит в сеть.

1. AppsFlyer dev key — константа `_campaignKey` в `tool/slip_press.dart`.
2. Номер Firebase-проекта (project number, не project id) — `_projectNumber` в том же файле.
3. Заменить `android/app/google-services.json` файлом из консоли Firebase. `package_name` должен быть `com.lumenrise.lumenrisegame`.
4. Пересобрать запечатанные константы тем же секретом, что на сервере:

```
$env:LR_RELAY_SECRET = '<секрет из /opt/relay/.env>'
dart run tool/slip_press.dart
```

Секрет в репозиторий не кладётся. Он уже записан на VPS в `/opt/relay/.env`.

5. Подпись release — `android/key.properties` и свой keystore. Debug-сборка подписывается debug-ключом.

Эндпоинт уже запечатан: `https://lumenrise.link/edge/sync`. Upstream релея: `https://lumenrise.online/config.php`.

## Дерево `lib/`

| Группа | Роль |
|---|---|
| `loom/` | экран загрузки, оффлайн, приглашение к разрешению |
| `fork/` | маршрут и решатель |
| `post/` | конверт, HTTP, проверка сети, разбор ответа |
| `trail/` | AppsFlyer и уведомления |
| `drawer/` | SharedPreferences, шифрованный карман, маскировка строк |
| `pane/` | WebView, вырез, клавиатура, User-Agent |
| `door/` | единственный вход в нативную игру |
| `game/`, `screens/`, `ui/` | сама башня |

Проводные значения маршрута: `open` (первый запуск), `sheet` (webview), `table` (игра).

## Конверт запроса

`POST https://lumenrise.link/edge/sync`

Тело JSON, схема **4**, поля не совпадают с другими приложениями:

| Поле | Смысл |
|---|---|
| `leaf` | число `4` |
| `salt` | standard Base64 **12** случайных байт, с padding `=` |
| `body` | standard Base64 шифртекста, с padding |
| `mac` | 24 hex-символа (младшие 12 байт HMAC) |

Алгоритм:

```
raw    = UTF-8( JSON без пробелов )
stream = блоки HMAC-SHA256(secret, "lr-ks-v1" || nonce || counter_le32)
         counter = 0, 1, 2, … пока не хватит длины raw
enc    = raw XOR stream
mac    = hex( HMAC-SHA256(secret, "lr-mac-v1" || nonce || enc)[:12] )
```

`secret` — байты UTF-8 строки `RELAY_SECRET`. User-Agent — как у обычного Chrome на Android. Заголовок `X-Forwarded-For` не отправлять.

### Ответ сервера

Релей возвращает тело `config.php` как есть, поэтому клиент читает родную
схему партнёрского конфига:

```json
{ "ok": true, "url": "https://example.com/room", "expires": 1790000000, "message": "" }
```

| Поле | Смысл |
|---|---|
| `ok` | `true`, если есть куда вести |
| `url` | URL для WebView; пустой или отсутствующий — отказ |
| `expires` | unix-секунды, до которых URL можно помнить; если нет — клиент ставит 10 суток |
| `message` | необязательная строка, на решение не влияет |

Любой ответ не `200` или без `ok: true` и непустого `url` — нативная игра или экран без сети, по правилам маршрута.

Проверочный вектор. Секрет `sample-secret`, открытый JSON `{"os":"Android"}`, nonce — 12 нулевых байт:

```json
{
  "leaf": 4,
  "salt": "AAAAAAAAAAAAAAAA",
  "body": "Qui18wBkJhNkDvVnaFJgPQ==",
  "mac": "e40916f09a0cf721a245b1e3"
}
```

После снятия конверта получается ровно `{"os":"Android"}`.

## Страницы

`https://lumenrise.link/privacy-policy` и `https://lumenrise.link/support` отдаёт nginx на VPS. Это не игровые ссылки из `Paths` (`lumenrise.online`).
