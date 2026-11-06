# pgmodeler-cli Docker image

Run pgmodeler-cli without building or installing.

The 2.0.0 image contains pgModeler Community. Database import and model diff
are exclusive to pgModeler Plus and are not available in this image. See the
[pgModeler 2.0.0 release notes](https://github.com/nullptrlabs/pgmodeler/releases/tag/v2.0.0)
for the differences between editions.

## Usage

```bash
docker run --rm -v $(pwd):/data sunaoka/pgmodeler-cli \
    --export-to-file \
    --input some.dbm \
    --output some.sql
```

## Language

Set `LANGUAGE` to choose a translation. For example, to show the help in
Japanese:

```bash
docker run --rm -e LANGUAGE=ja sunaoka/pgmodeler-cli --help
```

## Usage (Overwriting Settings)

Copy the default configuration into a local directory and edit the files there:

```bash
mkdir -p config
docker run --rm --entrypoint tar sunaoka/pgmodeler-cli \
    -C /usr/local/share/pgmodeler/conf -cf - . | tar -xf - -C config
```

Set `PGMODELER_CONF_PATH` to use that directory. The directory is mounted as
part of `/data`:

```bash
docker run --rm -v "$(pwd):/data" \
    -e PGMODELER_CONF_PATH=/data/config \
    sunaoka/pgmodeler-cli \
    --export-to-file \
    --input some.dbm \
    --output some.sql
```

## Tags

Older versions are available, please see the docker hub for available tags
