// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_screenshot_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppScreenshotRecordCollection on Isar {
  IsarCollection<AppScreenshotRecord> get appScreenshotRecords =>
      this.collection();
}

const AppScreenshotRecordSchema = CollectionSchema(
  name: r'AppScreenshotRecord',
  id: -1038940755104521945,
  properties: {
    r'appId': PropertySchema(id: 0, name: r'appId', type: IsarType.long),
    r'createAt': PropertySchema(id: 1, name: r'createAt', type: IsarType.long),
    r'path': PropertySchema(id: 2, name: r'path', type: IsarType.string),
  },

  estimateSize: _appScreenshotRecordEstimateSize,
  serialize: _appScreenshotRecordSerialize,
  deserialize: _appScreenshotRecordDeserialize,
  deserializeProp: _appScreenshotRecordDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _appScreenshotRecordGetId,
  getLinks: _appScreenshotRecordGetLinks,
  attach: _appScreenshotRecordAttach,
  version: '3.2.0-dev.2',
);

int _appScreenshotRecordEstimateSize(
  AppScreenshotRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.path.length * 3;
  return bytesCount;
}

void _appScreenshotRecordSerialize(
  AppScreenshotRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.appId);
  writer.writeLong(offsets[1], object.createAt);
  writer.writeString(offsets[2], object.path);
}

AppScreenshotRecord _appScreenshotRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppScreenshotRecord();
  object.appId = reader.readLong(offsets[0]);
  object.createAt = reader.readLong(offsets[1]);
  object.id = id;
  object.path = reader.readString(offsets[2]);
  return object;
}

P _appScreenshotRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appScreenshotRecordGetId(AppScreenshotRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appScreenshotRecordGetLinks(
  AppScreenshotRecord object,
) {
  return [];
}

void _appScreenshotRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  AppScreenshotRecord object,
) {
  object.id = id;
}

extension AppScreenshotRecordQueryWhereSort
    on QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QWhere> {
  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppScreenshotRecordQueryWhere
    on QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QWhereClause> {
  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension AppScreenshotRecordQueryFilter
    on
        QueryBuilder<
          AppScreenshotRecord,
          AppScreenshotRecord,
          QFilterCondition
        > {
  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  appIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'appId', value: value),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  appIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'appId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  appIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'appId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  appIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'appId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  createAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createAt', value: value),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  createAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  createAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  createAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  pathEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  pathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  pathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  pathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'path',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  pathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  pathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  pathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  pathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'path',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  pathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'path', value: ''),
      );
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterFilterCondition>
  pathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'path', value: ''),
      );
    });
  }
}

extension AppScreenshotRecordQueryObject
    on
        QueryBuilder<
          AppScreenshotRecord,
          AppScreenshotRecord,
          QFilterCondition
        > {}

extension AppScreenshotRecordQueryLinks
    on
        QueryBuilder<
          AppScreenshotRecord,
          AppScreenshotRecord,
          QFilterCondition
        > {}

extension AppScreenshotRecordQuerySortBy
    on QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QSortBy> {
  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  sortByAppId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appId', Sort.asc);
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  sortByAppIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appId', Sort.desc);
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  sortByCreateAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createAt', Sort.asc);
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  sortByCreateAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createAt', Sort.desc);
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  sortByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  sortByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }
}

extension AppScreenshotRecordQuerySortThenBy
    on QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QSortThenBy> {
  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  thenByAppId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appId', Sort.asc);
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  thenByAppIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appId', Sort.desc);
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  thenByCreateAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createAt', Sort.asc);
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  thenByCreateAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createAt', Sort.desc);
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  thenByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QAfterSortBy>
  thenByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }
}

extension AppScreenshotRecordQueryWhereDistinct
    on QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QDistinct> {
  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QDistinct>
  distinctByAppId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appId');
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QDistinct>
  distinctByCreateAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createAt');
    });
  }

  QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QDistinct>
  distinctByPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'path', caseSensitive: caseSensitive);
    });
  }
}

extension AppScreenshotRecordQueryProperty
    on QueryBuilder<AppScreenshotRecord, AppScreenshotRecord, QQueryProperty> {
  QueryBuilder<AppScreenshotRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppScreenshotRecord, int, QQueryOperations> appIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appId');
    });
  }

  QueryBuilder<AppScreenshotRecord, int, QQueryOperations> createAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createAt');
    });
  }

  QueryBuilder<AppScreenshotRecord, String, QQueryOperations> pathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'path');
    });
  }
}
