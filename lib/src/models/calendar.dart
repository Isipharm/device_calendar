/// A calendar on the user's device
class Calendar {
  /// Read-only. The unique identifier for this calendar
  String? id;

  /// The name of this calendar
  String? name;

  /// Read-only. If the calendar is read-only
  bool? isReadOnly;

  /// Read-only. If the calendar is the default
  bool? isDefault;

  /// Read-only. Color of the calendar
  int? color;

  // Read-only. Account name associated with the calendar
  String? accountName;

  // Read-only. Account type associated with the calendar
  String? accountType;

  Calendar(
      {this.id,
      this.name,
      this.isReadOnly,
      this.isDefault,
      this.color,
      this.accountName,
      this.accountType});

  Calendar.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isReadOnly = json['isReadOnly'];
    isDefault = json['isDefault'];
    color = json['color'];
    accountName = json['accountName'];
    accountType = json['accountType'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'isReadOnly': isReadOnly,
      'isDefault': isDefault,
      'color': color,
      'accountName': accountName,
      'accountType': accountType
    };

    return data;
  }

  @override
  bool operator ==(covariant Calendar other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.isReadOnly == isReadOnly &&
        other.isDefault == isDefault &&
        other.color == color &&
        other.accountName == accountName &&
        other.accountType == accountType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        isReadOnly.hashCode ^
        isDefault.hashCode ^
        color.hashCode ^
        accountName.hashCode ^
        accountType.hashCode;
  }
}
