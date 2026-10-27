class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.birthDate,
    required this.gender,
    this.avatarUrl,
    this.phone = '',
    this.instagram = '',
    this.telegram = '',
    this.contactUrl = '',
    this.isOrganizer = false,
    this.sports = const ['football'],
  });

  final String id;
  final String username;
  final String fullName;
  final DateTime? birthDate;
  final String gender;
  final String? avatarUrl;

  /// International phone number, e.g. `5491122334455` (no `+`).
  /// Used for WhatsApp contact between players and organizers.
  final String phone;

  /// Instagram handle without the `@` or the profile URL.
  final String instagram;

  /// Telegram username without the `@`.
  final String telegram;

  /// Any other way to reach this person or sign up: a Google Form, a club
  /// site, a spreadsheet. Stored with its scheme (`https://…`).
  final String contactUrl;
  final bool isOrganizer;
  final List<String> sports;

  bool get isComplete => username.isNotEmpty && birthDate != null;

  /// Phone is the baseline every player has; the other channels are extras.
  bool get canBeContacted => phone.isNotEmpty;

  /// True when there is any way at all to reach this person, phone or not.
  bool get hasContactChannels =>
      phone.isNotEmpty ||
      instagram.isNotEmpty ||
      telegram.isNotEmpty ||
      contactUrl.isNotEmpty;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String? ?? '',
      instagram: json['instagram'] as String? ?? '',
      telegram: json['telegram'] as String? ?? '',
      contactUrl: json['contact_url'] as String? ?? '',
      isOrganizer: json['is_organizer'] as bool? ?? false,
      // `birth_date` is a Postgres `date`: keep the calendar date — parsing
      // a midnight ISO and converting to local would shift the day.
      birthDate: json['birth_date'] == null
          ? null
          : _dateOnly(json['birth_date'] as String),
      sports: (json['sports'] as List?)?.cast<String>() ?? const ['football'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'gender': gender,
      'avatar_url': avatarUrl,
      'phone': phone,
      'instagram': instagram,
      'telegram': telegram,
      'contact_url': contactUrl,
      'is_organizer': isOrganizer,
      'birth_date': birthDate?.toIso8601String(),
      'sports': sports,
    };
  }

  UserModel copyWith({
    String? username,
    String? fullName,
    // Closure pattern (see TournamentQuery.copyWith): plain nullable params
    // can't express "reset to null" — `birthDate: () => null` clears it.
    DateTime? Function()? birthDate,
    String? gender,
    String? Function()? avatarUrl,
    String? phone,
    String? instagram,
    String? telegram,
    String? contactUrl,
    bool? isOrganizer,
    List<String>? sports,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      birthDate: birthDate != null ? birthDate() : this.birthDate,
      avatarUrl: avatarUrl != null ? avatarUrl() : this.avatarUrl,
      phone: phone ?? this.phone,
      instagram: instagram ?? this.instagram,
      telegram: telegram ?? this.telegram,
      contactUrl: contactUrl ?? this.contactUrl,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      sports: sports ?? this.sports,
    );
  }
}

/// Parses a date-only string (`1990-05-04`) into a local calendar date;
/// full ISO timestamps keep their date part.
DateTime? _dateOnly(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}
