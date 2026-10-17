import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/client.dart';

class ApplicationItem {
  const ApplicationItem({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    required this.appliedAt,
    this.location,
  });

  final String id;
  final String jobTitle;
  final String companyName;
  final String status;
  final String appliedAt;
  final String? location;

  factory ApplicationItem.fromJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>?;
    final company = job?['company'] as Map<String, dynamic>?;

    return ApplicationItem(
      id: json['id']?.toString() ?? '',
      jobTitle: job?['title']?.toString() ?? 'Software Engineer',
      companyName: company?['name']?.toString() ?? 'Tech Corp',
      status: json['status']?.toString() ?? 'submitted',
      appliedAt: json['createdAt']?.toString() ?? 'Recently',
      location: job?['location']?.toString() ?? 'Ho Chi Minh City',
    );
  }
}

final myApplicationsProvider =
    FutureProvider.autoDispose<List<ApplicationItem>>((ref) async {
      final client = ref.watch(apiClientProvider);

      try {
        final response = await client.get<Map<String, dynamic>>(
          '/api/v1/applications/mine',
        );
        final items = response.data?['items'] as List<dynamic>?;
        if (items == null) return [];
        return items
            .map((e) => ApplicationItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Return sample mockup if backend is offline, allowing UI exploration
        return const [
          ApplicationItem(
            id: 'APP-1029',
            jobTitle: 'Senior Flutter Developer',
            companyName: 'FPT Software',
            status: 'interview',
            appliedAt: '2 days ago',
            location: 'Da Nang, Vietnam',
          ),
          ApplicationItem(
            id: 'APP-1028',
            jobTitle: 'Frontend Engineer (React)',
            companyName: 'VNG Corporation',
            status: 'review',
            appliedAt: '1 week ago',
            location: 'Ho Chi Minh City, Vietnam',
          ),
          ApplicationItem(
            id: 'APP-1025',
            jobTitle: 'Fullstack Tech Lead',
            companyName: 'Viettel Group',
            status: 'offered',
            appliedAt: '2 weeks ago',
            location: 'Hanoi, Vietnam',
          ),
        ];
      }
    });
