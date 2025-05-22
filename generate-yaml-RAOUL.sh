#!/bin/bash

OUTPUT_FILE=".gitlab-ci.yml"

if [ -f "$OUTPUT_FILE" ]; then
  echo "El archivo $OUTPUT_FILE ya existe, generando copia de seguridad..."
  cp "$OUTPUT_FILE" "$OUTPUT_FILE.bak"
fi

# Escribir encabezado del archivo
cat > "$OUTPUT_FILE" <<EOF
stages:
  - check_base
  - build

image: docker:latest

services:
  - docker:dind

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: ""

before_script:
  - echo "\$CI_JOB_TOKEN" | docker login -u gitlab-ci-token --password-stdin "\$CI_REGISTRY"

cache:
  key: digest-cache
  paths:
    - .ci_digests/

EOF

# Detectar servicios (carpetas con Dockerfile)
services=()
for dir in */; do
  if [ -f "$dir/Dockerfile" ]; then
    service=${dir%/}
    services+=("$service")
  fi
done

# Buscar y extraer dependencias
declare -A deps

for service in "${services[@]}"; do
  from_image=$(grep -i '^FROM' "$service/Dockerfile" | head -n 1 | awk '{print $2}')
  deps_list=()
  for other in "${services[@]}"; do
    lower_other=$(echo "$other" | tr '[:upper:]' '[:lower:]')
    if [[ "$from_image" == *"/$lower_other"* ]]; then
      deps_list+=("$other")
    fi
  done
  deps[$service]="${deps_list[*]}"
done

# Generar jobs para check_base
for service in "${services[@]}"; do
  lower_service=$(echo "$service" | tr '[:upper:]' '[:lower:]')

  cat >> "$OUTPUT_FILE" <<EOF
check_base_$lower_service:
  stage: check_base
  script:
    - echo "Comprobando cambios en la imagen base para $lower_service"
    - docker pull \$CI_REGISTRY_IMAGE/$lower_service:latest || true
    - docker inspect --format='{{index .RepoDigests 0}}' \$CI_REGISTRY_IMAGE/$lower_service:latest > base_digest_$lower_service.txt || echo "no-digest" > base_digest_$lower_service.txt
    - mkdir -p .ci_digests
    - if [ -f .ci_digests/base_digest_$lower_service.txt ]; then
          diff base_digest_$lower_service.txt .ci_digests/base_digest_$lower_service.txt || echo "digest_changed" > changed_$lower_service.flag;
      else
          echo "digest_changed" > changed_$lower_service.flag;
      fi

    - cp base_digest_$lower_service.txt .ci_digests/base_digest_$lower_service.txt
  artifacts:
    paths:
      - base_digest_$lower_service.txt
      - changed_$lower_service.flag
      - .ci_digests/base_digest_$lower_service.txt
    expire_in: 1 week
  rules:
    - changes:
        - "$service/**/*"
    - when: always

EOF
done

# Generar jobs de build
for service in "${services[@]}"; do
  lower_service=$(echo "$service" | tr '[:upper:]' '[:lower:]')

  # needs
  needs_jobs=("check_base_$lower_service")
  if [[ -n "${deps[$service]}" ]]; then
    for dep in ${deps[$service]}; do
      dep_lower=$(echo "$dep" | tr '[:upper:]' '[:lower:]')
      needs_jobs+=("check_base_$dep_lower")
      needs_jobs+=("$dep_lower")
    done
  fi

  # changes list
  changes_list=("$service")
  if [[ -n "${deps[$service]}" ]]; then
    for dep in ${deps[$service]}; do
      changes_list+=("$dep")
    done
  fi

  # escribir job
  echo "$lower_service:" >> "$OUTPUT_FILE"
  echo "  stage: build" >> "$OUTPUT_FILE"
  echo "  needs:" >> "$OUTPUT_FILE"
  for n in "${needs_jobs[@]}"; do
    if [[ "$n" == check_base_* ]]; then
      echo "    - job: $n" >> "$OUTPUT_FILE"
    else
      echo "    - job: $n" >> "$OUTPUT_FILE"
      echo "      optional: true" >> "$OUTPUT_FILE"
    fi
  done

  echo "  rules:" >> "$OUTPUT_FILE"
  echo "    - changes:" >> "$OUTPUT_FILE"
  for path in "${changes_list[@]}"; do
    echo "      - \"$path/**/*\"" >> "$OUTPUT_FILE"
  done
  echo "    - exists:" >> "$OUTPUT_FILE"
  echo "        - \"changed_$lower_service.flag\"" >> "$OUTPUT_FILE"
  echo "    - if: '\$CI_PIPELINE_SOURCE == \"schedule\"'" >> "$OUTPUT_FILE"
  echo "      when: always" >> "$OUTPUT_FILE"
  echo "    - when: never" >> "$OUTPUT_FILE"

  cat >> "$OUTPUT_FILE" <<EOF
  script:
    - docker build -t \$CI_REGISTRY_IMAGE/$lower_service:latest ./$service
    - docker push \$CI_REGISTRY_IMAGE/$lower_service:latest

EOF

done

echo "Archivo $OUTPUT_FILE generado correctamente."
