---
title: "使用 Checkstyle Plugin 检查 Java 代码（风格）质量"
date: 2022-09-18T13:24:14+08:00
tags: [java, checkstyle]
categories: [maven]
draft: false
---

本文记录了如何在 Maven 项目中使用 [Apache Maven Checkstyle Plugin](https://maven.apache.org/plugins/maven-checkstyle-plugin/) 检查代码风格质量

## 一个 Maven 项目

假设我有一个 Maven 项目，这个项目包含若干子模块。根目录的 pom.xml 看起来如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">

  <modelVersion>4.0.0</modelVersion>
  <groupId>my</groupId>
  <artifactId>my-project</artifactId>
  <version>${revision}</version>
  <packaging>pom</packaging>

  <properties>
  	<revision>0.1.0-SNAPSHOT</revision>
  </properties>

  <modules>
    <module>module-dependencies</module>
    <module>module-bar</module>
    <module>module-foo</module>   
  </modules>
</project>
```

## 在根项目 pom.xml 中增加 `maven-checkstyle-plugin` 插件

增加 maven-checkstyle-plugin 插件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">

  <modelVersion>4.0.0</modelVersion>
  <groupId>my</groupId>
  <artifactId>my-project</artifactId>
  <version>${revision}</version>
  <packaging>pom</packaging>

  <properties>
    <maven-checkstyle-plugin.version>3.1.2</maven-checkstyle-plugin.version>
    <com.puppycrawl.tools.version>9.3</com.puppycrawl.tools.version>
  </properties>

  <modules>
    <module>module-dependencies</module>
    <module>module-bar</module>
    <module>module-foo</module>   
  </modules>

  <build>
    <pluginManagement>
      <plugins>    
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-checkstyle-plugin</artifactId>
          <version>${maven-checkstyle-plugin.version}</version>
          <dependencies>
            <dependency>
              <groupId>com.puppycrawl.tools</groupId>
              <artifactId>checkstyle</artifactId>
              <version>${com.puppycrawl.tools.version}</version>
            </dependency>
          </dependencies>
          <configuration>
            <configLocation>src/checkstyle/google_checks.xml</configLocation>
          </configuration>
          <executions>
            <execution>
              <id>validate</id>
              <phase>validate</phase>
              <goals>
                <goal>check</goal>
              </goals>
            </execution>
          </executions>
        </plugin>
      </plugins>
    </pluginManagement>

    <plugins>
        <plugin>
          <groupId>org.apache.maven.plugins</groupId>
          <artifactId>maven-checkstyle-plugin</artifactId>
        </plugin>
    </plugins>
  </build>
</project>
```

增加 `src/checkstyle/google_checks.xml` 规则配置文件，你可以根据团队技术管理要求适当裁剪规则，你也可以在 [Checkstyle 仓库](https://github.com/checkstyle/checkstyle/tree/master/src/main/resources) 找到更多规则


```xml
<?xml version="1.0"?>
<!DOCTYPE module PUBLIC
    "-//Checkstyle//DTD Checkstyle Configuration 1.3//EN"
    "https://checkstyle.org/dtds/configuration_1_3.dtd">

<!--
    Checkstyle configuration that checks the Google coding conventions from Google Java Style
    that can be found at https://google.github.io/styleguide/javaguide.html
    Checkstyle is very configurable. Be sure to read the documentation at
    http://checkstyle.org (or in your downloaded distribution).
    To completely disable a check, just comment it out or delete it from the file.
    To suppress certain violations please review suppression filters.
    Authors: Max Vetrenko, Ruslan Diachenko, Roman Ivanov.
 -->

<module name = "Checker">
  <property name="charset" value="UTF-8"/>

  <property name="severity" value="error"/>

  <property name="fileExtensions" value="java, properties, xml"/>
  <!-- Excludes all 'module-info.java' files              -->
  <!-- See https://checkstyle.org/config_filefilters.html -->
  <module name="BeforeExecutionExclusionFileFilter">
    <property name="fileNamePattern" value="module\-info\.java$"/>
  </module>
  <!-- https://checkstyle.org/config_filters.html#SuppressionFilter -->
  <module name="SuppressionFilter">
    <property name="file" value="${org.checkstyle.google.suppressionfilter.config}"
              default="checkstyle-suppressions.xml" />
    <property name="optional" value="true"/>
  </module>

  <!-- Checks for whitespace                               -->
  <!-- See http://checkstyle.org/config_whitespace.html -->
  <module name="FileTabCharacter">
    <property name="eachLine" value="true"/>
  </module>

  <module name="LineLength">
    <property name="fileExtensions" value="java"/>
    <property name="max" value="180"/>
    <property name="ignorePattern" value="^package.*|^import.*|a href|href|http://|https://|ftp://"/>
  </module>

  <module name="TreeWalker">
    <module name="OuterTypeFilename"/>
    <module name="IllegalTokenText">
      <property name="tokens" value="STRING_LITERAL, CHAR_LITERAL"/>
      <property name="format"
                value="\\u00(09|0(a|A)|0(c|C)|0(d|D)|22|27|5(C|c))|\\(0(10|11|12|14|15|42|47)|134)"/>
      <property name="message"
                value="Consider using special escape sequence instead of octal value or Unicode escaped value."/>
    </module>
    <module name="AvoidEscapedUnicodeCharacters">
      <property name="allowEscapesForControlCharacters" value="true"/>
      <property name="allowByTailComment" value="true"/>
      <property name="allowNonPrintableEscapes" value="true"/>
    </module>   
    <module name="OneTopLevelClass"/>
    <module name="NoLineWrap">
      <property name="tokens" value="PACKAGE_DEF, IMPORT, STATIC_IMPORT"/>
    </module>
    <module name="EmptyBlock">
      <property name="option" value="TEXT"/>
      <property name="tokens"
                value="LITERAL_TRY, LITERAL_FINALLY, LITERAL_IF, LITERAL_ELSE, LITERAL_SWITCH"/>
    </module>
    <module name="LeftCurly">
      <property name="tokens"
                value="ANNOTATION_DEF, CLASS_DEF, CTOR_DEF, ENUM_CONSTANT_DEF, ENUM_DEF,
                    INTERFACE_DEF, LAMBDA, LITERAL_CASE, LITERAL_CATCH, LITERAL_DEFAULT,
                    LITERAL_DO, LITERAL_ELSE, LITERAL_FINALLY, LITERAL_FOR, LITERAL_IF,
                    LITERAL_SWITCH, LITERAL_SYNCHRONIZED, LITERAL_TRY, LITERAL_WHILE, METHOD_DEF,
                    OBJBLOCK, STATIC_INIT, RECORD_DEF, COMPACT_CTOR_DEF"/>
    </module>
    <module name="RightCurly">
      <property name="id" value="RightCurlySame"/>
      <property name="tokens"
                value="LITERAL_TRY, LITERAL_CATCH, LITERAL_FINALLY, LITERAL_IF, LITERAL_ELSE,
                    LITERAL_DO"/>
    </module>
    <module name="RightCurly">
      <property name="id" value="RightCurlyAlone"/>
      <property name="option" value="alone"/>
      <property name="tokens"
                value="CLASS_DEF, METHOD_DEF, CTOR_DEF, LITERAL_FOR, LITERAL_WHILE, STATIC_INIT,
                    INSTANCE_INIT, ANNOTATION_DEF, ENUM_DEF, INTERFACE_DEF, RECORD_DEF,
                    COMPACT_CTOR_DEF"/>
    </module>
    <module name="SuppressionXpathSingleFilter">
      <!-- suppresion is required till https://github.com/checkstyle/checkstyle/issues/7541 -->
      <property name="id" value="RightCurlyAlone"/>
      <property name="query" value="//RCURLY[parent::SLIST[count(./*)=1]
                                     or preceding-sibling::*[last()][self::LCURLY]]"/>
    </module>
    <module name="WhitespaceAfter">
      <property name="tokens"
                value="COMMA, SEMI, TYPECAST, LITERAL_IF, LITERAL_ELSE,
                    LITERAL_WHILE, LITERAL_DO, LITERAL_FOR, DO_WHILE"/>
    </module>
    <module name="WhitespaceAround">
      <property name="allowEmptyConstructors" value="true"/>
      <property name="allowEmptyLambdas" value="true"/>
      <property name="allowEmptyMethods" value="true"/>
      <property name="allowEmptyTypes" value="true"/>
      <property name="allowEmptyLoops" value="true"/>
      <property name="ignoreEnhancedForColon" value="false"/>
      <property name="tokens"
                value="ASSIGN, BAND, BAND_ASSIGN, BOR, BOR_ASSIGN, BSR, BSR_ASSIGN, BXOR,
                    BXOR_ASSIGN, COLON, DIV, DIV_ASSIGN, DO_WHILE, EQUAL, GE, GT, LAMBDA, LAND,
                    LCURLY, LE, LITERAL_CATCH, LITERAL_DO, LITERAL_ELSE, LITERAL_FINALLY,
                    LITERAL_FOR, LITERAL_IF, LITERAL_RETURN, LITERAL_SWITCH, LITERAL_SYNCHRONIZED,
                    LITERAL_TRY, LITERAL_WHILE, LOR, LT, MINUS, MINUS_ASSIGN, MOD, MOD_ASSIGN,
                    NOT_EQUAL, PLUS, PLUS_ASSIGN, QUESTION, RCURLY, SL, SLIST, SL_ASSIGN, SR,
                    SR_ASSIGN, STAR, STAR_ASSIGN, LITERAL_ASSERT, TYPE_EXTENSION_AND"/>
      <message key="ws.notFollowed"
               value="WhitespaceAround: ''{0}'' is not followed by whitespace. Empty blocks may only be represented as '{}' when not part of a multi-block statement (4.1.3)"/>
      <message key="ws.notPreceded"
               value="WhitespaceAround: ''{0}'' is not preceded with whitespace."/>
    </module>
    <module name="OneStatementPerLine"/>
    <module name="MultipleVariableDeclarations"/>
    <module name="ArrayTypeStyle"/>
    <module name="MissingSwitchDefault"/>
    <module name="FallThrough"/>
    <module name="UpperEll"/>
    <module name="ModifierOrder"/>
    <module name="EmptyLineSeparator">
      <property name="tokens"
                value="PACKAGE_DEF, IMPORT, STATIC_IMPORT, CLASS_DEF, INTERFACE_DEF, ENUM_DEF,
                    STATIC_INIT, INSTANCE_INIT, METHOD_DEF, CTOR_DEF, VARIABLE_DEF, RECORD_DEF,
                    COMPACT_CTOR_DEF"/>
      <property name="allowNoEmptyLineBetweenFields" value="true"/>
    </module>
    <module name="SeparatorWrap">
      <property name="id" value="SeparatorWrapComma"/>
      <property name="tokens" value="COMMA"/>
      <property name="option" value="EOL"/>
    </module>
    <module name="SeparatorWrap">
      <!-- ELLIPSIS is EOL until https://github.com/google/styleguide/issues/259 -->
      <property name="id" value="SeparatorWrapEllipsis"/>
      <property name="tokens" value="ELLIPSIS"/>
      <property name="option" value="EOL"/>
    </module>
    <module name="SeparatorWrap">
      <!-- ARRAY_DECLARATOR is EOL until https://github.com/google/styleguide/issues/258 -->
      <property name="id" value="SeparatorWrapArrayDeclarator"/>
      <property name="tokens" value="ARRAY_DECLARATOR"/>
      <property name="option" value="EOL"/>
    </module>
    <module name="SeparatorWrap">
      <property name="id" value="SeparatorWrapMethodRef"/>
      <property name="tokens" value="METHOD_REF"/>
      <property name="option" value="nl"/>
    </module>
    <module name="PackageName">
      <property name="format" value="^[a-z]+(\.[a-z][a-z0-9]*)*$"/>
      <message key="name.invalidPattern"
               value="Package name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <module name="TypeName">
      <property name="tokens" value="CLASS_DEF, INTERFACE_DEF, ENUM_DEF,
                    ANNOTATION_DEF, RECORD_DEF"/>
      <message key="name.invalidPattern"
               value="Type name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <module name="MemberName">
      <property name="format" value="^[a-z][a-z0-9][a-zA-Z0-9]*$"/>
      <message key="name.invalidPattern"
               value="Member name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <module name="ParameterName">
      <property name="format" value="^[a-z]([a-z0-9][a-zA-Z0-9]*)?$"/>
      <message key="name.invalidPattern"
               value="Parameter name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <module name="CatchParameterName">
      <property name="format" value="^[a-z]([a-z0-9][a-zA-Z0-9]*)?$"/>
      <message key="name.invalidPattern"
               value="Catch parameter name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <module name="LocalVariableName">
      <property name="format" value="^[a-z]([a-z0-9][a-zA-Z0-9]*)?$"/>
      <message key="name.invalidPattern"
               value="Local variable name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <module name="PatternVariableName">
      <property name="format" value="^[a-z]([a-z0-9][a-zA-Z0-9]*)?$"/>
      <message key="name.invalidPattern"
               value="Pattern variable name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <module name="ClassTypeParameterName">
      <property name="format" value="(^[A-Z][0-9]?)$|([A-Z][a-zA-Z0-9]*[T]$)"/>
      <message key="name.invalidPattern"
               value="Class type name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <module name="RecordComponentName">
      <property name="format" value="^[a-z]([a-z0-9][a-zA-Z0-9]*)?$"/>
      <message key="name.invalidPattern"
               value="Record component name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <module name="RecordTypeParameterName">
      <property name="format" value="(^[A-Z][0-9]?)$|([A-Z][a-zA-Z0-9]*[T]$)"/>
      <message key="name.invalidPattern"
               value="Record type name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <module name="MethodTypeParameterName">
      <property name="format" value="(^[A-Z][0-9]?)$|([A-Z][a-zA-Z0-9]*[T]$)"/>
      <message key="name.invalidPattern"
               value="Method type name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <module name="InterfaceTypeParameterName">
      <property name="format" value="(^[A-Z][0-9]?)$|([A-Z][a-zA-Z0-9]*[T]$)"/>
      <message key="name.invalidPattern"
               value="Interface type name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <module name="NoFinalizer"/>
    <module name="GenericWhitespace">
      <message key="ws.followed"
               value="GenericWhitespace ''{0}'' is followed by whitespace."/>
      <message key="ws.preceded"
               value="GenericWhitespace ''{0}'' is preceded with whitespace."/>
      <message key="ws.illegalFollow"
               value="GenericWhitespace ''{0}'' should followed by whitespace."/>
      <message key="ws.notPreceded"
               value="GenericWhitespace ''{0}'' is not preceded with whitespace."/>
    </module>
    <module name="Indentation">
      <property name="basicOffset" value="2"/>
      <property name="braceAdjustment" value="2"/>
      <property name="caseIndent" value="2"/>
      <property name="throwsIndent" value="4"/>
      <property name="lineWrappingIndentation" value="4"/>
      <property name="arrayInitIndent" value="2"/>
    </module>
    <module name="NoWhitespaceBeforeCaseDefaultColon"/>
    <module name="MethodParamPad">
      <property name="tokens"
                value="CTOR_DEF, LITERAL_NEW, METHOD_CALL, METHOD_DEF,
                    SUPER_CTOR_CALL, ENUM_CONSTANT_DEF, RECORD_DEF"/>
    </module>
    <module name="NoWhitespaceBefore">
      <property name="tokens"
                value="COMMA, SEMI, POST_INC, POST_DEC, DOT,
                    LABELED_STAT, METHOD_REF"/>
      <property name="allowLineBreaks" value="true"/>
    </module>
    <module name="ParenPad">
      <property name="tokens"
                value="ANNOTATION, ANNOTATION_FIELD_DEF, CTOR_CALL, CTOR_DEF, DOT, ENUM_CONSTANT_DEF,
                    EXPR, LITERAL_CATCH, LITERAL_DO, LITERAL_FOR, LITERAL_IF, LITERAL_NEW,
                    LITERAL_SWITCH, LITERAL_SYNCHRONIZED, LITERAL_WHILE, METHOD_CALL,
                    METHOD_DEF, QUESTION, RESOURCE_SPECIFICATION, SUPER_CTOR_CALL, LAMBDA,
                    RECORD_DEF"/>
    </module>
    <module name="AnnotationLocation">
      <property name="id" value="AnnotationLocationMostCases"/>
      <property name="tokens"
                value="CLASS_DEF, INTERFACE_DEF, ENUM_DEF, METHOD_DEF, CTOR_DEF,
                      RECORD_DEF, COMPACT_CTOR_DEF"/>
    </module>
    <module name="AnnotationLocation">
      <property name="id" value="AnnotationLocationVariables"/>
      <property name="tokens" value="VARIABLE_DEF"/>
      <property name="allowSamelineMultipleAnnotations" value="true"/>
    </module>
    <module name="MethodName">
      <property name="format" value="^[a-z][a-z0-9][a-zA-Z0-9_]*$"/>
      <message key="name.invalidPattern"
               value="Method name ''{0}'' must match pattern ''{1}''."/>
    </module>
    <!-- <module name="SingleLineJavadoc"/> -->
    <module name="EmptyCatchBlock">
      <property name="exceptionVariableName" value="expected"/>
    </module>
    <module name="CommentsIndentation">
      <property name="tokens" value="SINGLE_LINE_COMMENT, BLOCK_COMMENT_BEGIN"/>
    </module>
    <!-- https://checkstyle.org/config_filters.html#SuppressionXpathFilter -->
    <module name="SuppressionXpathFilter">
      <property name="file" value="${org.checkstyle.google.suppressionxpathfilter.config}"
                default="checkstyle-xpath-suppressions.xml" />
      <property name="optional" value="true"/>
    </module>
  </module>
</module>
```

## 命令行检查

你可以在 PR 的合并请求时使用以下命令，已确保代码合并前符合规则

```shell
mvn clean validate -DskipTests checkstyle:check
```

## IDE 工具

[Jetbrains IDEA Checkstyle](https://plugins.jetbrains.com/plugin/1065-checkstyle-idea)