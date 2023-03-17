# 1) Build
FROM docker.io/eclipse-temurin:17-jdk-alpine as builder

RUN apk --no-cache add --update bash git

WORKDIR /flyway

ENV FLYWAY_VERSION=9.16.0

# Hack of resolving conflicts https://github.com/flyway/flyway/pull/3611#issuecomment-1457006906!
COPY pom.xml /flyway/pom.xml

# Build with Clickhouse support!
# See https://kb.altinity.com/altinity-kb-setup-and-maintenance/schema-migration-tools/
#  => https://github.com/flyway/flyway/pull/3611
RUN git clone --progress --depth=50 --filter=blob:none https://github.com/flyway/flyway.git flyway.git

RUN cd flyway.git \
	&& git remote add sazonov https://github.com/sazonov/flyway.git \
	&& git fetch --progress --depth=50 --filter=blob:none sazonov \
	&& git checkout --progress sazonov/clickhouse-support \
		&& git config --global user.email "Pahan@Hubbitus.info" \
		&& git config --global user.name "Pavel Alexeev" \
	&& git pull --no-rebase --no-edit origin main || : \
		&& mv /flyway/pom.xml flyway-community-db-support/pom.xml `# Conflict resolve hack! https://github.com/flyway/flyway/pull/3611#issuecomment-1457006906`

RUN cd flyway.git \
	&& ./mvnw install -Pbuild-assemblies-no-jre

RUN cd /flyway \
	&& tar -zxvf flyway.git/flyway-commandline/target/flyway-commandline-${FLYWAY_VERSION}.tar.gz --strip-components=1 \
	&& cd flyway.git \
		&& ./mvnw dependency:get "-Dartifact=com.clickhouse:clickhouse-jdbc:0.4.1:jar:all" -Ddest=. \
		&& mv ~/.m2/repository/com/clickhouse/clickhouse-jdbc/0.4.1/clickhouse-jdbc-0.4.1-all.jar /flyway/drivers/ \
	&& rm -vfr /flyway/flyway.git \
		&& chmod -R a+r /flyway \
		&& chmod a+x /flyway/flyway

# Workaround of annoyed SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder"
# See https://github.com/flyway/flyway/issues/3453#issuecomment-1147448690
RUN rm -vf /flyway/lib/aad/slf4j-api-*.jar

# 2) Target image
FROM docker.io/eclipse-temurin:17-jre-alpine

LABEL maintainer="Pavel Alexeev <plalexeev@gid.ru>"

RUN apk --no-cache add --update bash vault libcap \
  && setcap cap_ipc_lock= $(readlink -f $(which vault))

WORKDIR /flyway
ENV PATH="/flyway:${PATH}"

ENTRYPOINT ["flyway"]
CMD ["-?"]
