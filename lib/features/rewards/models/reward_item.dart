class RewardItem {
  const RewardItem({
    required this.code,
    required this.title,
    required this.pointsCost,
    required this.description,
  });

  final String code;
  final String title;
  final int pointsCost;
  final String description;
}

/// Каталог наград кампуса (MVP).
const kCampusRewards = <RewardItem>[
  RewardItem(
    code: 'campus_coffee',
    title: 'Кофе в кампусе',
    pointsCost: 100,
    description: 'Бесплатный напиток в партнёрской точке',
  ),
  RewardItem(
    code: 'eco_bag',
    title: 'Эко-сумка',
    pointsCost: 200,
    description: 'Многоразовая сумка из переработанных материалов',
  ),
  RewardItem(
    code: 'canteen_10',
    title: 'Скидка 10% в столовой',
    pointsCost: 350,
    description: 'Одноразовая скидка при предъявлении кода',
  ),
  RewardItem(
    code: 'uni_merch',
    title: 'Мерч университета',
    pointsCost: 500,
    description: 'Значок или стикерпак эко-клуба',
  ),
];