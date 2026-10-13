class OAuthConfig {
  // Public OAuth client identifier, not a client secret.
  // A build can override this project default with --dart-define.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '764367490870-n17cmlp7q4mr42aco2ar1k81bpsuqfku.apps.googleusercontent.com',
  );
}
