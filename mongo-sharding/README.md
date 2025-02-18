# Mongo-Sharding

## Шаги

### Запуск

Запускаем docker compose с контейнерами

```shell
docker compose up -d
```

Запускаем скрипт для инициализации конфига и данных

```shell
./scripts/setup_mongo_sharding.sh
```

В скрипте присутствуют логи для каждого шага

### Дополнительная информация

Удаляем полностью контейнеры (помогла именно данная команда, когда использовал другие команды, была ошибка
`shard2/shard2:27019' because a local database 'somedb' exists in another shard1`)

```shell
docker system prune -a --volumes
```
