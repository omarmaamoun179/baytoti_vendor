class StatusCode {
  // Success
  static const String success = 'st_0000';
  
  // Authentication & Authorization
  static const String sessionExpired = 'st_0001';
  static const String unauthorized = 'st_0004';
  static const String forbidden = 'st_0005';
  
  // Server Errors
  static const String internalServerError = 'st_0006';
  static const String badGateway = 'st_0007';
  static const String serviceUnavailable = 'st_0008';
  static const String gatewayTimeout = 'st_0009';
  
  // Resource Errors
  static const String notFound = 'st_0002';
  static const String conflict = 'st_0010';
  static const String gone = 'st_0011';
  static const String resourceAlreadyExists = 'st_0036';
  
  // Request Errors
  static const String invalidRequest = 'st_0003';
  static const String badRequest = 'st_0035';
  static const String lengthRequired = 'st_0012';
  static const String preconditionFailed = 'st_0013';
  static const String payloadTooLarge = 'st_0014';
  static const String uriTooLong = 'st_0015';
  static const String unsupportedMediaType = 'st_0016';
  static const String rangeNotSatisfiable = 'st_0017';
  static const String expectationFailed = 'st_0018';
  static const String misdirectedRequest = 'st_0020';
  static const String unprocessableEntity = 'st_0021';
  static const String locked = 'st_0022';
  static const String failedDependency = 'st_0023';
  static const String tooEarly = 'st_0024';
  static const String upgradeRequired = 'st_0025';
  static const String preconditionRequired = 'st_0026';
  static const String tooManyRequests = 'st_0027';
  static const String requestHeaderFieldsTooLarge = 'st_0028';
  static const String unavailableForLegalReasons = 'st_0029';
  
  // User Related
  static const String emailAlreadyVerified = 'st_0030';
  static const String invalidOtp = 'st_0031';
  static const String userNotFound = 'st_0032';
  static const String invalidPassword = 'st_0033';
  static const String notVerified = 'st_0034';
}