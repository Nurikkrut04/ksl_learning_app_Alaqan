class AdminConstants {
  static const Set<String> allowedAdminEmails = {
    'nurikslam.beis@gmail.com',
  };

  static bool isAllowedAdminEmail(String? email) {
    if (email == null) return false;
    return allowedAdminEmails.contains(email.trim().toLowerCase());
  }
}
