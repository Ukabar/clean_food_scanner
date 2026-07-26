enum AdditiveConcernLevel { low, moderate, high, unknown }

class AdditiveConcern {
  const AdditiveConcern(this.code, this.level, this.note);

  final String code;
  final AdditiveConcernLevel level;
  final String note;
}

class AdditiveConcernDatabase {
  const AdditiveConcernDatabase();

  static const _items = {
    'e100': AdditiveConcern(
      'E100',
      AdditiveConcernLevel.low,
      'Common color additive.',
    ),
    'e202': AdditiveConcern(
      'E202',
      AdditiveConcernLevel.low,
      'Common preservative.',
    ),
    'e250': AdditiveConcern(
      'E250',
      AdditiveConcernLevel.moderate,
      'Often used in cured products.',
    ),
    'e621': AdditiveConcern(
      'E621',
      AdditiveConcernLevel.moderate,
      'Flavor enhancer.',
    ),
    'e951': AdditiveConcern(
      'E951',
      AdditiveConcernLevel.moderate,
      'Sweetener; verify packaging if sensitive.',
    ),
  };

  AdditiveConcern lookup(String tag) {
    final code = tag.toLowerCase().split(':').last.replaceAll('-', '');
    return _items[code] ??
        AdditiveConcern(
          tag.toUpperCase(),
          AdditiveConcernLevel.unknown,
          'No local concern note available.',
        );
  }
}
