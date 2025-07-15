# version_controller

## Platform

- Android

## OTA-обновления

[Docs Google Android](https://source.android.com/docs/core/ota?hl=ru)

## Системные обновления без A/B

[Docs Google Android](https://source.android.com/docs/core/ota/nonab?hl=ru)

***Платформы для Enterprise: Microsoft Intune, MobileIron***

```text
Ваше приложение → Проверяет API → Скачивает APK → Устанавливает
          ↑
       Сервер (хранит APK + версии)
```

### Description

- Google Play Policy: Приложения из Google Play не могут использовать OTA (нарушение политики).
- Подпись APK: Все обновления должны быть подписаны тем же ключом, что и исходное приложение.
- Версия Android: На Android 8+ требуются дополнительные разрешения для доступа к файлам.
