FROM gradle:7.5.1-jdk17 AS builder

WORKDIR /app

# Set Gradle options for better build performance and network resilience
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Dorg.gradle.workers.max=4 -Xmx4096m -Xms1024m"
ENV GRADLE_USER_HOME="/app/.gradle"

# Copy gradle configuration files
COPY gradle gradle
COPY build.gradle settings.gradle gradle.properties ./
COPY buildSrc buildSrc

# Copy project modules
COPY fineract-provider fineract-provider
COPY fineract-client fineract-client
COPY fineract-avro-schemas fineract-avro-schemas
COPY fineract-core fineract-core
COPY fineract-loan fineract-loan
COPY fineract-investor fineract-investor
COPY integration-tests integration-tests
COPY config config

# Add retry mechanism for dependency downloads and build
RUN for i in {1..3}; do \
        echo "Attempt $i: Downloading dependencies..." && \
        (gradle clean dependencies --refresh-dependencies --no-daemon || \
        (echo "Attempt $i failed, waiting 15s..." && sleep 15 && false)) && break; \
    done && \
    echo "Building with Gradle..." && \
    (gradle clean bootJar -x test --no-daemon --stacktrace --info || \
    (echo "First build attempt failed, waiting 30s..." && \
     sleep 30 && \
     echo "Retrying build..." && \
     gradle clean bootJar -x test --no-daemon --stacktrace --info))

# Final stage
FROM openjdk:17-slim

WORKDIR /app

# Copy the built artifact
COPY --from=builder /app/fineract-provider/build/libs/fineract-provider.jar ./app.jar

ENV JAVA_OPTS="-Xmx1G -Xms1G"
ENV FINERACT_NODE_ID=1

EXPOSE 8443

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
