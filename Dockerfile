FROM gradle:7.5.1-jdk17 AS builder

WORKDIR /app

# Set basic Gradle options
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false"
ENV GRADLE_USER_HOME="/app/.gradle"

# Create init.gradle with repository configurations
RUN echo "allprojects {" > /root/.gradle/init.gradle && \
    echo "    repositories {" >> /root/.gradle/init.gradle && \
    echo "        mavenCentral()" >> /root/.gradle/init.gradle && \
    echo "        gradlePluginPortal()" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://jfrog.fineract.dev/artifactory/libs-snapshot-local' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://jfrog.fineract.dev/artifactory/libs-release-local' }" >> /root/.gradle/init.gradle && \
    echo "    }" >> /root/.gradle/init.gradle && \
    echo "}" >> /root/.gradle/init.gradle

# Copy only essential files first
COPY gradle gradle
COPY build.gradle settings.gradle gradle.properties ./
COPY buildSrc buildSrc

# Copy all source files
COPY fineract-provider fineract-provider
COPY fineract-client fineract-client
COPY fineract-avro-schemas fineract-avro-schemas
COPY fineract-core fineract-core
COPY fineract-loan fineract-loan
COPY fineract-investor fineract-investor
COPY integration-tests integration-tests
COPY config config

# Build with basic settings
RUN gradle clean bootJar -x test --no-daemon --info \
    -Dorg.gradle.jvmargs="-Xmx4g -Xms512m" \
    -Dorg.gradle.parallel=false

# Final stage
FROM openjdk:17-slim

WORKDIR /app

# Copy the built artifact
COPY --from=builder /app/fineract-provider/build/libs/fineract-provider.jar ./app.jar

ENV JAVA_OPTS="-Xmx1G -Xms1G"
ENV FINERACT_NODE_ID=1

EXPOSE 8443

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
