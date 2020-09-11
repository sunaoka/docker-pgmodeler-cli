# pgmodeler-cli Docker image

Run pgmodeler-cli without building or installing.

## Usage

```bash
docker run --rm -v $(pwd):/data sunaoka/pgmodeler-cli \
    --export-to-file \
    --input some.dbm \
    --output some.sql
```

## Usage (Overwriting Settings)

Copy the configuration file into the `$(pwd)/config` directory.

```bash
docker run --rm -v $(pwd):/data sunaoka/pgmodeler-cli \
                -v $(pwd)/config:/root/.config/pgmodeler \
    --export-to-file \
    --input some.dbm \
    --output some.sql
```

## Tags

Older versions are available, please see the docker hub for available tags
