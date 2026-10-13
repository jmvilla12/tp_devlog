# Runtime-only image: the jar is built by the pipeline (stage 07), not inside Docker
FROM eclipse-temurin:25-jre

WORKDIR /app

# Run as a non-root user
RUN useradd --system --no-create-home appuser
USER appuser

COPY target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]