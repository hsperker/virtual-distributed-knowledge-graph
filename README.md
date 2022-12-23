# virtual-distributed-knowledge-graph

## Currently Open Topics

- [ ] When run for the first time an empty Azure Container Registry is created but bicep tries to deploy container apps e.g. Trino from this acr. \
  *Workaround:* Let the first infra deploy fail, build and publish container, rerun infa deployment
- [ ] The PostgreSQL database is created empty but Trino currently expects an employees_database. \
  *Workaround:* After the initial deployment of the database geht required dummy data from https://github.com/h8/employees-database and import it into the database.
- [ ] The PostgreSQL server firewall currently allows access from everywhere (0.0.0.0 - 255.255.255.255). This currently allows Trino workers and local hosts to access the database.

## Trino

### Configuration

Trino is configured by the following means:

- *Templates* under `trino/template/` \
  Here you'll find the properties template common to all Trino nodes (trino.node.properties.template), the properties template for the coordinator (coordinator.config.properties) as well as the properties template for the worker (worker.config.properties.template).
- *Conncetors* under `trino/template/catalog` \
  Here you'll find the configuration for the different connectors configured for the cluster. \
  Each connector will have its own properties template like the postgresql.properties.template.
- *setup.sh* under `trino` \
  This script is executed by the container upon deployment, consumes environment variables and uses those to substitute template variables and to copy the template files into the proper location for Trino to use.
  The Templates use the *${VARIABLE}* pattern which is exchanged to proper values via the `envsubst` command.




### Preparing The Custom Trino Image

For this documentation it is assumed that your container registry can be found under `vdkg01pocacr.azurecr.io`. \
If that's not the case please change all the references to the correct host.

#### Building 
In the `trino` folder execute the following command to build the custom Trino image manually.

```bash
$ docker build --platform=linux/amd64 -t vdkg01pocacr.azurecr.io/trino:$(date +"%Y-%m-%d_%H-%M-%S") .
```

This will create an image like the following `vdkg01pocacr.azurecr.io/trino:2022-12-22_15-59-08` with the build timestamp at the end.

#### Publishing

To publish the custom Trino to the container registry execute the following command.

You might need to login to the registry at first via `docker login vdkg01pocacr.azurecr.io`

```bash
$ docker push vdkg01pocacr.azurecr.io/trino:2022-12-22_15-59-08
```

## Infrastructure

### Deployment

Required parameters:

- *trinoImage* the custom Trino image in the container registry to deploy
- *postGresAdministratorLogin* the PostgreSQL admin username
- *postGresAdministratorLoginPassword* the PostgreSQL admin password

```bash
$ az deployment sub create --location westeurope \
    --template-file ./main.bicep \
    --parameters \
        @./parameters.dev.json \
        trinoImage='vdkg01pocacr.azurecr.io/trino:2022-12-22_15-59-08' \
        postGresAdministratorLogin='foobaruser' \
        postGresAdministratorLoginPassword='ccb86...f1fff'
```