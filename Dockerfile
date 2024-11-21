FROM gradle:7.5.1-jdk17 AS builder

WORKDIR /app

# Set Gradle options for better build performance
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Xmx4096m -Xms1024m"
ENV GRADLE_USER_HOME="/app/.gradle"

# Copy gradle configuration files first
COPY gradle gradle
COPY build.gradle settings.gradle gradle.properties ./
COPY buildSrc buildSrc

# Initial dependency resolution
RUN echo "Downloading initial dependencies..." && \
    gradle dependencies --no-daemon --info || exit 1

# Copy core modules first
COPY fineract-core fineract-core
COPY fineract-provider fineract-provider
RUN echo "Building core modules..." && \
    gradle :fineract-core:build :fineract-provider:build -x test --no-daemon --info || exit 1

# Copy remaining modules
COPY fineract-client fineract-client
COPY fineract-avro-schemas fineract-avro-schemas
COPY fineract-loan fineract-loan
COPY fineract-investor fineract-investor
COPY integration-tests integration-tests
COPY config config

# Final build
RUN echo "Performing final build..." && \
    gradle clean bootJar -x test --no-daemon --info --stacktrace || exit 1

# Final stage
FROM openjdk:17-slim

WORKDIR /app

# Copy the built artifact
COPY --from=builder /app/fineract-provider/build/libs/fineract-provider.jar ./app.jar

ENV JAVA_OPTS="-Xmx1G -Xms1G"
ENV FINERACT_NODE_ID=1

EXPOSE 8443

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
