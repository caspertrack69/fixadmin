import '../../../core/utils/json_parsers.dart';

class Category {
  const Category({required this.id, required this.name, required this.models});

  final int id;
  final String name;
  final List<DeviceModel> models;

  factory Category.fromJson(Map<String, dynamic> json) {
    final rawModels = json['models'] as List? ?? const [];
    return Category(
      id: parseInt(json['id']),
      name: parseString(json['name']),
      models: rawModels
          .whereType<Map>()
          .map(
            (item) => DeviceModel.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .toList(),
    );
  }

  Category copyWith({List<DeviceModel>? models}) {
    return Category(id: id, name: name, models: models ?? this.models);
  }
}

class DeviceModel {
  const DeviceModel({
    required this.id,
    required this.name,
    required this.parts,
  });

  final int id;
  final String name;
  final List<Part> parts;

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    final rawParts = json['parts'] as List? ?? const [];
    return DeviceModel(
      id: parseInt(json['id']),
      name: parseString(json['name']),
      parts: rawParts
          .whereType<Map>()
          .map(
            (item) => Part.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .toList(),
    );
  }

  DeviceModel copyWith({List<Part>? parts}) {
    return DeviceModel(id: id, name: name, parts: parts ?? this.parts);
  }
}

class Part {
  const Part({required this.id, required this.name, required this.variants});

  final int id;
  final String name;
  final List<Variant> variants;

  factory Part.fromJson(Map<String, dynamic> json) {
    final rawVariants = json['variants'] as List? ?? const [];
    return Part(
      id: parseInt(json['id']),
      name: parseString(json['name']),
      variants: rawVariants
          .whereType<Map>()
          .map(
            (item) => Variant.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .toList(),
    );
  }

  Part copyWith({List<Variant>? variants}) {
    return Part(id: id, name: name, variants: variants ?? this.variants);
  }
}

class Variant {
  const Variant({
    required this.id,
    required this.name,
    required this.sellPrice,
    required this.currentStock,
    required this.minStock,
    this.photoUrl,
  });

  final int id;
  final String name;
  final int sellPrice;
  final int currentStock;
  final int minStock;
  final String? photoUrl;

  bool get inStock => currentStock > 0;

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: parseInt(json['id']),
      name: parseString(json['name']),
      sellPrice: parseInt(json['sell_price']),
      currentStock: parseInt(json['current_stock']),
      minStock: parseInt(json['min_stock']),
      photoUrl: json['photo_url'] == null
          ? null
          : parseString(json['photo_url']),
    );
  }
}
