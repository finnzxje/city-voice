#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"
HEALTH_TIMEOUT_SECONDS="${QA_HEALTH_TIMEOUT_SECONDS:-90}"
POLL_SECONDS=2

fail() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' was not found in PATH."
}

service_status() {
    local service="$1"
    local container_id

    container_id="$(docker compose -f "$COMPOSE_FILE" ps -q "$service")"
    if [[ -z "$container_id" ]]; then
        printf 'missing'
        return
    fi

    docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id"
}

print_service_diagnostics() {
    printf '\nDocker service status:\n' >&2
    docker compose -f "$COMPOSE_FILE" ps db minio >&2 || true
    printf '\nRecent Docker service logs:\n' >&2
    docker compose -f "$COMPOSE_FILE" logs --tail=50 db minio >&2 || true
}

wait_for_infrastructure() {
    local deadline=$((SECONDS + HEALTH_TIMEOUT_SECONDS))
    local db_status
    local minio_status

    while ((SECONDS < deadline)); do
        db_status="$(service_status db)"
        minio_status="$(service_status minio)"
        printf '\rWaiting for infrastructure: db=%-10s minio=%-10s' "$db_status" "$minio_status"

        if [[ "$db_status" == "healthy" && "$minio_status" == "healthy" ]]; then
            printf '\n'
            return
        fi

        if [[ "$db_status" == "unhealthy" || "$minio_status" == "unhealthy" ]]; then
            printf '\n' >&2
            print_service_diagnostics
            fail "A required Docker service became unhealthy."
        fi

        sleep "$POLL_SECONDS"
    done

    printf '\n' >&2
    print_service_diagnostics
    fail "Timed out after ${HEALTH_TIMEOUT_SECONDS}s waiting for db and minio to become healthy."
}

require_command docker
require_command java

docker compose version >/dev/null 2>&1 \
    || fail "Docker Compose is required. Install Docker Compose or enable the Docker Compose plugin."

JAVA_MAJOR="$(java -version 2>&1 | awk -F '[".]' '/version/ { print $2; exit }')"
if [[ ! "$JAVA_MAJOR" =~ ^[0-9]+$ ]] || ((JAVA_MAJOR < 21)); then
    fail "Java 21 or newer is required to run backend tests."
fi

[[ -x "$ROOT_DIR/backend/mvnw" ]] \
    || fail "Expected executable Maven wrapper at '$ROOT_DIR/backend/mvnw'."

printf 'Starting PostgreSQL/PostGIS and MinIO containers...\n'
docker compose -f "$COMPOSE_FILE" up -d db minio \
    || fail "Unable to start Docker services. Confirm the Docker daemon is running."

wait_for_infrastructure

printf 'Running backend Maven tests...\n'
(
    cd "$ROOT_DIR/backend"
    ./mvnw clean test
)

printf 'Local backend quality gate passed. Docker services remain running for reuse.\n'
