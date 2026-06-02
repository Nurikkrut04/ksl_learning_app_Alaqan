class RouteConstants {
  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Main Routes
  static const String home = '/home';
  static const String courses = '/courses';
  static const String profile = '/profile';
  static const String settings = '/settings';
  
  // Course Routes
  static const String courseDetail = '/course/:courseId';
  static const String topicDetail = '/course/:courseId/topic/:topicId';
  static const String lessonDetail = '/course/:courseId/topic/:topicId/lesson/:lessonId';
  
  // Quiz Routes
  static const String quiz = '/quiz/:quizId';
  static const String quizResult = '/quiz/:quizId/result';
  
  // Profile Routes
  static const String progress = '/progress';
  static const String achievements = '/achievements';
  static const String editProfile = '/profile/edit';
  
  // Dictionary
  static const String gestureDictionary = '/dictionary';
  static const String gestureDetail = '/dictionary/:gestureId';
  
  // Admin Routes
  static const String adminDashboard = '/admin';
  static const String manageCourses = '/admin/courses';
  static const String manageTopics = '/admin/topics';
  static const String manageLessons = '/admin/lessons';
  static const String manageUsers = '/admin/users';
  static const String addCourse = '/admin/courses/add';
  static const String editCourse = '/admin/courses/edit/:courseId';
  static const String addLesson = '/admin/lessons/add';
  static const String editLesson = '/admin/lessons/edit/:lessonId';
  
  // Helper method to build route with parameters
  static String buildRoute(String route, Map<String, String> params) {
    String result = route;
    params.forEach((key, value) {
      result = result.replaceAll(':$key', value);
    });
    return result;
  }
  
  // Example usage:
  // RouteConstants.buildRoute(
  //   RouteConstants.lessonDetail,
  //   {
  //     'courseId': 'course_123',
  //     'topicId': 'topic_456',
  //     'lessonId': 'lesson_789',
  //   }
  // )
}
