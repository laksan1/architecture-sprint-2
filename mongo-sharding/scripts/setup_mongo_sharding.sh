#!/bin/bash

# Логирование
log_file="setup_mongo_sharding.log"
touch $log_file

log_message() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $1" | tee -a $log_file
}

log_message "Starting MongoDB Sharding setup..."

# Шаг 1: Инициализация конфигурационного сервера
log_message "Initiating config server..."
docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate({
    _id: 'config_server',
    configsvr: true,
    members: [{ _id: 0, host: 'configSrv:27017' }]
});
EOF
log_message "Config server initiated."
sleep 5  # Ожидание 5 секунд для завершения инициализации

# Шаг 2: Инициализация шардов
log_message "Initiating shard1..."
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate({
    _id: 'shard1',
    members: [{ _id: 0, host: 'shard1:27018' }]
});
EOF
log_message "Shard1 initiated."
sleep 5  # Ожидание 5 секунд

log_message "Initiating shard2..."
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
rs.initiate({
    _id: 'shard2',
    members: [{ _id: 0, host: 'shard2:27019' }]
});
EOF
log_message "Shard2 initiated."
sleep 5  # Ожидание 5 секунд

# Шаг 3: Настройка маршрутизатора
log_message "Configuring mongos router..."
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard('shard1/shard1:27018');
sh.addShard('shard2/shard2:27019');
EOF
log_message "Mongos router configured. Shards has been added"
sleep 5  # Ожидание 5 секунд

# Шаг 4: Включение шардинга в базе данных и заполнение
log_message "Data inserted into 'helloDoc'."
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
use somedb;
sh.enableSharding('somedb');
db.createCollection('helloDoc');
db.helloDoc.createIndex({ 'name': 'hashed' });
sh.shardCollection('somedb.helloDoc', { 'name': 'hashed' });

for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});
db.helloDoc.countDocuments();
EOF
log_message "Loading data is completed"
sleep 10 # Ожидание 10 секунд


# Шаг 5: Подсчет документов в Shard1
log_message "Counting documents in 'Shard1'..."
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
use somedb;
const count = db.helloDoc.countDocuments();
print('Total documents in Shard1:', count);
EOF
log_message "Document count in 'Shard1' completed."


# Шаг 6: Подсчет документов в Shard2
log_message "Counting documents in 'Shard2'..."
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
use somedb;
const count = db.helloDoc.countDocuments();
print('Total documents in Shard2:', count);
EOF
log_message "Document count in 'Shard2' completed."

log_message "MongoDB Sharding setup completed."
