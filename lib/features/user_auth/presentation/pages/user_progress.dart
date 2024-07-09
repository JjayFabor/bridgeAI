class Lesson {
  final String title;
  final int score;
  final String timestamp;

  Lesson({
    required this.title,
    required this.score,
    required this.timestamp,
  });
}

class Topic {
  final String name;
  final List<Lesson> lessons;

  Topic({
    required this.name,
    required this.lessons,
  });
}

class Subject {
  final String name;
  final List<Topic> topics;

  Subject({
    required this.name,
    required this.topics,
  });
}

class UserProgress {
  final String userId;
  final List<Subject> subjects;

  UserProgress({
    required this.userId,
    required this.subjects,
  });
}
