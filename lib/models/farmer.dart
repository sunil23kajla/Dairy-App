class Farmer {
  final String id;
  final String dairyCode;
  final String name;
  final String nickname;
  final String mobile;
  final double lastLiters;

  const Farmer({
    required this.id,
    required this.dairyCode,
    required this.name,
    required this.nickname,
    required this.mobile,
    this.lastLiters = 0.0,
  });

  Farmer copyWith({
    String? id,
    String? dairyCode,
    String? name,
    String? nickname,
    String? mobile,
    double? lastLiters,
  }) {
    return Farmer(
      id: id ?? this.id,
      dairyCode: dairyCode ?? this.dairyCode,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      mobile: mobile ?? this.mobile,
      lastLiters: lastLiters ?? this.lastLiters,
    );
  }
}
