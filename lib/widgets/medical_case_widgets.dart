import 'package:flutter/material.dart';

/// Row of status chips for medical cases
class CaseStatusChipRow extends StatelessWidget {
  final String status;
  final String category;
  final bool sentToOperator;

  const CaseStatusChipRow({
    super.key,
    required this.status,
    required this.category,
    this.sentToOperator = false, required bool escalationScheduled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusChip(
          label: status.toUpperCase(),
          color: _getStatusColor(status),
          icon: _getStatusIcon(status),
          isCompact: true,
        ),
        const SizedBox(height: 2),
        _StatusChip(
          label: category.toUpperCase(),
          color: _getCategoryColor(category),
          icon: _getCategoryIcon(category),
          isCompact: true,
        ),
        if (sentToOperator) ...[
          const SizedBox(height: 2),
          const _StatusChip(
            label: 'OPR',
            color: Colors.purple,
            icon: Icons.person,
            isCompact: true,
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'accepted':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.blue;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'serious':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'ordinary':
      default:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'accepted':
        return Icons.local_hospital;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'serious':
        return Icons.priority_high;
      case 'moderate':
        return Icons.warning;
      case 'ordinary':
      default:
        return Icons.info;
    }
  }
}

/// Individual status chip widget
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isCompact;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: Colors.white),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Hospital card widget with skeleton loading state
class HospitalCard extends StatelessWidget {
  final String? hospitalId;
  final String? hospitalName;
  final bool isLoading;

  const HospitalCard({
    super.key,
    this.hospitalId,
    this.hospitalName,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_hospital, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(width: 120),
                  SizedBox(height: 4),
                  _SkeletonLine(width: 80),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (hospitalId == null || hospitalName == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.local_hospital, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Waiting for hospital assignment...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_hospital, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospitalName!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'ID: $hospitalId',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Driver card widget with skeleton loading state
class DriverCard extends StatelessWidget {
  final String? driverId;
  final String? driverName;
  final String? driverUnitId;
  final bool isLoading;

  const DriverCard({
    super.key,
    this.driverId,
    this.driverName,
    this.driverUnitId,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_shipping, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(width: 100),
                  SizedBox(height: 4),
                  _SkeletonLine(width: 70),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (driverId == null || driverName == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.local_shipping, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Waiting for driver assignment...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                Row(
                  children: [
                    if (driverUnitId != null) ...[
                      Text(
                        'Unit: $driverUnitId',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const Text(' • ', style: TextStyle(color: Colors.orange)),
                    ],
                    Text(
                      'ID: $driverId',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading line for loading states
class _SkeletonLine extends StatelessWidget {
  final double width;

  const _SkeletonLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// AI Advice card for completed cases
class AiAdviceCard extends StatelessWidget {
  final String? aiAdvice;

  const AiAdviceCard({super.key, this.aiAdvice});

  @override
  Widget build(BuildContext context) {
    if (aiAdvice == null || aiAdvice!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Medical Advice',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aiAdvice!,
                  style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
