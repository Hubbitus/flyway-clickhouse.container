# Flyway container image with Clickhouse support

Unfortunately there are [several pull requests](https://kb.altinity.com/altinity-kb-setup-and-maintenance/schema-migration-tools/) to bring into [flyway](https://flywaydb.org/) support of [Clickhouse](https://clickhouse.com/), but most of them stalled, unfortunately.

This repository contains attempt to build it with latest [PR#3611](https://github.com/flyway/flyway/pull/3611).

## Automated builds

Please find images in https://hub.docker.com/r/hubbitus/flyway-clickhouse

## Example of run

Said you placed your migrations in directory `clickhouse/migrations`, and config file in `conf/flyway.conf` then you may run it like:

```shell
podman run --rm -it --name flyway \
    -v ./clickhouse/migrations:/flyway/sql:z 
    -v ./conf:/flyway/conf:ro,z \
    --network=host \
        docker.io/hubbitus/flyway-clickhouse:master \
            -user=default -password='' -url=jdbc:clickhouse://default@127.0.0.1:8123/datamart migrate
```

Off course, you may omit name, network mode or run it in kubernetes, as you wish.
