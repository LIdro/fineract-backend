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

# Set GRADLE_USER_HOME and other environment variables
ENV GRADLE_USER_HOME=/app/.gradle
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false"
ENV JAVA_TOOL_OPTIONS="-Xmx4g -Xms512m"

# Create gradle directories
RUN mkdir -p $GRADLE_USER_HOME && \
    mkdir -p /root/.gradle

# Copy gradle files first
COPY gradle gradle/
COPY gradlew gradlew.bat ./
COPY build.gradle settings.gradle gradle.properties ./
RUN dos2unix gradlew && chmod +x gradlew

# Create init.gradle with repository configurations
RUN echo "allprojects {" > /root/.gradle/init.gradle && \
    echo "    repositories {" >> /root/.gradle/init.gradle && \
    echo "        mavenCentral()" >> /root/.gradle/init.gradle && \
    echo "        gradlePluginPortal()" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://repo1.maven.org/maven2' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://plugins.gradle.org/m2/' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://jfrog.fineract.dev/artifactory/libs-snapshot-local' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://jfrog.fineract.dev/artifactory/libs-release-local' }" >> /root/.gradle/init.gradle && \
    echo "        maven { url 'https://packages.confluent.io/maven/' }" >> /root/.gradle/init.gradle && \
    echo "    }" >> /root/.gradle/init.gradle && \
    echo "    configurations.all {" >> /root/.gradle/init.gradle && \
    echo "        resolutionStrategy {" >> /root/.gradle/init.gradle && \
    echo "            force 'org.mapstruct:mapstruct-processor:1.5.5.Final'" >> /root/.gradle/init.gradle && \
    echo "            force 'org.mapstruct:mapstruct:1.5.5.Final'" >> /root/.gradle/init.gradle && \
    echo "            force 'org.projectlombok:lombok:1.18.30'" >> /root/.gradle/init.gradle && \
    echo "            force 'org.projectlombok:lombok-mapstruct-binding:0.2.0'" >> /root/.gradle/init.gradle && \
    echo "        }" >> /root/.gradle/init.gradle && \
    echo "    }" >> /root/.gradle/init.gradle && \
    echo "}" >> /root/.gradle/init.gradle

# Copy buildSrc
COPY buildSrc buildSrc/

# Copy source files in dependency order
COPY fineract-core fineract-core/
COPY fineract-avro-schemas fineract-avro-schemas/
COPY fineract-client fineract-client/
COPY fineract-loan fineract-loan/
COPY fineract-investor fineract-investor/
COPY fineract-provider fineract-provider/
COPY integration-tests integration-tests/
COPY config config/
COPY custom custom/

# Copy license files
COPY APACHE_LICENSETEXT.md LICENSE_SOURCE LICENSE_RELEASE NOTICE_SOURCE NOTICE_RELEASE README.md ./

# Apply license headers
RUN ./gradlew spotlessApply --no-daemon

# Build with specific settings
RUN ./gradlew clean build \
    --console=plain \
    --no-daemon \
    --info \
    --stacktrace \
    -x test \
    -x rat \
    -x spotlessCheck \
    -x spotlessApply \
    -x licenseMain \
    -x licenseTest \
    -x licenseFormatMain \
    -x licenseFormatTest \
    -Dfineract.custom.modules.enabled=false \
    -Dorg.gradle.parallel=false \
    -Dorg.gradle.warning.mode=all \
    -Dorg.gradle.jvmargs="-Xmx4g -Xms512m -XX:+HeapDumpOnOutOfMemoryError" \
    -Dorg.gradle.configureondemand=false && \
    ./gradlew :fineract-provider:bootJar \
    --console=plain \
    --no-daemon \
    -x test \
    -x rat \
    -x spotlessCheck \
    -x spotlessApply \
    -x licenseMain \
    -x licenseTest \
    -x licenseFormatMain \
    -x licenseFormatTest

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
