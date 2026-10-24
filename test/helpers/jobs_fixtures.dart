/// Public job postings as the API returns them, for the jobs tests.
String daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).toUtc().toIso8601String();

String daysAhead(int days) =>
    DateTime.now().add(Duration(days: days)).toUtc().toIso8601String();

Map<String, dynamic> jobJson(
  String id,
  String title, {
  String company = 'Nimbus Pay',
  String? location = 'Ha Noi',
  String? type = 'Full-time',
  String? level = 'Senior',
  num? min = 45000000,
  num? max = 60000000,
  bool negotiable = false,
  String currency = 'VND',
  String? description,
  String? requirements,
  String? createdAt,
  String? expiresAt,
}) => {
  'id': id,
  'enterpriseId': 'e-$company',
  'enterprise': {'id': 'e-$company', 'name': company, 'logoUrl': null},
  'title': title,
  'location': location,
  'employmentType': type,
  'level': level,
  'salaryMin': min,
  'salaryMax': max,
  'salaryNegotiable': negotiable,
  'currency': currency,
  'description': description,
  'requirements': requirements,
  'openings': 2,
  'createdAt': createdAt ?? daysAgo(3),
  'expiresAt': expiresAt ?? daysAhead(20),
};

Map<String, dynamic> jobsPage(
  List<Map<String, dynamic>> items, {
  int page = 1,
  int totalPages = 1,
  int? total,
}) => {
  'items': items,
  'page': page,
  'limit': 100,
  'total': total ?? items.length,
  'totalPages': totalPages,
};
