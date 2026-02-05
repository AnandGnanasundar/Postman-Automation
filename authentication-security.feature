Feature: TMF646 Appointment Management - Authentication and Security
  As a CityFibre API security administrator
  I want to ensure proper authentication and authorization controls
  So that only authorized API consumers can access appointment management services

  Background:
    Given the appointment management API is available
    And the OAuth 2.0 authentication service is operational

  @authentication @oauth @token-generation
  Scenario: Successfully obtain OAuth 2.0 access token
    Given I have valid OAuth client credentials
    And I have the following OAuth parameters:
      | Parameter     | Value              |
      | client_id     | <valid-client-id>  |
      | client_secret | <valid-secret>     |
      | audience      | <api-audience>     |
      | grant_type    | client_credentials |
    When I send a POST request to the OAuth token endpoint
    Then the OAuth server should return HTTP status code 200
    And the response should contain "access_token"
    And the response should contain "expires_in"
    And the response should contain "token_type" as "Bearer"
    And the access token should be stored in environment variable "accessToken"
    And the token expiration timestamp should be calculated and stored

  @authentication @oauth @token-refresh
  Scenario: Automatically refresh expired OAuth token
    Given I have an OAuth token that has expired
    And the current timestamp exceeds the stored "tokenExpiration" value
    When a pre-request script executes before any API call
    Then the script should detect the token is expired
    And it should automatically request a new access token
    And the new token should be stored in "accessToken" environment variable
    And the new expiration timestamp should be calculated and stored
    And the API request should proceed with the new valid token

  @authentication @oauth @token-refresh-timing
  Scenario: Proactive token refresh before expiration
    Given I have an OAuth token
    And the token will expire in less than 60 seconds
    When a pre-request script executes
    Then the script should proactively refresh the token
    And prevent authentication failures due to token expiration mid-request

  @authentication @pre-request @token-validation
  Scenario: Pre-request script validates token before each API call
    Given I have the pre-request script configured at folder level
    When any request under the appointment folder executes
    Then the pre-request script should run first
    And it should check if "accessToken" exists in environment
    And it should check if "tokenExpiration" exists in environment
    And it should validate the token has not expired
    And if valid, the request should proceed with Authorization header
    And if invalid, the token should be refreshed automatically

  @authentication @authorization-header
  Scenario: Include valid Bearer token in Authorization header
    Given I have a valid OAuth access token
    When I make a SearchTimeSlot API request
    Then the request should include Authorization header
    And the header value should be "Bearer <access_token>"
    And the API should accept the request
    And return HTTP status code 200 or 201 for valid requests

  @authentication @missing-authorization
  Scenario: Reject request without Authorization header
    Given I have a valid SearchTimeSlot request payload
    And I intentionally omit the Authorization header
    When I submit the request to the API
    Then the API should return HTTP status code 401
    And the response should indicate "Unauthorized"
    And the response should require authentication

  @authentication @invalid-token-format
  Scenario: Reject request with malformed Bearer token
    Given I have a SearchTimeSlot request
    And I set Authorization header to "Bearer invalid-token-format"
    When I submit the request to the API
    Then the API should return HTTP status code 401
    And the error response should indicate invalid token format

  @authentication @expired-token-handling
  Scenario: Handle expired token gracefully
    Given I have an expired OAuth access token
    And I set the Authorization header with the expired token
    And I disable automatic token refresh
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 401
    And the error should indicate the token has expired
    And the client should be able to request a new token

  @authorization @client-permissions
  Scenario: Allow request from client with sufficient permissions
    Given I am authenticated with a client that has appointment management permissions
    When I submit a SearchTimeSlot or CreateAppointment request
    Then the API should process the request successfully
    And return appropriate success response code

  @authorization @insufficient-permissions
  Scenario: Reject request from client with insufficient permissions
    Given I am authenticated with OAuth credentials
    And my client is configured with limited permissions (403 test credentials)
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 403
    And the response should indicate "Forbidden"
    And the response should explain insufficient permissions

  @authorization @forbidden-appointment
  Scenario: Block appointment creation for restricted client
    Given I am authenticated with restricted client credentials
    When I attempt to create an Appointment
    Then the API should return HTTP status code 403
    And the error response should clearly state access is forbidden

  @security @environment-variables
  Scenario: Securely store sensitive credentials in environment
    Given I have OAuth credentials
    When I configure the Postman environment
    Then "clientId" should be stored as secret type
    And "clientSecret" should be stored as secret type
    And "accessToken" should be stored as secret type
    And "audience" should be stored as secret type
    And these variables should not be visible in plain text in logs
    And they should be masked in the Postman interface

  @security @token-storage
  Scenario: Manage access token lifecycle in environment variables
    Given I have obtained an OAuth access token
    When the token is stored in environment
    Then it should be stored in "accessToken" variable with secret type
    And the expiration should be stored as timestamp in "tokenExpiration"
    And when token is refreshed, both values should be updated atomically
    And old token should be immediately replaced with new token

  @security @credential-rotation
  Scenario: Support credential rotation without breaking automation
    Given I have running automation with OAuth credentials
    When the OAuth credentials are rotated (new client_id or client_secret)
    Then I should update the environment variables
    And the pre-request script should fetch new token automatically
    And existing automation should continue working without code changes

  @error-handling @oauth-failure
  Scenario: Handle OAuth token request failure gracefully
    Given I have OAuth credentials
    And the OAuth authorization server is temporarily unavailable
    When the pre-request script attempts to refresh token
    Then the error should be caught in try-catch block
    And an error message should be logged to console
    And the request should fail with clear error indication
    And the automation should not proceed with invalid/missing token

  @error-handling @network-timeout
  Scenario: Handle network timeout during token refresh
    Given I am requesting a new OAuth token
    And the network connection experiences timeout
    When the token refresh request fails
    Then the error should be properly handled
    And logged to console for debugging
    And the request should not proceed without valid token

  @environment-configuration @multi-environment
  Scenario: Support multiple environments (staging, production)
    Given I have separate Postman environments configured
    And "CityFibre TMF - Staging New" environment is for staging
    When I switch to staging environment
    Then all environment variables should point to staging endpoints
    And "baseUrl" should reference staging API URL
    And "authUrl" should reference staging OAuth server
    And requests should execute against staging environment

  @environment-configuration @variable-precedence
  Scenario: Respect variable precedence between environment and collection
    Given I have variables defined at both collection and environment level
    When a pre-request script accesses a variable
    Then it should first check environment variables
    And if not found, check collection variables
    And use the appropriate value based on precedence

  @integration @authentication-flow
  Scenario: Complete authentication flow before API request execution
    Given I have configured OAuth credentials in environment
    And the "accessToken" variable is empty or expired
    When I execute a SearchTimeSlot request
    Then the pre-request script should run automatically
    And it should detect missing or expired token
    And request a new token from OAuth server
    And store the token in environment
    And attach the token to Authorization header
    And execute the actual API request
    And all this should happen transparently without manual intervention

  @integration @token-reuse
  Scenario: Reuse valid token across multiple requests
    Given I have obtained a valid OAuth token
    And the token expiration is 3600 seconds in the future
    When I execute 10 consecutive SearchTimeSlot requests
    Then the pre-request script should detect token is still valid
    And it should NOT request a new token for each request
    And it should reuse the existing valid token
    And all 10 requests should succeed with the same token

  @integration @concurrent-requests
  Scenario: Handle concurrent request execution with single token
    Given I have a valid OAuth token
    When I execute multiple requests concurrently in Collection Runner
    Then all requests should use the same valid token
    And no race condition should occur in token refresh
    And all requests should complete successfully

  @monitoring @token-expiration-tracking
  Scenario: Track and log token expiration events
    Given I have OAuth token lifecycle logging enabled
    When a token is obtained
    Then the expiration timestamp should be logged
    And when token refresh occurs
    Then a log entry should indicate "Token refreshed"
    And the new expiration should be logged
    And this helps in debugging authentication issues

  @monitoring @authentication-metrics
  Scenario: Monitor authentication success and failure rates
    Given I am running automated regression tests
    When authentication events occur
    Then successful token generations should be tracked
    And authentication failures should be tracked
    And token refresh events should be tracked
    And these metrics help monitor API health
