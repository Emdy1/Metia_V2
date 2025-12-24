// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_database.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAnimeDatabaseCollection on Isar {
  IsarCollection<AnimeDatabase> get animeDatabases => this.collection();
}

const AnimeDatabaseSchema = CollectionSchema(
  name: r'AnimeDatabase',
  id: -7123506015754260134,
  properties: {
    r'anilistMeidaId': PropertySchema(
      id: 0,
      name: r'anilistMeidaId',
      type: IsarType.long,
    ),
    r'extensionId': PropertySchema(
      id: 1,
      name: r'extensionId',
      type: IsarType.long,
    ),
    r'matchedAnime': PropertySchema(
      id: 2,
      name: r'matchedAnime',
      type: IsarType.object,
      target: r'MetiaAnime',
    )
  },
  estimateSize: _animeDatabaseEstimateSize,
  serialize: _animeDatabaseSerialize,
  deserialize: _animeDatabaseDeserialize,
  deserializeProp: _animeDatabaseDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {r'MetiaAnime': MetiaAnimeSchema},
  getId: _animeDatabaseGetId,
  getLinks: _animeDatabaseGetLinks,
  attach: _animeDatabaseAttach,
  version: '3.1.0+1',
);

int _animeDatabaseEstimateSize(
  AnimeDatabase object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.matchedAnime;
    if (value != null) {
      bytesCount += 3 +
          MetiaAnimeSchema.estimateSize(
              value, allOffsets[MetiaAnime]!, allOffsets);
    }
  }
  return bytesCount;
}

void _animeDatabaseSerialize(
  AnimeDatabase object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.anilistMeidaId);
  writer.writeLong(offsets[1], object.extensionId);
  writer.writeObject<MetiaAnime>(
    offsets[2],
    allOffsets,
    MetiaAnimeSchema.serialize,
    object.matchedAnime,
  );
}

AnimeDatabase _animeDatabaseDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AnimeDatabase();
  object.anilistMeidaId = reader.readLongOrNull(offsets[0]);
  object.extensionId = reader.readLongOrNull(offsets[1]);
  object.id = id;
  object.matchedAnime = reader.readObjectOrNull<MetiaAnime>(
    offsets[2],
    MetiaAnimeSchema.deserialize,
    allOffsets,
  );
  return object;
}

P _animeDatabaseDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readObjectOrNull<MetiaAnime>(
        offset,
        MetiaAnimeSchema.deserialize,
        allOffsets,
      )) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _animeDatabaseGetId(AnimeDatabase object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _animeDatabaseGetLinks(AnimeDatabase object) {
  return [];
}

void _animeDatabaseAttach(
    IsarCollection<dynamic> col, Id id, AnimeDatabase object) {
  object.id = id;
}

extension AnimeDatabaseQueryWhereSort
    on QueryBuilder<AnimeDatabase, AnimeDatabase, QWhere> {
  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AnimeDatabaseQueryWhere
    on QueryBuilder<AnimeDatabase, AnimeDatabase, QWhereClause> {
  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AnimeDatabaseQueryFilter
    on QueryBuilder<AnimeDatabase, AnimeDatabase, QFilterCondition> {
  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      anilistMeidaIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'anilistMeidaId',
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      anilistMeidaIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'anilistMeidaId',
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      anilistMeidaIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'anilistMeidaId',
        value: value,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      anilistMeidaIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'anilistMeidaId',
        value: value,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      anilistMeidaIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'anilistMeidaId',
        value: value,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      anilistMeidaIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'anilistMeidaId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      extensionIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'extensionId',
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      extensionIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'extensionId',
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      extensionIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'extensionId',
        value: value,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      extensionIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'extensionId',
        value: value,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      extensionIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'extensionId',
        value: value,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      extensionIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'extensionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      matchedAnimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'matchedAnime',
      ));
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      matchedAnimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'matchedAnime',
      ));
    });
  }
}

extension AnimeDatabaseQueryObject
    on QueryBuilder<AnimeDatabase, AnimeDatabase, QFilterCondition> {
  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterFilterCondition>
      matchedAnime(FilterQuery<MetiaAnime> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'matchedAnime');
    });
  }
}

extension AnimeDatabaseQueryLinks
    on QueryBuilder<AnimeDatabase, AnimeDatabase, QFilterCondition> {}

extension AnimeDatabaseQuerySortBy
    on QueryBuilder<AnimeDatabase, AnimeDatabase, QSortBy> {
  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterSortBy>
      sortByAnilistMeidaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anilistMeidaId', Sort.asc);
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterSortBy>
      sortByAnilistMeidaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anilistMeidaId', Sort.desc);
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterSortBy> sortByExtensionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionId', Sort.asc);
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterSortBy>
      sortByExtensionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionId', Sort.desc);
    });
  }
}

extension AnimeDatabaseQuerySortThenBy
    on QueryBuilder<AnimeDatabase, AnimeDatabase, QSortThenBy> {
  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterSortBy>
      thenByAnilistMeidaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anilistMeidaId', Sort.asc);
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterSortBy>
      thenByAnilistMeidaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anilistMeidaId', Sort.desc);
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterSortBy> thenByExtensionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionId', Sort.asc);
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterSortBy>
      thenByExtensionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionId', Sort.desc);
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension AnimeDatabaseQueryWhereDistinct
    on QueryBuilder<AnimeDatabase, AnimeDatabase, QDistinct> {
  QueryBuilder<AnimeDatabase, AnimeDatabase, QDistinct>
      distinctByAnilistMeidaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'anilistMeidaId');
    });
  }

  QueryBuilder<AnimeDatabase, AnimeDatabase, QDistinct>
      distinctByExtensionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'extensionId');
    });
  }
}

extension AnimeDatabaseQueryProperty
    on QueryBuilder<AnimeDatabase, AnimeDatabase, QQueryProperty> {
  QueryBuilder<AnimeDatabase, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AnimeDatabase, int?, QQueryOperations> anilistMeidaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'anilistMeidaId');
    });
  }

  QueryBuilder<AnimeDatabase, int?, QQueryOperations> extensionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'extensionId');
    });
  }

  QueryBuilder<AnimeDatabase, MetiaAnime?, QQueryOperations>
      matchedAnimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchedAnime');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MetiaAnimeSchema = Schema(
  name: r'MetiaAnime',
  id: 1395422921283439939,
  properties: {
    r'length': PropertySchema(
      id: 0,
      name: r'length',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 1,
      name: r'name',
      type: IsarType.string,
    ),
    r'poster': PropertySchema(
      id: 2,
      name: r'poster',
      type: IsarType.string,
    ),
    r'url': PropertySchema(
      id: 3,
      name: r'url',
      type: IsarType.string,
    )
  },
  estimateSize: _metiaAnimeEstimateSize,
  serialize: _metiaAnimeSerialize,
  deserialize: _metiaAnimeDeserialize,
  deserializeProp: _metiaAnimeDeserializeProp,
);

int _metiaAnimeEstimateSize(
  MetiaAnime object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.poster.length * 3;
  bytesCount += 3 + object.url.length * 3;
  return bytesCount;
}

void _metiaAnimeSerialize(
  MetiaAnime object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.length);
  writer.writeString(offsets[1], object.name);
  writer.writeString(offsets[2], object.poster);
  writer.writeString(offsets[3], object.url);
}

MetiaAnime _metiaAnimeDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MetiaAnime();
  object.length = reader.readLong(offsets[0]);
  object.name = reader.readString(offsets[1]);
  object.poster = reader.readString(offsets[2]);
  object.url = reader.readString(offsets[3]);
  return object;
}

P _metiaAnimeDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MetiaAnimeQueryFilter
    on QueryBuilder<MetiaAnime, MetiaAnime, QFilterCondition> {
  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> lengthEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'length',
        value: value,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> lengthGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'length',
        value: value,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> lengthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'length',
        value: value,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> lengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'length',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> posterEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'poster',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> posterGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'poster',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> posterLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'poster',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> posterBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'poster',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> posterStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'poster',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> posterEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'poster',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> posterContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'poster',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> posterMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'poster',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> posterIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'poster',
        value: '',
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition>
      posterIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'poster',
        value: '',
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> urlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> urlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> urlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> urlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'url',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> urlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> urlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'url',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<MetiaAnime, MetiaAnime, QAfterFilterCondition> urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'url',
        value: '',
      ));
    });
  }
}

extension MetiaAnimeQueryObject
    on QueryBuilder<MetiaAnime, MetiaAnime, QFilterCondition> {}
