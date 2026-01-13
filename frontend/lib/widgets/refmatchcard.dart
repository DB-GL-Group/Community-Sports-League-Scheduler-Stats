import 'package:community_sports_league_scheduler/object_models.dart' as om;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RefMatchCard extends StatelessWidget {
  final om.RefMatch match;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool showScore;

  const RefMatchCard({
    super.key,
    required this.match,
    required this.onAccept,
    required this.onDecline,
    this.showScore = false,
  });

  bool get _isFinished {
    return match.status == 'Accepted' && DateTime.now().isAfter(match.endTime);
  }

  bool get _canRespond {
    final now = DateTime.now();
    final difference = match.startTime.difference(now);
    return match.status == 'Pending' && difference.inHours <= 24 && now.isBefore(match.startTime);
  }

  bool get _isLocked {
    final now = DateTime.now();
    final difference = match.startTime.difference(now);
    return difference.inHours <= 24 && now.isBefore(match.startTime);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Postponed':
        return Colors.red;
      case 'Finished':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final timeFormat = DateFormat.Hm();
    final displayStatus = _isFinished ? 'Finished' : match.status;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teams
            Text(
              '${match.home_team} vs ${match.away_team}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (showScore && match.homeScore != null && match.awayScore != null) ...[
              const SizedBox(height: 4),
              Text(
                '${match.homeScore} - ${match.awayScore}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],

            const SizedBox(height: 8),

            // Time
            Text(
              '${timeFormat.format(match.startTime)} – ${timeFormat.format(match.endTime)}',
              style: const TextStyle(fontSize: 14),
            ),

            // Date & venue
            Text(
              '${dateFormat.format(match.startTime)} · ${match.venue}',
              style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.6)),
            ),

            const SizedBox(height: 12),

            // Status + actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(displayStatus),
                  backgroundColor: _statusColor(displayStatus).withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: _statusColor(displayStatus)),
                ),

                if (_isLocked)
                  Icon(
                    Icons.lock,
                    size: 20,
                    color: onSurface.withOpacity(0.55),
                  ),

                if (_canRespond)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'accept') onAccept?.call();
                      if (value == 'decline') onDecline?.call();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'accept', child: Text('Accept')),
                      const PopupMenuItem(value: 'decline', child: Text('Decline')),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
