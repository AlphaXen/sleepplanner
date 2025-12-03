class EnvSample {
  final DateTime time;
  final double lux;
  final double noiseDb;

  EnvSample(this.time, this.lux, this.noiseDb);

  Map<String, dynamic> toJson() => {
        "t": time.millisecondsSinceEpoch,
        "lux": lux,
        "db": noiseDb,
      };

  static EnvSample fromJson(Map<String, dynamic> m) {
    return EnvSample(
      DateTime.fromMillisecondsSinceEpoch(m["t"]),
      (m["lux"] as num).toDouble(),
      (m["db"] as num).toDouble(),
    );
  }
}
