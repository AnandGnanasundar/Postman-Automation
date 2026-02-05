Feature: TMF646 Appointment Management - Appointment Creation and Reservation
  As a CityFibre API consumer
  I want to create and reserve appointment slots
  So that I can book installation appointments for customers

  Background:
    Given I am an authenticated API consumer with valid OAuth credentials
    And the appointment management API is available at the base URL
    And I have successfully searched for available time slots

  @appointment-creation @positive @request-chaining
  Scenario: Create appointment using slot from SearchTimeSlot response
    Given I have executed a SearchTimeSlot request successfully
    And the response contains at least one available time slot
    And I have extracted the first available slot's "startDateTime" and "endDateTime"
    And I set environment variables for appointment creation
    When I create an Appointment request with the extracted time slot
    And I provide all mandatory appointment details:
      | Field           | Value                          |
      | @type           | Appointment                    |
      | category        | Installation                   |
      | description     | FTTP Installation Appointment  |
      | appointmentType | Installation                   |
      | ispMigration    | false                          |
      | reappointment   | false                          |
    And I submit the CreateAppointment request
    Then the API should return HTTP status code 201
    And the response should contain a unique appointment "id"
    And the response should have "status" as "reserved"
    And the response "validFor" should match the requested time slot
    And the response should include "creationDate"
    And the response should validate against the Appointment response schema

  @appointment-creation @positive @with-order-type
  Scenario: Create appointment with specific order type information
    Given I have executed a SearchTimeSlot request for a "Business" customer with "Switch" order type
    And the response contains available time slots
    And I have extracted the first available slot
    When I create an Appointment request with the extracted time slot
    And I include the order type information in the appointment
    And I provide external identifier with order reference
    And I submit the CreateAppointment request
    Then the API should return HTTP status code 201
    And the response should contain the appointment "id"
    And the response should preserve the order type characteristics
    And the appointment status should be "reserved"

  @appointment-creation @positive @external-identifiers
  Scenario: Create appointment with multiple external identifiers
    Given I have available time slot information from SearchTimeSlot
    When I create an Appointment request
    And I include multiple external identifiers:
      | Owner      | Type      | ID          |
      | CityFibre  | OrderId   | ORD-12345   |
      | CityFibre  | ProductId | PROD-67890  |
    And I submit the CreateAppointment request
    Then the API should return HTTP status code 201
    And the response should include all provided external identifiers
    And each external identifier should maintain its owner and type

  @appointment-creation @positive @related-party
  Scenario: Create appointment with multiple related parties
    Given I have available time slot information from SearchTimeSlot
    When I create an Appointment request with the time slot
    And I include related parties:
      | Role     | Name              | Type     | ReferredType |
      | Customer | John Smith        | PartyRef | Individual   |
      | Agent    | CityFibre Agent   | PartyRef | Agent        |
    And I submit the CreateAppointment request
    Then the API should return HTTP status code 201
    And the response should contain all related parties
    And each party should maintain role and reference information

  @appointment-creation @positive @related-entity
  Scenario: Create appointment with related product entities
    Given I have available time slot information from SearchTimeSlot
    When I create an Appointment request
    And I include related entities:
      | Role    | Name          | Type      | ReferredType |
      | Product | FTTP 1000Mbps | EntityRef | Product      |
    And I submit the CreateAppointment request
    Then the API should return HTTP status code 201
    And the response should include the related product entity
    And the entity information should be preserved correctly

  @appointment-creation @positive @related-place
  Scenario: Create appointment with geographic place reference
    Given I have available time slot information from SearchTimeSlot
    When I create an Appointment request
    And I include related place with role "InstallationAddress"
    And I provide geographic address reference with external identifiers
    And I submit the CreateAppointment request
    Then the API should return HTTP status code 201
    And the response should include the related place information
    And the geographic address should be correctly referenced

  @appointment-creation @positive @isp-migration
  Scenario: Create appointment for ISP Migration order
    Given I have executed SearchTimeSlot for ISP Migration
    And the response contains available same-day slots
    When I create an Appointment request with ISP Migration flag set to true
    And I provide the extracted time slot
    And I submit the CreateAppointment request
    Then the API should return HTTP status code 201
    And the response should show "ispMigration" as true
    And the appointment should be created for the same day

  @appointment-creation @positive @reappointment
  Scenario: Create a reappointment for existing customer
    Given I have executed SearchTimeSlot with reappointment flag set to true
    And the response contains available slots for reappointment
    When I create an Appointment request with reappointment flag set to true
    And I provide reference to the original appointment if applicable
    And I submit the CreateAppointment request
    Then the API should return HTTP status code 201
    And the response should show "reappointment" as true
    And the appointment should be successfully reserved

  @appointment-creation @date-time-validation
  Scenario: Validate appointment date-time format and timezone handling
    Given I have available time slot with specific timezone
    When I create an Appointment request with the time slot
    And the validFor startDateTime is in ISO 8601 format
    And the validFor endDateTime is in ISO 8601 format
    And I submit the CreateAppointment request
    Then the API should return HTTP status code 201
    And the response validFor dates should match the request
    And the dates should maintain ISO 8601 format with timezone
    And the creationDate should be a valid ISO 8601 timestamp

  @appointment-creation @schema-validation
  Scenario: Validate appointment request and response schemas
    Given I have a complete Appointment request payload
    When I validate the request against the Appointment request schema
    Then the request should pass JSON schema validation
    And when I submit the request and receive the response
    Then the response should validate against the Appointment response schema
    And all mandatory response fields should be present

  @negative @bad-request @missing-fields
  Scenario: Attempt to create appointment with missing mandatory fields
    Given I have an incomplete Appointment request
    And the request is missing mandatory field "@type"
    When I submit the CreateAppointment request
    Then the API should return HTTP status code 400
    And the response should contain error code
    And the response should contain reason describing the missing field
    And the error response should validate against the BadRequest schema

  @negative @bad-request @invalid-field-types
  Scenario Outline: Attempt to create appointment with invalid field types
    Given I have an Appointment request
    And the field "<fieldName>" has invalid type "<invalidType>" instead of "<expectedType>"
    When I submit the CreateAppointment request
    Then the API should return HTTP status code 400
    And the error response should indicate field type mismatch
    And the response should include "@type" as "Error"

    Examples:
      | fieldName       | invalidType | expectedType |
      | validFor        | string      | object       |
      | ispMigration    | string      | boolean      |
      | reappointment   | string      | boolean      |
      | relatedEntity   | object      | array        |
      | externalId      | object      | array        |

  @negative @bad-request @invalid-date-format
  Scenario: Attempt to create appointment with invalid date-time format
    Given I have an Appointment request
    And the validFor startDateTime is not in ISO 8601 format
    When I submit the CreateAppointment request
    Then the API should return HTTP status code 400
    And the error response should indicate invalid date format
    And the response should validate against the BadRequest schema

  @negative @bad-request @invalid-time-slot
  Scenario: Attempt to create appointment with unavailable time slot
    Given I have executed SearchTimeSlot and received available slots
    And I modify the time slot to a date not returned in available slots
    When I submit the CreateAppointment request with unavailable slot
    Then the API should return HTTP status code 400
    And the error response should indicate the slot is not available
    And the response reason should explain time slot validation failure

  @negative @bad-request @past-date-time
  Scenario: Attempt to create appointment with past date-time
    Given I have an Appointment request
    And the validFor startDateTime is set to a past date
    When I submit the CreateAppointment request
    Then the API should return HTTP status code 400
    And the error response should indicate appointment time cannot be in the past

  @negative @bad-request @end-before-start
  Scenario: Attempt to create appointment where endDateTime is before startDateTime
    Given I have an Appointment request
    And the validFor endDateTime is before the startDateTime
    When I submit the CreateAppointment request
    Then the API should return HTTP status code 400
    And the error response should indicate invalid time range

  @negative @unauthorized @missing-token
  Scenario: Attempt to create appointment without authentication token
    Given I have a valid Appointment request payload
    And I do not include the Authorization header
    When I submit the CreateAppointment request
    Then the API should return HTTP status code 401
    And the response should indicate authentication is required

  @negative @unauthorized @invalid-token
  Scenario: Attempt to create appointment with invalid authentication token
    Given I have a valid Appointment request payload
    And I include an invalid or expired OAuth token in Authorization header
    When I submit the CreateAppointment request
    Then the API should return HTTP status code 401
    And the error response should indicate token is invalid or expired

  @negative @unauthorized @expired-token
  Scenario: Attempt to create appointment with expired token
    Given I have a valid Appointment request payload
    And my OAuth token has expired
    And I have not refreshed the token
    When I submit the CreateAppointment request
    Then the API should return HTTP status code 401
    And the system should trigger automatic token refresh in subsequent requests

  @negative @forbidden @insufficient-permissions
  Scenario: Attempt to create appointment with insufficient client permissions
    Given I am authenticated with OAuth credentials that have limited permissions
    And the client is configured with 403 response credentials
    When I submit the CreateAppointment request
    Then the API should return HTTP status code 403
    And the error response should indicate insufficient permissions
    And the response should validate against the error schema

  @negative @bad-request-search @missing-fields
  Scenario: Attempt SearchTimeSlot with missing mandatory fields
    Given I have an incomplete SearchTimeSlot request
    And the request is missing mandatory field "appointmentType"
    When I submit the SearchTimeSlot request
    Then the API should return HTTP status code 400
    And the response should contain error code
    And the response should indicate which field is missing

  @negative @bad-request-search @invalid-customer-type
  Scenario: Attempt SearchTimeSlot with invalid customer type
    Given I have a SearchTimeSlot request
    And the relatedParty @referredType is set to an invalid value
    When I submit the SearchTimeSlot request
    Then the API should return HTTP status code 400
    And the error response should indicate invalid customer type

  @negative @bad-request-search @invalid-geographic-address
  Scenario: Attempt SearchTimeSlot with non-existent geographic address
    Given I have a SearchTimeSlot request
    And the relatedPlace contains a geographic address ID that does not exist
    When I submit the SearchTimeSlot request
    Then the API should return HTTP status code 400
    And the error response should indicate geographic address not found

  @negative @unauthorized-search @missing-token
  Scenario: Attempt SearchTimeSlot without authentication
    Given I have a valid SearchTimeSlot request payload
    And I do not include the Authorization header
    When I submit the SearchTimeSlot request
    Then the API should return HTTP status code 401
    And the response should indicate authentication is required

  @negative @unauthorized-search @invalid-token
  Scenario: Attempt SearchTimeSlot with invalid token
    Given I have a valid SearchTimeSlot request payload
    And I include an invalid OAuth token
    When I submit the SearchTimeSlot request
    Then the API should return HTTP status code 401

  @negative @forbidden-search @insufficient-permissions
  Scenario: Attempt SearchTimeSlot with insufficient permissions
    Given I am authenticated with limited permission OAuth credentials
    And the client is configured with 403 response
    When I submit the SearchTimeSlot request
    Then the API should return HTTP status code 403
    And the error response should indicate forbidden access

  @integration @end-to-end
  Scenario: Complete appointment booking workflow from search to reservation
    Given I am an authenticated API consumer
    When I execute SearchTimeSlot for a "Business" customer with "New" order on "FTTP"
    Then the API should return available slots with minimum 10 business days lead time
    And I extract the first available slot start and end times
    And I store them in environment variables
    When I create an Appointment request using the extracted slot
    And I submit the CreateAppointment request
    Then the API should return HTTP status code 201
    And the appointment should be successfully reserved
    And the appointment ID should be returned for order reference
    And the complete workflow should complete in under 2 seconds

  @integration @token-refresh
  Scenario: Automatic OAuth token refresh during appointment workflow
    Given I am authenticated with an OAuth token that is about to expire
    And I have configured token expiration monitoring
    When I submit a SearchTimeSlot request
    Then the pre-request script should check token expiration
    And if the token is expired, it should automatically refresh
    And the request should proceed with the new valid token
    And the response should be successful
    And the new token should be stored in environment variable "accessToken"
    And the new token expiration should be stored in "tokenExpiration"

  @data-integrity @request-chaining
  Scenario: Validate data extraction and chaining between SearchTimeSlot and Appointment
    Given I execute SearchTimeSlot and receive multiple available slots
    When I extract the first available slot's startDateTime
    And I set environment variable "firstAvailableStartDateTime"
    And I extract the first available slot's endDateTime
    And I set environment variable "firstAvailableEndDateTime"
    Then these environment variables should be populated correctly
    And when I use them in CreateAppointment request via {{variable}} syntax
    Then the variables should be correctly interpolated
    And the Appointment should be created with exact matching time slot
    And the response should confirm the time slot matches extracted values

  @performance @response-time
  Scenario: Validate API response time performance
    Given I have valid requests for SearchTimeSlot and CreateAppointment
    When I execute the SearchTimeSlot request
    Then the response time should be less than 200ms
    When I execute the CreateAppointment request
    Then the response time should be less than 200ms
    And the total workflow duration should be less than 500ms
