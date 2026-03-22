// lib/models/exercise_model.dart

class ExerciseModel {
  final String name;
  final String muscleGroup;
  final int sets;
  final String reps;
  final int restSeconds;
  final int estimatedCalories;
  final String difficulty; // "beginner" | "intermediate" | "advanced"
  final String category; // "Cardio" | "Strength" | "Flexibility"
  final String? imageUrl;
  final String? videoUrl;
  final String? youtubeVideoId;
  final String? thumbnailUrl;
  final String? videoDuration;
  final List<String> instructions;

  const ExerciseModel({
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.estimatedCalories,
    required this.difficulty,
    required this.category,
    this.imageUrl,
    this.videoUrl,
    this.youtubeVideoId,
    this.thumbnailUrl,
    this.videoDuration,
    this.instructions = const [],
  });

  String get setsDisplay => '$sets';
  String get repsDisplay => reps;
  String get restDisplay => restSeconds >= 60
      ? '${restSeconds ~/ 60}m ${restSeconds % 60 == 0 ? '' : '${restSeconds % 60}s'}'.trim()
      : '${restSeconds}s';
  String get caloriesDisplay => '$estimatedCalories';

  String? get youtubeThumbnail => youtubeVideoId != null
      ? 'https://img.youtube.com/vi/$youtubeVideoId/hqdefault.jpg'
      : null;
}

/// Factory helpers keyed by exercise name
ExerciseModel exerciseFromName(String name) {
  final n = name.toLowerCase();

  // Cardio
  if (n.contains('cycling') || n.contains('cycle')) {
    return ExerciseModel(name: name, muscleGroup: 'Full Body', sets: 1, reps: '20 min', restSeconds: 60, estimatedCalories: 220, difficulty: 'beginner', category: 'Cardio', youtubeVideoId: 'ENpJPlmO-Lk', videoDuration: '8:22');
  }
  if (n.contains('running') || n.contains('run')) {
    return ExerciseModel(name: name, muscleGroup: 'Legs', sets: 1, reps: '10 min', restSeconds: 60, estimatedCalories: 150, difficulty: 'intermediate', category: 'Cardio', youtubeVideoId: 'wRhMoNQjHC0', videoDuration: '5:15');
  }
  if (n.contains('swimming')) {
    return ExerciseModel(name: name, muscleGroup: 'Full Body', sets: 1, reps: '10 min', restSeconds: 60, estimatedCalories: 180, difficulty: 'intermediate', category: 'Cardio', youtubeVideoId: 'zh4NiPEClOg', videoDuration: '6:42');
  }
  if (n.contains('jumping')) {
    return ExerciseModel(name: name, muscleGroup: 'Legs', sets: 3, reps: '30 jumps', restSeconds: 45, estimatedCalories: 80, difficulty: 'beginner', category: 'Cardio', youtubeVideoId: 'ibuTDG09eqc', videoDuration: '3:54');
  }
  if (n.contains('bicycle')) {
    return ExerciseModel(name: name, muscleGroup: 'Abs', sets: 3, reps: '20 reps', restSeconds: 30, estimatedCalories: 60, difficulty: 'beginner', category: 'Cardio', youtubeVideoId: 'Iwyvozckjak', videoDuration: '3:12');
  }
  if (n.contains('mount climb') || n.contains('mountain')) {
    return ExerciseModel(name: name, muscleGroup: 'Full Body', sets: 3, reps: '30s', restSeconds: 30, estimatedCalories: 90, difficulty: 'intermediate', category: 'Cardio', youtubeVideoId: 'nmwgirgXLYM', videoDuration: '4:00');
  }

  // Back
  if (n.contains('pull up') || n.contains('pull-up')) {
    return ExerciseModel(name: name, muscleGroup: 'Back', sets: 4, reps: '10 reps', restSeconds: 60, estimatedCalories: 80, difficulty: 'intermediate', category: 'Strength');
  }
  if (n.contains('deadlift')) {
    return ExerciseModel(name: name, muscleGroup: 'Back & Hamstrings', sets: 4, reps: '8 reps', restSeconds: 120, estimatedCalories: 110, difficulty: 'advanced', category: 'Strength');
  }
  if (n.contains('lat pulldown')) {
    return ExerciseModel(name: name, muscleGroup: 'Lats', sets: 3, reps: '12 reps', restSeconds: 60, estimatedCalories: 70, difficulty: 'beginner', category: 'Strength');
  }

  // Chest
  if (n.contains('bench press')) {
    return ExerciseModel(name: name, muscleGroup: 'Chest', sets: 4, reps: '10 reps', restSeconds: 90, estimatedCalories: 95, difficulty: 'intermediate', category: 'Strength', youtubeVideoId: 'vcBig73ojpE', videoDuration: '4:45');
  }
  if (n.contains('incline press') || n.contains('incline')) {
    return ExerciseModel(name: name, muscleGroup: 'Upper Chest', sets: 3, reps: '10 reps', restSeconds: 90, estimatedCalories: 85, difficulty: 'intermediate', category: 'Strength', youtubeVideoId: 'DbFgADa2PL8', videoDuration: '3:30');
  }
  if (n.contains('decline press') || n.contains('decline')) {
    return ExerciseModel(name: name, muscleGroup: 'Lower Chest', sets: 3, reps: '10 reps', restSeconds: 90, estimatedCalories: 80, difficulty: 'intermediate', category: 'Strength', youtubeVideoId: '5JmWguyvu7Y', videoDuration: '3:10');
  }
  if (n.contains('push up') || n.contains('push-up')) {
    return ExerciseModel(name: name, muscleGroup: 'Chest', sets: 4, reps: '20 reps', restSeconds: 45, estimatedCalories: 70, difficulty: 'beginner', category: 'Strength', youtubeVideoId: 'IODxDxX7oi4', videoDuration: '3:45');
  }
  if (n.contains('dip')) {
    return ExerciseModel(name: name, muscleGroup: 'Chest & Triceps', sets: 3, reps: '12 reps', restSeconds: 60, estimatedCalories: 75, difficulty: 'intermediate', category: 'Strength', youtubeVideoId: 'yN6Q1UI_xkE', videoDuration: '3:52');
  }
  if (n.contains('pec deck') || n.contains('cable cross') || n.contains('dumbbell flyer')) {
    return ExerciseModel(name: name, muscleGroup: 'Chest', sets: 3, reps: '12 reps', restSeconds: 60, estimatedCalories: 65, difficulty: 'beginner', category: 'Strength', youtubeVideoId: 'Iwe6AmxVf7o', videoDuration: '3:00');
  }

  // Legs
  if (n.contains('squat')) {
    return ExerciseModel(name: name, muscleGroup: 'Quads & Glutes', sets: 4, reps: '8 reps', restSeconds: 120, estimatedCalories: 120, difficulty: 'intermediate', category: 'Strength', youtubeVideoId: 'aclHkVaku9U', videoDuration: '5:00');
  }
  if (n.contains('lunge')) {
    return ExerciseModel(name: name, muscleGroup: 'Legs', sets: 3, reps: '20 reps', restSeconds: 60, estimatedCalories: 90, difficulty: 'intermediate', category: 'Strength', youtubeVideoId: 'wrwwXE_x-pQ', videoDuration: '4:10');
  }
  if (n.contains('leg press')) {
    return ExerciseModel(name: name, muscleGroup: 'Quads', sets: 3, reps: '12 reps', restSeconds: 90, estimatedCalories: 100, difficulty: 'intermediate', category: 'Strength', youtubeVideoId: 'IZxyjW7MPJQ', videoDuration: '3:50');
  }
  if (n.contains('calf raise')) {
    return ExerciseModel(name: name, muscleGroup: 'Calves', sets: 4, reps: '20 reps', restSeconds: 45, estimatedCalories: 50, difficulty: 'beginner', category: 'Strength', youtubeVideoId: 'gwLzBJYoWlI', videoDuration: '3:15');
  }
  if (n.contains('leg curl')) {
    return ExerciseModel(name: name, muscleGroup: 'Hamstrings', sets: 3, reps: '15 reps', restSeconds: 60, estimatedCalories: 60, difficulty: 'beginner', category: 'Strength', youtubeVideoId: 'ELOCsoDSmrg', videoDuration: '3:30');
  }

  // Shoulders
  if (n.contains('military press') || n.contains('overhead')) {
    return ExerciseModel(name: name, muscleGroup: 'Shoulders', sets: 4, reps: '8 reps', restSeconds: 90, estimatedCalories: 85, difficulty: 'intermediate', category: 'Strength', youtubeVideoId: '2yjwXTZQDDI', videoDuration: '4:50');
  }
  if (n.contains('lateral raise') || n.contains('side raise')) {
    return ExerciseModel(name: name, muscleGroup: 'Side Delts', sets: 4, reps: '15 reps', restSeconds: 60, estimatedCalories: 55, difficulty: 'beginner', category: 'Strength', youtubeVideoId: 'kDqklk1ZESo', videoDuration: '3:20');
  }
  if (n.contains('arnold')) {
    return ExerciseModel(name: name, muscleGroup: 'Shoulders', sets: 3, reps: '10 reps', restSeconds: 75, estimatedCalories: 70, difficulty: 'intermediate', category: 'Strength', youtubeVideoId: 'T0HZXwM7UEQ', videoDuration: '3:45');
  }

  // Abs
  if (n.contains('crunch')) {
    return ExerciseModel(name: name, muscleGroup: 'Abs', sets: 4, reps: '20 reps', restSeconds: 30, estimatedCalories: 60, difficulty: 'beginner', category: 'Strength', youtubeVideoId: 'Xyd_fa5zoEU', videoDuration: '3:00');
  }
  if (n.contains('plank')) {
    return ExerciseModel(name: name, muscleGroup: 'Core', sets: 3, reps: '60s hold', restSeconds: 30, estimatedCalories: 55, difficulty: 'beginner', category: 'Strength', youtubeVideoId: 'pvIjsG5Svck', videoDuration: '3:15');
  }
  if (n.contains('leg raise')) {
    return ExerciseModel(name: name, muscleGroup: 'Lower Abs', sets: 3, reps: '15 reps', restSeconds: 45, estimatedCalories: 55, difficulty: 'beginner', category: 'Strength', youtubeVideoId: 'l4kQd9eWclE', videoDuration: '3:45');
  }
  if (n.contains('twist') || n.contains('russian')) {
    return ExerciseModel(name: name, muscleGroup: 'Obliques', sets: 3, reps: '20 reps', restSeconds: 30, estimatedCalories: 60, difficulty: 'beginner', category: 'Strength', youtubeVideoId: 'wkD8rjkodUI', videoDuration: '3:00');
  }

  // Forearms
  if (n.contains('wrist curl') || n.contains('wrist rotation')) {
    return ExerciseModel(name: name, muscleGroup: 'Forearms', sets: 4, reps: '15 reps', restSeconds: 45, estimatedCalories: 40, difficulty: 'beginner', category: 'Strength', youtubeVideoId: 'J81YNsb4qg4', videoDuration: '3:22');
  }
  if (n.contains('hammer curl')) {
    return ExerciseModel(name: name, muscleGroup: 'Biceps & Forearms', sets: 3, reps: '12 reps', restSeconds: 60, estimatedCalories: 55, difficulty: 'beginner', category: 'Strength', youtubeVideoId: 'zC3nLlEvin4', videoDuration: '3:10');
  }
  if (n.contains('farmer') || n.contains('dead hang') || n.contains('towel')) {
    return ExerciseModel(name: name, muscleGroup: 'Grip & Forearms', sets: 3, reps: '30s hold', restSeconds: 60, estimatedCalories: 50, difficulty: 'intermediate', category: 'Strength', youtubeVideoId: 'Jg0GxFMH7cU', videoDuration: '4:00');
  }

  // Stretching / flexibility
  if (n.contains('stretch')) {
    return ExerciseModel(name: name, muscleGroup: 'Full Body', sets: 1, reps: '10 min', restSeconds: 0, estimatedCalories: 40, difficulty: 'beginner', category: 'Flexibility', youtubeVideoId: 'sTxC3J3gQEU', videoDuration: '10:00');
  }

  // Default fallback
  return ExerciseModel(
    name: name,
    muscleGroup: 'Full Body',
    sets: 3,
    reps: '10 reps',
    restSeconds: 60,
    estimatedCalories: 80,
    difficulty: 'intermediate',
    category: 'Strength',
  );
}
