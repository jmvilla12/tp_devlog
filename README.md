# tp_devlog

A CI/CD pipeline written from scratch in Bash for a small Spring Boot app. It doesn't use Jenkins or GitLab CI: each stage is a plain shell script, and an orchestrator runs them in order and logs everything.

Made for the DEVLOG course (Conception et Production Logiciel) at IMT Nord Europe.

## Requirements

- Java 25
- Docker (Docker Desktop on Windows)
- Bash and curl (Git Bash is enough on Windows)

You don't need Maven installed. The scripts use the Maven wrapper (`./mvnw`), so everyone builds with the same version.

## Running the pipeline

```bash
bash ci/pipeline.sh
```

You can call it from any directory, the script moves to the project root by itself.

Each run writes its own log to `ci/logs/pipeline_<date>_<time>.log`. The exit code is 0 when every stage passes. Otherwise it's the exit code of the stage that failed.

When the pipeline succeeds, the app runs in a container called `tp_devlog-app`:

- http://localhost:8080/api/hello?name=IMT
- http://localhost:8080/actuator/health

## Stages

| Order | Script | What it does |
|---|---|---|
| 1 | `01_validate.sh` | `mvn clean validate`, checks the pom.xml |
| 2 | `05_lint.sh` | Checkstyle, with the rules from `checkstyle.xml` |
| 3 | `02_dependencies.sh` | Resolves dependencies and prints the tree |
| 4 | `03_compile.sh` | Compiles the sources |
| 5 | `04_test.sh` | Runs the unit tests (JaCoCo records coverage here) |
| 6 | `06_coverage.sh` | Coverage report, fails below 80% line coverage |
| 7 | `07_package.sh` | Builds the jar |
| 8 | `08_deploy.sh` | Builds the Docker image, swaps the container, waits for the health check |
| - | `09_rollback.sh` | Only runs when stage 8 fails |

Lint runs second even though its file is numbered 05. It's quick and works on source code, so if the style is broken there's no reason to wait for the tests to find out. The real order comes from the `SCRIPTS` array in `ci/pipeline.sh`, not from the file names.

Linting and coverage are the two extra (R&D) stages.

## Deployment and rollback

Every deploy builds a new image tagged `<commit>-<timestamp>`, like `tp_devlog:74e1e02-20261013143256`. The commit says which code is inside. The timestamp keeps tags unique, so a rebuild can't overwrite the image you might need to go back to.

Once the container starts, the deploy stage polls `/actuator/health` for up to 60 seconds. If it answers `UP`, the image name goes into `ci/state/last_successful_image`. If it doesn't, the stage prints the container's last logs and fails. The orchestrator then calls the rollback script, which starts the last good image again. The pipeline still ends as failed, because the new version never went live.

To watch a rollback happen, add `server.port=9090` to `src/main/resources/application.properties` and run the pipeline. The tests still pass since they don't open a port, but the container listens on the wrong one, the health check times out and the previous version comes back. Undo it with `git restore src/main/resources/application.properties`.

Rollback needs at least one earlier successful deploy. On the very first run there's nothing to go back to, so it just removes the broken container.

## Layout

```
ci/
  pipeline.sh      orchestrator
  scripts/         one script per stage
  lib/common.sh    settings and health check shared by deploy and rollback
  logs/            pipeline logs (not versioned)
  state/           last good image (not versioned)
checkstyle.xml     lint rules
Dockerfile         runtime image (Java 25 JRE, non-root user)
```
