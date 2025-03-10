# Mongo-Sharding

## Описание

Этот проект автоматизирует настройку и запуск MongoDB с **_шардингом_** с использованием Docker Compose.

## Шаги установки

Все шаги настройки описаны в скрипте:

```shell
./scripts/setup_mongo_sharding.sh
```

## Запуск

### 1. Запускаем контейнеры Docker

```shell
docker compose up -d
```

### 2. Инициализация конфигурации и данных

```shell
./scripts/setup_mongo_sharding.sh
```

В скрипте предусмотрены логи для отслеживания выполнения каждого шага.

## Дополнительная информация

Полностью очистить данные можно с помощью:

```shell
docker volume prune -a
```

## Отчет

### 1. Запуск через команды в консоле

![Скриншот выполнения 1](./result_task_2.png)

### 2. Итоговый скриншот с количеством элементов в разных шардах

![Скриншот выполнения 2](./result_run_screenshot_2.png)
