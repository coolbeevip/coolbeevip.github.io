---
title: "Migrate Spring Data Elasticsearch from 3.x version to 4.x"
date: 2022-03-06T13:24:14+08:00
tags: [elasticsearch, spring-data-elasticsearch]
categories: [java, elasticsearch, spring-boot]
draft: false
---

Spring Data Elasticsearch 从 3.X 迁移到 4.X

因为需要将产品的 spring boot 2.1.6.RELEASE 升级到 2.3.12.RELEASE，升级过程中发现有一些需要迁移的部分，特此整理记录。
本文不是迁移指南，仅仅是工作中遇到的迁移问题笔记

## 依赖组件

| 组件 | 迁移前 | 迁移后 |
| ---- | ---- | ---- |
| spring-data-elasticsearch | 3.1.9 | 4.0.9 |
| elasticsearch | 6.4.3 | 7.6.2 |

#### GetQuery 已废弃

以下代码中 ~~GetQuery~~ 已经被废弃，并且 ~~getQuery.setId~~ 方法已经被删除

```java
GetQuery getQuery = new GetQuery();
getQuery.setId(globalTxId);
GlobalTransactionDocument globalTransaction = this.template
    .queryForObject(getQuery, GlobalTransactionDocument.class);
```   

使用以下代码替换

```java
Query query = new NativeSearchQueryBuilder().withIds(Collections.singletonList(globalTxId)).build();
SearchHit<GlobalTransactionDocument> result =  this.template.searchOne(query, GlobalTransactionDocument.class);
GlobalTransactionDocument globalTransaction = result.getContent();
```

#### ElasticsearchTemplate 已废弃

使用 `ElasticsearchRestTemplate` 代替 `ElasticsearchTemplate`

#### ElasticsearchRestTemplate 索引操作

ElasticsearchTemplate 的 ~~getClient().admin().indices()~~ 用法已经废弃

```java
IndicesExistsRequest request = new IndicesExistsRequest(INDEX_NAME);
if (this.template.getClient().admin().indices().exists(request).actionGet().isExists()) {

}
```

迁移后 ElasticsearchRestTemplate 的用法

```java
if (this.template.indexOps(IndexCoordinates.of(INDEX_NAME)).exists()) {

}
```

#### ElasticsearchRestTemplate 翻页查询

ElasticsearchTemplate 原来的用法

```java
QueryBuilder query = QueryBuilders.termQuery("state.keyword", state);
SearchResponse response = this.template.getClient().prepareSearch(INDEX_NAME)
    .setTypes(INDEX_TYPE)
    .setQuery(query)
    .addSort(SortBuilders.fieldSort("beginTime").order(SortOrder.DESC).unmappedType("date"))
    .setSize(size)
    .setFrom(page * size)
    .execute()
    .actionGet();
```    

迁移后 ElasticsearchRestTemplate 的用法

```java
NativeSearchQueryBuilder queryBuilder = new NativeSearchQueryBuilder();
queryBuilder.withSearchType(SearchType.valueOf(INDEX_TYPE));
if (state != null && state.trim().length() > 0) {
  queryBuilder.withQuery(QueryBuilders.termQuery("state.keyword", state));
} else {
  queryBuilder.withQuery(QueryBuilders.matchAllQuery());
}
queryBuilder.withSort(SortBuilders.fieldSort("beginTime").order(SortOrder.DESC).unmappedType("date"));
queryBuilder.withPageable(PageRequest.of(page, size));

SearchHits<GlobalTransactionDocument> result = this.template.search(queryBuilder.build(), GlobalTransactionDocument.class);
```

#### ElasticsearchTemplate.query 方法以删除

~~this.template.query~~ 方法以废弃，~~SearchQuery~~ 类已被移除，NativeSearchQueryBuilder 的 ~~withIndices~~ 方法已被移除

```java
public Map<String, Long> getTransactionStatistics() {
  TermsAggregationBuilder termsAggregationBuilder = AggregationBuilders
      .terms("count_group_by_state").field("state.keyword");
  SearchQuery searchQuery = new NativeSearchQueryBuilder()
      .withIndices(INDEX_NAME)
      .addAggregation(termsAggregationBuilder)
      .build();
  return this.template.query(searchQuery, response -> {
    Map<String, Long> statistics = new HashMap<>();
    if (response.getHits().getTotalHits().value > 0) {
      final StringTerms groupState = response.getAggregations().get("count_group_by_state");
      statistics = groupState.getBuckets()
          .stream()
          .collect(Collectors.toMap(MultiBucketsAggregation.Bucket::getKeyAsString,
              MultiBucketsAggregation.Bucket::getDocCount));
    }
    return statistics;
  });
}
```

迁移后 ElasticsearchRestTemplate 新方法

```java
public Map<String, Long> getTransactionStatistics() {
  Map<String, Long> statistics = new HashMap<>();

  Query query = new NativeSearchQueryBuilder()
      .addAggregation(AggregationBuilders.terms("count_group_by_state").field("state.keyword"))
      .build();
  SearchHits<Map> result = this.template.search(query,Map.class,IndexCoordinates.of(INDEX_NAME));
  if (result.getTotalHits() > 0) {
    final StringTerms groupState = result.getAggregations().get("count_group_by_state");
    statistics = groupState.getBuckets()
        .stream()
        .collect(Collectors.toMap(MultiBucketsAggregation.Bucket::getKeyAsString,
            MultiBucketsAggregation.Bucket::getDocCount));
  }

  return statistics;
}
```

#### 索引刷新

ElasticsearchTemplate 的方法

```java
template.refresh(INDEX_NAME);
```

迁移后 ElasticsearchRestTemplate 的方法

```java
template.indexOps(IndexCoordinates.of(INDEX_NAME)).refresh();
```

#### Spring Boot 配置

旧的配置

```properties
spring.data.elasticsearch.cluster-nodes=localhost:9300
```

迁移后的配置

```properties
spring.elasticsearch.rest.uris=http://localhost:9200
```
