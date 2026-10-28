class AppErrors {
  static const String networkTimeout = 'Connection timed out. Please check your internet connection.';
  static const String networkGeneral = 'Unable to connect to the server. Working in offline mode.';
  static const String visitorNotFound = 'Visitor record not found in registry.';
  static const String visitorNotFoundForId = 'Visitor with this pass identifier was not found.';
  static const String checkInFailed = 'Failed to check in visitor. Please try again.';
  static const String checkOutFailed = 'Failed to check out visitor. Please try again.';
  static const String registrationFailed = 'Failed to register visitor. Please check your inputs.';
  static const String updateFailed = 'Failed to update visitor record.';
  static const String deleteFailed = 'Failed to delete visitor record.';
  static const String restoreFailed = 'Failed to restore visitor record.';
  static const String registrationInProgress = 'Registration is already in progress. Please wait.';
  static const String duplicateRegistration = 'Duplicate registration request prevented.';
  static const String emptyRecycleBinFailed = 'Failed to empty recycle bin.';

  static const String nameRequired = 'Full Name is required';
  static const String nameMinLength = 'Name must be at least 2 characters';
  static const String nameMaxLength = 'Name cannot exceed 100 characters';
  static const String mobileRequired = 'Mobile number is required';
  static const String mobileExactDigits = 'Mobile number must be exactly 10 digits';
  static const String mobileNumericOnly = 'Mobile number must contain digits only';
  static const String emailInvalid = 'Please enter a valid email address';
  static const String emailMaxLength = 'Email cannot exceed 254 characters';
  static const String purposeRequired = 'Purpose of visit is required';
  static const String purposeMinLength = 'Purpose must be at least 3 characters';
  static const String purposeMaxLength = 'Purpose cannot exceed 500 characters';
  static const String customTypeRequired = 'Please specify the custom visitor type';
}

