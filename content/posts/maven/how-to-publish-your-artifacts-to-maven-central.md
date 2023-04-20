---
title: "How to Publish Your Artifacts to Maven Central"
date: 2023-03-24T13:24:14+08:00
tags: [maven, release, publish]
categories: [maven]
draft: true
---

## Sign up for a Sonatype Jira account.

https://issues.sonatype.org/

Create a Jira issue for new project hosting，[Click here](https://issues.sonatype.org/browse/OSSRH-68657) for a sample
request.

## Creating a GPG key pair

https://infra.apache.org/openpgp.html#generate-key

## GitHub Actions secrets

* OSSRH_USERNAME: Jira username
* OSSRH_TOKEN: Jira password
* MAVEN_GPG_PASSPHRASE: Your GPG key password

* GPG_SIGNING_KEY: Your GPG key as Base64

  ```shell
  # If you don't know your key ID, search it by e-mail
  gpg --list-secret-keys <your email address>
  # Export your key as Base64
  gpg --export-secret-keys <your key ID> | base64
  ```

## Add Profile in your Maven Project

```xml
<profile>
    <id>sonatype-oss-release</id>
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-source-plugin</artifactId>
                <version>3.0.1</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>jar</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-javadoc-plugin</artifactId>
                <version>3.0.1</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>jar</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-gpg-plugin</artifactId>
                <version>1.6</version>
                <executions>
                    <execution>
                        <id>sign-artifacts</id>
                        <phase>verify</phase>
                        <goals>
                            <goal>sign</goal>
                        </goals>
                        <configuration>
                            <!-- Prevent `gpg` from using pinentry programs -->
                            <gpgArguments>
                                <arg>--pinentry-mode</arg>
                                <arg>loopback</arg>
                            </gpgArguments>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>org.sonatype.plugins</groupId>
                <artifactId>nexus-staging-maven-plugin</artifactId>
                <version>1.6.7</version>
                <extensions>true</extensions>
                <configuration>
                    <serverId>ossrh</serverId>
                    <nexusUrl>https://s01.oss.sonatype.org/</nexusUrl>
                    <autoReleaseAfterClose>true</autoReleaseAfterClose>
                </configuration>
            </plugin>
        </plugins>
    </build>
</profile>
```

## GitHub Actions workflow

```yaml
name: Publish package to the Maven Central Repository

on:
  release:
    types: [ created ]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Maven Central Repository
        uses: actions/setup-java@v2
        with:
          java-version: '8'
          distribution: 'adopt'
          server-id: ossrh
          server-username: MAVEN_USERNAME
          server-password: MAVEN_PASSWORD
          gpg-passphrase: MAVEN_GPG_PASSPHRASE
      - name: Configure GPG Key
        run: |
          echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --import --no-tty --batch --yes
        env:
          GPG_SIGNING_KEY: ${{ secrets.GPG_SIGNING_KEY }}
      - name: Publish package
        run: mvn package deploy -Psonatype-oss-release
        env:
          MAVEN_USERNAME: ${{ secrets.OSSRH_USERNAME }}
          MAVEN_PASSWORD: ${{ secrets.OSSRH_TOKEN }}
          MAVEN_GPG_PASSPHRASE: ${{ secrets.MAVEN_GPG_PASSPHRASE }}
```

## Push Tag & Create a new release

Creating tags from the command line

```shell
git tag -a v1.0.0 -m 'Release v1.0.0'
git push origin v1.0.0
```


[Creating a release GitHub's web interface](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) or `mvn package deploy -Psonatype-oss-release` on local


