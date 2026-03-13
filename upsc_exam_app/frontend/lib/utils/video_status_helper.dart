// Video Status Helper
// Calculates video status (Live/Recorded/Upcoming) based on IST timezone

class VideoStatusHelper {
  // Get video status based on scheduled time and duration
  // MongoDB stores in UTC, we need to compare with IST
  static VideoStatus getVideoStatus(
    DateTime? scheduledAt,
    int durationMinutes,
  ) {
    if (scheduledAt == null) {
      return VideoStatus.recorded;
    }

    // Get current local time
    final now = DateTime.now();

    // Convert scheduledAt (UTC from server) to local time for comparison
    final scheduledLocal =
        (scheduledAt.isUtc
                ? scheduledAt
                : DateTime.utc(
                    scheduledAt.year,
                    scheduledAt.month,
                    scheduledAt.day,
                    scheduledAt.hour,
                    scheduledAt.minute,
                    scheduledAt.second,
                  ))
            .toLocal();

    // Calculate when the class ends
    final classEndTime = scheduledLocal.add(Duration(minutes: durationMinutes));

    // If current time is before scheduled time - Upcoming
    if (now.isBefore(scheduledLocal)) {
      return VideoStatus.upcoming;
    }

    // If current time is after class end time - Recorded
    if (now.isAfter(classEndTime)) {
      return VideoStatus.recorded;
    }

    // If current time is between scheduled and end time - Live
    return VideoStatus.live;
  }

  // Get status color
  static String getStatusColor(VideoStatus status) {
    switch (status) {
      case VideoStatus.live:
        return '#FF0000'; // Red
      case VideoStatus.upcoming:
        return '#FFA500'; // Orange
      case VideoStatus.recorded:
        return '#808080'; // Gray
    }
  }

  // Get status text
  static String getStatusText(VideoStatus status) {
    switch (status) {
      case VideoStatus.live:
        return 'LIVE';
      case VideoStatus.upcoming:
        return 'UPCOMING';
      case VideoStatus.recorded:
        return 'RECORDED';
    }
  }
}

enum VideoStatus { live, upcoming, recorded }
