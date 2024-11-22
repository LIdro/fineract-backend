FROM eclipse-temurin:17-jdk-focal AS builder

WORKDIR /app

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    curl \
    dos2unix \
    postgresql-client \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set GRADLE_USER_HOME
ENV GRADLE_USER_HOME=/app/.gradle

# Create gradle user home directory
RUN mkdir -p $GRADLE_USER_HOME

# Copy license and configuration files first
COPY APACHE_LICENSETEXT.md LICENSE* NOTICE* ./

# Copy gradle files
COPY gradle gradle/
COPY gradlew gradlew.bat build.gradle settings.gradle gradle.properties ./

# Fix line endings and make gradlew executable
RUN dos2unix gradlew && \
    chmod +x gradlew

# Copy buildSrc
COPY buildSrc buildSrc/

# Create init.gradle with repository configurations
RUN mkdir -p /root/.gradle && \
    echo "allprojects {" > /root/.gradle/init.gradle && \
    echo "    repositories {" >> /root/.gradle/init.gradle && \
    echo "        mavenCentral()" >> /root/.gradle/init.gradle && \
    echo "        gradlePluginPortal()" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://repo1.maven.org/maven2' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://plugins.gradle.org/m2/' }" >> /root/.gradle/init.gradle && \
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
COPY fineract-provider fineract-provider/
COPY fineract-client fineract-client/
COPY fineract-avro-schemas fineract-avro-schemas/
COPY fineract-core fineract-core/
COPY fineract-loan fineract-loan/
COPY fineract-investor fineract-investor/
COPY integration-tests integration-tests/
COPY config config/
COPY custom custom/

# Build with specific settings and skip license tasks
RUN ./gradlew clean bootJar \
    --no-daemon \
    --info \
    --debug \
    --stacktrace \
    -x test \
    -x licenseMain \
    -x licenseTest \
    -x licenseFormatMain \
    -x licenseFormatTest \
    --refresh-dependencies \
    -Dorg.gradle.jvmargs="-Xmx4g -Xms512m" \
    -Dfineract.custom.modules.enabled=false \
    -Dgradle.user.home=/app/.gradle \
    -Dorg.gradle.parallel=false

# Final stage
FROM eclipse-temurin:17-jre-focal

WORKDIR /app

# Install PostgreSQL client
RUN apt-get update && \
    apt-get install -y postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy the built artifact
COPY --from=builder /app/fineract-provider/build/libs/fineract-provider.jar ./app.jar

ENV JAVA_OPTS="-Xmx1G -Xms1G"
ENV FINERACT_NODE_ID=1

# Database configuration
ENV FINERACT_HIKARI_DRIVER_CLASS_NAME=org.postgresql.Driver
ENV FINERACT_HIKARI_JDBC_URL=jdbc:postgresql://srv-captain--fineract-db:5432/fineract_tenants
ENV FINERACT_HIKARI_USERNAME=root
ENV FINERACT_HIKARI_PASSWORD=postgres
ENV FINERACT_HIKARI_MINIMUM_IDLE=3
ENV FINERACT_HIKARI_MAXIMUM_POOL_SIZE=10
ENV FINERACT_HIKARI_IDLE_TIMEOUT=60000
ENV FINERACT_HIKARI_CONNECTION_TIMEOUT=20000
ENV FINERACT_HIKARI_TEST_QUERY="SELECT 1"
ENV FINERACT_HIKARI_AUTO_COMMIT=true
ENV FINERACT_TENANT_HOST=srv-captain--fineract-db
ENV FINERACT_TENANT_PORT=5432
ENV FINERACT_TENANT_DB_NAME=fineract_default
ENV FINERACT_TENANT_USERNAME=root
ENV FINERACT_TENANT_PASSWORD=postgres

# Wait for database script
COPY config/docker/wait-for-it.sh /wait-for-it.sh
RUN chmod +x /wait-for-it.sh

EXPOSE 8443

CMD ["/bin/bash", "-c", "/wait-for-it.sh srv-captain--fineract-db:5432 -- java $JAVA_OPTS -jar app.jar"]
