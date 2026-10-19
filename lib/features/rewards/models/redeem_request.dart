class RedeemRequest {
  const RedeemRequest({
    required this.id,
    required this.rewardTitle,
    required this.pointsCost,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String rewardTitle;
  final int pointsCost;
  final String status;
  final DateTime createdAt;

  String get statusRu => switch (status) {
        'approved' => 'Одобрено',
        'rejected' => 'Отклонено',
        'fulfilled' => 'Выдано',
        _ => 'В обработке',
      };

  factory RedeemRequest.fromJson(Map<String, dynamic> json) {
    return RedeemRequest(
      id: json['id'] as String,
      rewardTitle: json['reward_title'] as String? ?? 'Награда',
      pointsCost: (json['points_cost'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}