---
title: "Flyway Support Oracle "
date: 2018-11-29T13:24:14+08:00
categories: [java, flyway, oracle]
draft: false
---

记录在使用 Flyway 管理 Oracle 数据库脚本时遇到的一些问题，Flyway 5.2.1 - 7.7.3 都存在此问题。

#### 1. Flyway not support Oracle 11g

异常信息

```shell
Caused by: org.flywaydb.core.internal.license.FlywayEditionUpgradeRequiredException: Flyway Enterprise Edition or Oracle upgrade required: Oracle 11.2 is no longer supported by Flyway Community Edition, but still supported by Flyway Enterprise Edition.
	at org.flywaydb.core.internal.database.base.Database.ensureDatabaseNotOlderThanOtherwiseRecommendUpgradeToFlywayEdition(Database.java:173)
	at org.flywaydb.core.internal.database.oracle.OracleDatabase.ensureSupported(OracleDatabase.java:91)
	at org.flywaydb.core.Flyway.execute(Flyway.java:514)
	at org.flywaydb.core.Flyway.migrate(Flyway.java:159)
	at org.springframework.boot.autoconfigure.flyway.FlywayMigrationInitializer.afterPropertiesSet(FlywayMigrationInitializer.java:65)
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.invokeInitMethods(AbstractAutowireCapableBeanFactory.java:1855)
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.initializeBean(AbstractAutowireCapableBeanFactory.java:1792)
	... 19 common frames omitted
```

* 修改 Flyway 5.2.4 [OracleDatabase.java](https://github.com/flyway/flyway/blob/0e87e9d7bedc06398d40902149a04e82c38eb9a3/flyway-core/src/main/java/org/flywaydb/core/internal/database/oracle/OracleDatabase.java#L118) 社区版本做了版本号限制
* 修改 Flyway 6.5.7 [OracleDatabase.java](https://github.com/flyway/flyway/blob/d3295ba81c0c29aa5e5aeff577b2572f9c4d7910/flyway-core/src/main/java/org/flywaydb/core/internal/database/oracle/OracleDatabase.java#L91) 社区版本做了版本号限制
* 修改 Flyway 7.7.3 [OracleDatabase.java](https://github.com/flyway/flyway/blob/74aa05c5cd6e05a4667e841e42ac6af361cb7489/flyway-core/src/main/java/org/flywaydb/core/internal/database/oracle/OracleDatabase.java#L84) 社区版本做了版本号限制

**解决办法：** 删除 ensureDatabaseNotOlderThanOtherwiseRecommendUpgradeToFlywayEdition 行检查代码

```java
@Override
public final void ensureSupported() {
    ensureDatabaseIsRecentEnough("10");
    ensureDatabaseNotOlderThanOtherwiseRecommendUpgradeToFlywayEdition("12.2", org.flywaydb.core.internal.license.Edition.ENTERPRISE);
    recommendFlywayUpgradeIfNecessary("19.0");
}
```

#### 2. ALL_SCHEDULER_CREDENTIALS not exist

ALL_SCHEDULER_CREDENTIALS 在 Oracle10 中不存在，并且在 Oracle12c以后废弃

* 修改 Flyway 5.2.4 [OracleSchema.java](https://github.com/flyway/flyway/blob/0e87e9d7bedc06398d40902149a04e82c38eb9a3/flyway-core/src/main/java/org/flywaydb/core/internal/database/oracle/OracleSchema.java#L783) 的 `getObjectTypeNames` 方法
* 修改 Flyway 6.4.4 [OracleSchema.java](https://github.com/flyway/flyway/blob/c13e6880bf9470850dfaa3cbd0070d7fb83b1d3e/flyway-core/src/main/java/org/flywaydb/core/internal/database/oracle/OracleSchema.java#L783) 的 `getObjectTypeNames` 方法
* 修改 Flyway 7.7.3 [OracleSchema.java](https://github.com/flyway/flyway/blob/74aa05c5cd6e05a4667e841e42ac6af361cb7489/flyway-core/src/main/java/org/flywaydb/core/internal/database/oracle/OracleSchema.java#L783) 的 `getObjectTypeNames` 方法

**解决办法：** 判断 `database.getVersion().getMajor().intValue() > 10` 才增加 `ALL_SCHEDULER_CREDENTIALS` 表的关联查询 

```java
  /**
   * Returns the schema's existing object types.
   *
   * @return a set of object type names.
   * @throws SQLException if retrieving of object types failed.
   */
  public static Set<String> getObjectTypeNames(JdbcTemplate jdbcTemplate, OracleDatabase database,
      OracleSchema schema) throws SQLException {
    boolean xmlDbAvailable = database.isXmlDbAvailable();

    String query =
        // Most object types can be correctly selected from DBA_/ALL_OBJECTS.
        "SELECT DISTINCT OBJECT_TYPE FROM " + database.dbaOrAll("OBJECTS") + " WHERE OWNER = ? " +
            // Materialized view logs.
            "UNION SELECT '" + MATERIALIZED_VIEW_LOG.getName() + "' FROM DUAL WHERE EXISTS(" +
            "SELECT * FROM ALL_MVIEW_LOGS WHERE LOG_OWNER = ?) " +
            // Dimensions.
            "UNION SELECT '" + DIMENSION.getName() + "' FROM DUAL WHERE EXISTS(" +
            "SELECT * FROM ALL_DIMENSIONS WHERE OWNER = ?) " +
            // Queue tables.
            "UNION SELECT '" + QUEUE_TABLE.getName() + "' FROM DUAL WHERE EXISTS(" +
            "SELECT * FROM ALL_QUEUE_TABLES WHERE OWNER = ?) " +
            // Database links.
            "UNION SELECT '" + DATABASE_LINK.getName() + "' FROM DUAL WHERE EXISTS(" +
            "SELECT * FROM " + database.dbaOrAll("DB_LINKS") + " WHERE OWNER = ?) " +
            // Contexts.
            "UNION SELECT '" + CONTEXT.getName() + "' FROM DUAL WHERE EXISTS(" +
            "SELECT * FROM " + database.dbaOrAll("CONTEXT") + " WHERE SCHEMA = ?) " +
            // XML schemas.
            (xmlDbAvailable
                ? "UNION SELECT '" + XML_SCHEMA.getName() + "' FROM DUAL WHERE EXISTS(" +
                "SELECT * FROM " + database.dbaOrAll("XML_SCHEMAS") + " WHERE OWNER = ?) "
                : "");

    if (database.getVersion().getMajor().intValue() > 10 || !database.getVersion().isAtLeast("12.2")) {
      // Credentials.
      query = query + "UNION SELECT '" + CREDENTIAL.getName() + "' FROM DUAL WHERE EXISTS(" +
          "SELECT * FROM ALL_SCHEDULER_CREDENTIALS WHERE OWNER = ?) ";
    }

    int n = 6 + (xmlDbAvailable ? 1 : 0) +

        1;
    String[] params = new String[n];
    Arrays.fill(params, schema.getName());

    return new HashSet<>(jdbcTemplate.queryForStringList(query, params));
  }
```

#### 3. oracle_maintained column does not exist

Oracle 12c 之前的版本，ALL_USERS 这表中不存在 ORACLE_MAINTAINED 字段


* 修改 Flyway 5.2.4 [OracleDatabase.java](https://github.com/flyway/flyway/blob/0e87e9d7bedc06398d40902149a04e82c38eb9a3/flyway-core/src/main/java/org/flywaydb/core/internal/database/oracle/OracleDatabase.java#L365) 的 getSystemSchemas 方法
* 修改 Flyway 6.5.7 [OracleDatabase.java](https://github.com/flyway/flyway/blob/d3295ba81c0c29aa5e5aeff577b2572f9c4d7910/flyway-core/src/main/java/org/flywaydb/core/internal/database/oracle/OracleDatabase.java#L321) 的 getSystemSchemas 方法
* 修改 Flyway 7.7.3 [OracleDatabase.java](https://github.com/flyway/flyway/blob/74aa05c5cd6e05a4667e841e42ac6af361cb7489/flyway-core/src/main/java/org/flywaydb/core/internal/database/oracle/OracleDatabase.java#L320) 的 getSystemSchemas 方法

**解决办法：** 增加 `getVersion().isAtLeast("12.2")` 版本判断，当小于 12.2 版本时不判断 `ORACLE_MAINTAINED` 字段
```java
/**
 * Returns the list of schemas that were created and are maintained by Oracle-supplied scripts and must not be
 * changed in any other way. The list is composed of default schemas mentioned in the official documentation for
 * Oracle Database versions from 10.1 to 12.2, and is dynamically extended with schemas from DBA_REGISTRY and
 * ALL_USERS (marked with ORACLE_MAINTAINED = 'Y' in Oracle 12c).
 *
 * @return the set of system schema names
 */
Set<String> getSystemSchemas() throws SQLException {

  // The list of known default system schemas
  Set<String> result = new HashSet<>(Arrays.asList(
      "SYS", "SYSTEM", // Standard system accounts
      "SYSBACKUP", "SYSDG", "SYSKM", "SYSRAC", "SYS$UMF", // Auxiliary system accounts
      "DBSNMP", "MGMT_VIEW", "SYSMAN", // Enterprise Manager accounts
      "OUTLN", // Stored outlines
      "AUDSYS", // Unified auditing
      "ORACLE_OCM", // Oracle Configuration Manager
      "APPQOSSYS", // Oracle Database QoS Management
      "OJVMSYS", // Oracle JavaVM
      "DVF", "DVSYS", // Oracle Database Vault
      "DBSFWUSER", // Database Service Firewall
      "REMOTE_SCHEDULER_AGENT", // Remote scheduler agent
      "DIP", // Oracle Directory Integration Platform
      "APEX_PUBLIC_USER", "FLOWS_FILES", /*"APEX_######", "FLOWS_######",*/
      // Oracle Application Express
      "ANONYMOUS", "XDB", "XS$NULL", // Oracle XML Database
      "CTXSYS", // Oracle Text
      "LBACSYS", // Oracle Label Security
      "EXFSYS", // Oracle Rules Manager and Expression Filter
      "MDDATA", "MDSYS", "SPATIAL_CSW_ADMIN_USR", "SPATIAL_WFS_ADMIN_USR",
      // Oracle Locator and Spatial
      "ORDDATA", "ORDPLUGINS", "ORDSYS", "SI_INFORMTN_SCHEMA", // Oracle Multimedia
      "WMSYS", // Oracle Workspace Manager
      "OLAPSYS", // Oracle OLAP catalogs
      "OWBSYS", "OWBSYS_AUDIT", // Oracle Warehouse Builder
      "GSMADMIN_INTERNAL", "GSMCATUSER", "GSMUSER", // Global Data Services
      "GGSYS", // Oracle GoldenGate
      "WK_TEST", "WKSYS", "WKPROXY", // Oracle Ultra Search
      "ODM", "ODM_MTR", "DMSYS", // Oracle Data Mining
      "TSMSYS" // Transparent Session Migration
  ));

  if (!getVersion().isAtLeast("12.2")) {
    result.addAll(
        getMainConnection().getJdbcTemplate()
            .queryForStringList("SELECT USERNAME FROM ALL_USERS " +
                "WHERE REGEXP_LIKE(USERNAME, '^(APEX|FLOWS)_\\d+$')"
            ));
  } else {
    result.addAll(
        getMainConnection().getJdbcTemplate()
            .queryForStringList("SELECT USERNAME FROM ALL_USERS " +
                "WHERE REGEXP_LIKE(USERNAME, '^(APEX|FLOWS)_\\d+$')" +
                " OR ORACLE_MAINTAINED = 'Y'"
            ));
  }
  return result;
}
```