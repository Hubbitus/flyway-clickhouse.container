# 1) Build
FROM docker.io/eclipse-temurin:17-jdk-alpine as builder

RUN apk --no-cache add --update bash git

#? RUN apk --no-cache add --update bash openssl git
#? RUN apk --no-cache add --update python3 py3-pip \
#?    && pip3 install sqlfluff==1.2.1

WORKDIR /flyway

ENV FLYWAY_VERSION=9.15.1

# Build with Clickhouse support!
# See https://kb.altinity.com/altinity-kb-setup-and-maintenance/schema-migration-tools/
#  => https://github.com/flyway/flyway/pull/3611
RUN git clone --progress --depth=50 --filter=blob:none https://github.com/flyway/flyway.git flyway.git

RUN cd flyway.git \
	&& git remote add sazonov https://github.com/sazonov/flyway.git `# Build with Clickhouse support!` \
	&& git fetch --progress --depth=50 --filter=blob:none sazonov \
	&& git checkout --progress sazonov/clickhouse-support \
		&& git config --global user.email "Pahan@Hubbitus.info" \
		&& git config --global user.name "Pavel Alexeev" \
	&& git pull --no-rebase --no-edit origin main \
		&& sed -i 's#ENGINE = StripeLog;#ENGINE = MergeTree PRIMARY KEY version;#g;s#version Nullable(String)#version String#g' flyway-community-db-support/src/main/java/org/flywaydb/community/database/clickhouse/ClickHouseDatabase.java `# See https://github.com/flyway/flyway/pull/3611/files#r1118120672`

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

# 2) Target image
FROM docker.io/eclipse-temurin:17-jre-alpine
RUN apk --no-cache add --update bash
COPY --from=builder /flyway /flyway

ENV PATH="/flyway:${PATH}"

ENTRYPOINT ["flyway"]
CMD ["-?"]
