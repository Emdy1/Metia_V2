// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_history_instance.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEpisodeHistoryInstanceCollection on Isar {
  IsarCollection<EpisodeHistoryInstance> get episodeHistoryInstances =>
      this.collection();
}

const EpisodeHistoryInstanceSchema = CollectionSchema(
  name: r'EpisodeHistoryInstance',
  id: 3651302419984739329,
  properties: {
    r'anilistMediaId': PropertySchema(
      id: 0,
      name: r'anilistMediaId',
      type: IsarType.long,
    ),
    r'anime': PropertySchema(
      id: 1,
      name: r'anime',
      type: IsarType.object,
      target: r'MetiaAnime',
    ),
    r'episode': PropertySchema(
      id: 2,
      name: r'episode',
      type: IsarType.object,
      target: r'MetiaEpisode',
    ),
    r'episodeNumber': PropertySchema(
      id: 3,
      name: r'episodeNumber',
      type: IsarType.long,
    ),
    r'extensionId': PropertySchema(
      id: 4,
      name: r'extensionId',
      type: IsarType.long,
    ),
    r'lastModified': PropertySchema(
      id: 5,
      name: r'lastModified',
      type: IsarType.dateTime,
    ),
    r'parentList': PropertySchema(
      id: 6,
      name: r'parentList',
      type: IsarType.objectList,
      target: r'MetiaEpisode',
    ),
    r'seen': PropertySchema(
      id: 7,
      name: r'seen',
      type: IsarType.bool,
    ),
    r'title': PropertySchema(
      id: 8,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _episodeHistoryInstanceEstimateSize,
  serialize: _episodeHistoryInstanceSerialize,
  deserialize: _episodeHistoryInstanceDeserialize,
  deserializeProp: _episodeHistoryInstanceDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {
    r'MetiaEpisode': MetiaEpisodeSchema,
    r'MetiaAnime': MetiaAnimeSchema
  },
  getId: _episodeHistoryInstanceGetId,
  getLinks: _episodeHistoryInstanceGetLinks,
  attach: _episodeHistoryInstanceAttach,
  version: '3.1.0+1',
);

int _episodeHistoryInstanceEstimateSize(
  EpisodeHistoryInstance object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.anime;
    if (value != null) {
      bytesCount += 3 +
          MetiaAnimeSchema.estimateSize(
              value, allOffsets[MetiaAnime]!, allOffsets);
    }
  }
  {
    final value = object.episode;
    if (value != null) {
      bytesCount += 3 +
          MetiaEpisodeSchema.estimateSize(
              value, allOffsets[MetiaEpisode]!, allOffsets);
    }
  }
  {
    final list = object.parentList;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[MetiaEpisode]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              MetiaEpisodeSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final value = object.title;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _episodeHistoryInstanceSerialize(
  EpisodeHistoryInstance object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.anilistMediaId);
  writer.writeObject<MetiaAnime>(
    offsets[1],
    allOffsets,
    MetiaAnimeSchema.serialize,
    object.anime,
  );
  writer.writeObject<MetiaEpisode>(
    offsets[2],
    allOffsets,
    MetiaEpisodeSchema.serialize,
    object.episode,
  );
  writer.writeLong(offsets[3], object.episodeNumber);
  writer.writeLong(offsets[4], object.extensionId);
  writer.writeDateTime(offsets[5], object.lastModified);
  writer.writeObjectList<MetiaEpisode>(
    offsets[6],
    allOffsets,
    MetiaEpisodeSchema.serialize,
    object.parentList,
  );
  writer.writeBool(offsets[7], object.seen);
  writer.writeString(offsets[8], object.title);
}

EpisodeHistoryInstance _episodeHistoryInstanceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EpisodeHistoryInstance();
  object.anilistMediaId = reader.readLongOrNull(offsets[0]);
  object.anime = reader.readObjectOrNull<MetiaAnime>(
    offsets[1],
    MetiaAnimeSchema.deserialize,
    allOffsets,
  );
  object.episode = reader.readObjectOrNull<MetiaEpisode>(
    offsets[2],
    MetiaEpisodeSchema.deserialize,
    allOffsets,
  );
  object.episodeNumber = reader.readLongOrNull(offsets[3]);
  object.extensionId = reader.readLongOrNull(offsets[4]);
  object.id = id;
  object.lastModified = reader.readDateTimeOrNull(offsets[5]);
  object.parentList = reader.readObjectList<MetiaEpisode>(
    offsets[6],
    MetiaEpisodeSchema.deserialize,
    allOffsets,
    MetiaEpisode(),
  );
  object.seen = reader.readBoolOrNull(offsets[7]);
  object.title = reader.readStringOrNull(offsets[8]);
  return object;
}

P _episodeHistoryInstanceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readObjectOrNull<MetiaAnime>(
        offset,
        MetiaAnimeSchema.deserialize,
        allOffsets,
      )) as P;
    case 2:
      return (reader.readObjectOrNull<MetiaEpisode>(
        offset,
        MetiaEpisodeSchema.deserialize,
        allOffsets,
      )) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readObjectList<MetiaEpisode>(
        offset,
        MetiaEpisodeSchema.deserialize,
        allOffsets,
        MetiaEpisode(),
      )) as P;
    case 7:
      return (reader.readBoolOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _episodeHistoryInstanceGetId(EpisodeHistoryInstance object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _episodeHistoryInstanceGetLinks(
    EpisodeHistoryInstance object) {
  return [];
}

void _episodeHistoryInstanceAttach(
    IsarCollection<dynamic> col, Id id, EpisodeHistoryInstance object) {
  object.id = id;
}

extension EpisodeHistoryInstanceQueryWhereSort
    on QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QWhere> {
  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension EpisodeHistoryInstanceQueryWhere on QueryBuilder<
    EpisodeHistoryInstance, EpisodeHistoryInstance, QWhereClause> {
  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterWhereClause> idBetween(
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

extension EpisodeHistoryInstanceQueryFilter on QueryBuilder<
    EpisodeHistoryInstance, EpisodeHistoryInstance, QFilterCondition> {
  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> anilistMediaIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'anilistMediaId',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> anilistMediaIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'anilistMediaId',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> anilistMediaIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'anilistMediaId',
        value: value,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> anilistMediaIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'anilistMediaId',
        value: value,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> anilistMediaIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'anilistMediaId',
        value: value,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> anilistMediaIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'anilistMediaId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> animeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'anime',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> animeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'anime',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> episodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'episode',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> episodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'episode',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> episodeNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'episodeNumber',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> episodeNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'episodeNumber',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> episodeNumberEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'episodeNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> episodeNumberGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'episodeNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> episodeNumberLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'episodeNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> episodeNumberBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'episodeNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> extensionIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'extensionId',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> extensionIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'extensionId',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> extensionIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'extensionId',
        value: value,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> extensionIdGreaterThan(
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

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> extensionIdLessThan(
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

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> extensionIdBetween(
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

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> lastModifiedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastModified',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> lastModifiedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastModified',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> lastModifiedEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastModified',
        value: value,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> lastModifiedGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastModified',
        value: value,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> lastModifiedLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastModified',
        value: value,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> lastModifiedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastModified',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> parentListIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parentList',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> parentListIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parentList',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> parentListLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'parentList',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> parentListIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'parentList',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> parentListIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'parentList',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> parentListLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'parentList',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> parentListLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'parentList',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> parentListLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'parentList',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> seenIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'seen',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> seenIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'seen',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> seenEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seen',
        value: value,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'title',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> titleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> titleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> titleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> titleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
          QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
          QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension EpisodeHistoryInstanceQueryObject on QueryBuilder<
    EpisodeHistoryInstance, EpisodeHistoryInstance, QFilterCondition> {
  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> anime(FilterQuery<MetiaAnime> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'anime');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> episode(FilterQuery<MetiaEpisode> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'episode');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance,
      QAfterFilterCondition> parentListElement(FilterQuery<MetiaEpisode> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'parentList');
    });
  }
}

extension EpisodeHistoryInstanceQueryLinks on QueryBuilder<
    EpisodeHistoryInstance, EpisodeHistoryInstance, QFilterCondition> {}

extension EpisodeHistoryInstanceQuerySortBy
    on QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QSortBy> {
  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      sortByAnilistMediaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anilistMediaId', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      sortByAnilistMediaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anilistMediaId', Sort.desc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      sortByEpisodeNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeNumber', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      sortByEpisodeNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeNumber', Sort.desc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      sortByExtensionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionId', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      sortByExtensionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionId', Sort.desc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      sortByLastModified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModified', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      sortByLastModifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModified', Sort.desc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      sortBySeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seen', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      sortBySeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seen', Sort.desc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension EpisodeHistoryInstanceQuerySortThenBy on QueryBuilder<
    EpisodeHistoryInstance, EpisodeHistoryInstance, QSortThenBy> {
  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenByAnilistMediaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anilistMediaId', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenByAnilistMediaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anilistMediaId', Sort.desc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenByEpisodeNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeNumber', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenByEpisodeNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeNumber', Sort.desc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenByExtensionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionId', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenByExtensionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extensionId', Sort.desc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenByLastModified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModified', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenByLastModifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModified', Sort.desc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenBySeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seen', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenBySeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seen', Sort.desc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension EpisodeHistoryInstanceQueryWhereDistinct
    on QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QDistinct> {
  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QDistinct>
      distinctByAnilistMediaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'anilistMediaId');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QDistinct>
      distinctByEpisodeNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'episodeNumber');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QDistinct>
      distinctByExtensionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'extensionId');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QDistinct>
      distinctByLastModified() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModified');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QDistinct>
      distinctBySeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seen');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, EpisodeHistoryInstance, QDistinct>
      distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension EpisodeHistoryInstanceQueryProperty on QueryBuilder<
    EpisodeHistoryInstance, EpisodeHistoryInstance, QQueryProperty> {
  QueryBuilder<EpisodeHistoryInstance, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, int?, QQueryOperations>
      anilistMediaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'anilistMediaId');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, MetiaAnime?, QQueryOperations>
      animeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'anime');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, MetiaEpisode?, QQueryOperations>
      episodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'episode');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, int?, QQueryOperations>
      episodeNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'episodeNumber');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, int?, QQueryOperations>
      extensionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'extensionId');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, DateTime?, QQueryOperations>
      lastModifiedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModified');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, List<MetiaEpisode>?, QQueryOperations>
      parentListProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentList');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, bool?, QQueryOperations> seenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seen');
    });
  }

  QueryBuilder<EpisodeHistoryInstance, String?, QQueryOperations>
      titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
