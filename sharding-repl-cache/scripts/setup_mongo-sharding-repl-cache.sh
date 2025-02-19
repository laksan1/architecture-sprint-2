#!/bin/bash

# Логирование
log_file="setup_mongo-sharding-repl-cache.log"
touch $log_file

log_message() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $1" | tee -a $log_file
}

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

# Шаг 2: Инициализация 1 шарда с именем shard1-replica-set
log_message "Initiating shard1 (shard1-replica-set) ..."
docker compose exec -T shard1_1 mongosh --port 27018 --quiet <<EOF
rs.initiate({
    _id : "shard1-replica-set",
    members: [
        { _id : 0, host : "shard1_1:27018" },
        { _id : 1, host : "shard1_2:27019" },
        { _id : 2, host : "shard1_3:27020" }
    ]
});
EOF
log_message "Shard1 initiated (shard1-replica-set)."
sleep 5  # Ожидание 5 секунд

# Шаг 3: Инициализация 2 шарда с именем shard2-replica-set
log_message "Initiating shard2 (shard2-replica-set) ..."
docker compose exec -T shard2_1 mongosh --port 27021 --quiet <<EOF
rs.initiate({
    _id : "shard2-replica-set",
    members: [
        { _id : 0, host : "shard2_1:27021" },
        { _id : 1, host : "shard2_2:27022" },
        { _id : 2, host : "shard2_3:27023" }
    ]
});
EOF
log_message "Shard2 initiated (shard2-replica-set)."
sleep 5  # Ожидание 5 секунд

# Шаг 4: Добавление шардов в роутер
log_message "Configuring mongos router..."
docker compose exec -T mongos_router mongosh --port 27024 --quiet <<EOF
sh.addShard("shard1-replica-set/shard1_1:27018,shard1_2:27019,shard1_3:27020");
sh.addShard("shard2-replica-set/shard2_1:27021,shard2_2:27022,shard2_3:27023");
EOF
log_message "Mongos router configured. Shards has been added"
sleep 5  # Ожидание 5 секунд

# Шаг 5: Включение шардинга в базе данных и заполнение
log_message "Data inserted into 'helloDoc'."
docker compose exec -T mongos_router mongosh --port 27024 --quiet <<EOF
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

# Шаг 6: Подсчет документов в shard1_1
log_message "Counting documents in 'shard1_1'..."
docker compose exec -T shard1_1 mongosh --port 27018 --quiet <<EOF
use somedb;
const count = db.helloDoc.countDocuments();
print('Total documents in shard1_1:', count);
EOF
log_message "Document count in 'shard1_1' completed."

# Шаг 7: Подсчет документов в shard1_2
log_message "Counting documents in 'shard1_2'..."
docker compose exec -T shard1_2 mongosh --port 27019 --quiet <<EOF
use somedb;
const count = db.helloDoc.countDocuments();
print('Total documents in shard1_2:', count);
EOF
log_message "Document count in 'shard1_2' completed."

# Шаг 8: Подсчет документов в shard1_3
log_message "Counting documents in 'shard1_3'..."
docker compose exec -T shard1_3 mongosh --port 27020 --quiet <<EOF
use somedb;
const count = db.helloDoc.countDocuments();
print('Total documents in shard1_3:', count);
EOF
log_message "Document count in 'shard1_3' completed."

# Шаг 9: Подсчет документов в shard2_1
log_message "Counting documents in 'shard2_1'..."
docker compose exec -T shard2_1 mongosh --port 27021 --quiet <<EOF
use somedb;
const count = db.helloDoc.countDocuments();
print('Total documents in shard2_1:', count);
EOF
log_message "Document count in 'shard2_1' completed."

# Шаг 10: Подсчет документов в shard2_2
log_message "Counting documents in 'shard2_2'..."
docker compose exec -T shard2_2 mongosh --port 27022 --quiet <<EOF
use somedb;
const count = db.helloDoc.countDocuments();
print('Total documents in shard2_2:', count);
EOF
log_message "Document count in 'shard2_2' completed."

# Шаг 11: Подсчет документов в shard2_3
log_message "Counting documents in 'shard2_3'..."
docker compose exec -T shard2_3 mongosh --port 27023 --quiet <<EOF
use somedb;
const count = db.helloDoc.countDocuments();
print('Total documents in shard2_3:', count);
EOF
log_message "Document count in 'shard2_3' completed."