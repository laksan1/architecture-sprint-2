#!/bin/bash

docker compose exec -T configSrv mongosh --port 27017 --quiet
rs.initiate({_id : 'config_server',configsvr:true,members: [{ _id : 0, host : 'configSrv:27017' }]});


docker compose exec -T shard1 mongosh --port 27018 --quiet
rs.initiate({_id : "shard1",members: [{ _id : 0, host : "shard1:27018" }]});


docker compose exec -T shard2 mongosh --port 27019 --quiet
rs.initiate({_id : "shard2",members: [{ _id : 0, host : "shard2:27019" }]});

docker compose exec -T mongos_router mongosh --port 27020 --quiet
sh.addShard("shard1/shard1:27018");
sh.addShard("shard2/shard2:27019");


docker compose exec -T mongos_router mongosh --port 27020 --quiet
use somedb;
sh.enableSharding("somedb");
db.createCollection("helloDoc")
db.helloDoc.createIndex({ "name": "hashed" });
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" });

for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});
db.helloDoc.countDocuments();

docker compose exec -T shard1 mongosh --port 27018 --quiet
use somedb;
db.helloDoc.countDocuments();

docker compose exec -T shard2 mongosh --port 27019 --quiet
use somedb;
db.helloDoc.countDocuments();