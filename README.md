# CityVoice

## Backend Quality Gate

Requirements:

- Docker with Docker Compose support.
- Java 21 or newer available on `PATH`.
- Network access on first setup if Docker images or Maven dependencies have not been downloaded.

Run the backend QA suite from the repository root:

```bash
./qa/run-local-quality-gate.sh
```

The script starts the required `db` and `minio` Docker Compose services, waits for both health checks, and runs:

```bash
cd backend
./mvnw clean test
```

The clean Maven build is intentional because it avoids stale Lombok-generated output. The Docker services remain running after tests finish; stop them when no longer needed with:

```bash
docker compose stop db minio
```

If initial container startup needs longer than 90 seconds, set a longer health timeout:

```bash
QA_HEALTH_TIMEOUT_SECONDS=180 ./qa/run-local-quality-gate.sh
```
