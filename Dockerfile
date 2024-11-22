FROM eclipse-temurin:17-jdk-focal AS builder

WORKDIR /app

# Install curl for downloading dependencies
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Copy gradle files first
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle gradle.properties ./
COPY buildSrc buildSrc

# Make gradlew executable
RUN chmod +x gradlew

# Create init.gradle with repository configurations
RUN mkdir -p /root/.gradle && \
    echo "allprojects {" > /root/.gradle/init.gradle && \
    echo "    repositories {" >> /root/.gradle/init.gradle && \
    echo "        mavenCentral()" >> /root/.gradle/init.gradle && \
    echo "        gradlePluginPortal()" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://repo1.maven.org/maven2' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://jcenter.bintray.com' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://jfrog.fineract.dev/artifactory/libs-snapshot-local' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://jfrog.fineract.dev/artifactory/libs-release-local' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://packages.confluent.io/maven/' }" >> /root/.gradle/init.gradle && \
    echo "    }" >> /root/.gradle/init.gradle && \
    echo "}" >> /root/.gradle/init.gradle

# Create required directories
RUN mkdir -p custom/docker

# Download dependencies first
RUN ./gradlew dependencies --no-daemon --refresh-dependencies || true

# Copy source files
COPY fineract-provider fineract-provider
COPY fineract-client fineract-client
COPY fineract-avro-schemas fineract-avro-schemas
COPY fineract-core fineract-core
COPY fineract-loan fineract-loan
COPY fineract-investor fineract-investor
COPY integration-tests integration-tests
COPY config config
COPY custom custom

# Build with specific settings
RUN ./gradlew clean bootJar \
    --no-daemon \
    --stacktrace \
    -x test \
    -Dorg.gradle.jvmargs="-Xmx4g -Xms512m" \
    -Dfineract.custom.modules.enabled=false \
    -Dgradle.user.home=/app/.gradle

# Final stage
FROM eclipse-temurin:17-jre-focal

WORKDIR /app

# Copy the built artifact
COPY --from=builder /app/fineract-provider/build/libs/fineract-provider.jar ./app.jar

ENV JAVA_OPTS="-Xmx1G -Xms1G"
ENV FINERACT_NODE_ID=1

EXPOSE 8443

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
