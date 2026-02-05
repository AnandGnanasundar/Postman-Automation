Feature: TMF646 Appointment Management - SearchTimeSlot Lead Time Validation
  As a Test API consumer
  I want to search for available appointment time slots
  So that I can identify valid installation dates based on customer type and order configuration

  Background:
    Given I am an authenticated API consumer with valid OAuth credentials
    And the appointment management API is available at the base URL
    And I have configured bank holidays for lead time calculation
    And the current date is known for lead time validation

  @lead-time @order-type @business @fttp
  Scenario: Search time slots for Business customer with Switch order type on FTTP
    Given I am searching appointment slots for a "Business" customer
    And the customer has a "Switch" order type
    And the product type is "FTTP"
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the response should contain "searchResult" as "success"
    And the response should validate against the SearchTimeSlot schema
    And the first available time slot should be at least 5 business days from current date
    And no time slots should fall on weekends or bank holidays
    And the available time slots should have valid start and end date times
    And environment variables "firstAvailableStartDateTime" and "firstAvailableEndDateTime" should be set for appointment creation

  @lead-time @order-type @business @fttp
  Scenario: Search time slots for Business customer with New order type on FTTP
    Given I am searching appointment slots for a "Business" customer
    And the customer has a "New" order type
    And the product type is "FTTP"
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the response should contain "searchResult" as "success"
    And the first available time slot should be at least 10 business days from current date
    And no time slots should fall on weekends or bank holidays
    And the response should include related party information
    And the response should include related place information

  @lead-time @order-type @business @fttp
  Scenario: Search time slots for Business customer with Upgrade (Regrade) order type on FTTP
    Given I am searching appointment slots for a "Business" customer
    And the customer has a "Regrade" order type
    And the product type is "FTTP"
    And the order is an upgrade request
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the first available time slot should be at least 5 business days from current date
    And the response should validate against the SearchTimeSlot schema

  @lead-time @order-type @business @fttp
  Scenario: Search time slots for Business customer with Downgrade order type on FTTP
    Given I am searching appointment slots for a "Business" customer
    And the customer has a "Regrade" order type
    And the product type is "FTTP"
    And the order is a downgrade request
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the first available time slot should be at least 5 business days from current date
    And the available slots should be appropriate for service modification

  @lead-time @order-type @residential @fttp
  Scenario: Search time slots for Residential customer with Switch order type on FTTP
    Given I am searching appointment slots for a "Residential" customer
    And the customer has a "Switch" order type
    And the product type is "FTTP"
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the response should contain "searchResult" as "success"
    And the first available time slot should be at least 2 business days from current date
    And no time slots should fall on weekends or bank holidays
    And the response should validate against the SearchTimeSlot schema

  @lead-time @order-type @residential @fttp
  Scenario: Search time slots for Residential customer with New order type on FTTP
    Given I am searching appointment slots for a "Residential" customer
    And the customer has a "New" order type
    And the product type is "FTTP"
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the response should contain "searchResult" as "success"
    And the first available time slot should be at least 5 business days from current date
    And the available time slots should be in chronological order
    And the response should include the requested time slot information

  @lead-time @order-type @residential @fttp
  Scenario: Search time slots for Residential customer with Upgrade order type on FTTP
    Given I am searching appointment slots for a "Residential" customer
    And the customer has a "Regrade" order type
    And the product type is "FTTP"
    And the order is an upgrade request
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the first available time slot should be at least 2 business days from current date
    And the response should contain available time slot array with at least 1 slot

  @lead-time @order-type @residential @fttp
  Scenario: Search time slots for Residential customer with Downgrade order type on FTTP
    Given I am searching appointment slots for a "Residential" customer
    And the customer has a "Regrade" order type
    And the product type is "FTTP"
    And the order is a downgrade request
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the first available time slot should be at least 2 business days from current date

  @lead-time @order-type @business @fttc
  Scenario: Search time slots for Business customer with New order type on FTTC
    Given I am searching appointment slots for a "Business" customer
    And the customer has a "New" order type
    And the product type is "FTTC"
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the response should contain "searchResult" as "success"
    And the first available time slot should be at least 10 business days from current date
    And the response should validate against the SearchTimeSlot schema

  @lead-time @order-type @residential @fttc
  Scenario: Search time slots for Residential customer with New order type on FTTC
    Given I am searching appointment slots for a "Residential" customer
    And the customer has a "New" order type
    And the product type is "FTTC"
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the response should contain "searchResult" as "success"
    And the first available time slot should be at least 5 business days from current date
    And the response should validate against the SearchTimeSlot schema

  @lead-time @isp-migration @zero-lead-time
  Scenario: Search time slots for ISP Migration order with zero lead time
    Given I am searching appointment slots for any customer type
    And the customer has an "ISP Migration" order type
    And the "ispMigration" flag is set to true
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the response should contain "searchResult" as "success"
    And the first available time slot should be available today (0 business days)
    And the response should indicate ISP migration appointment characteristics
    And the response should validate against the SearchTimeSlot schema

  @lead-time @isp-migration @reappointment
  Scenario: Search time slots for ISP Migration with reappointment
    Given I am searching appointment slots for any customer type
    And the customer has an "ISP Migration" order type
    And the "ispMigration" flag is set to true
    And the "reappointment" flag is set to true
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the first available time slot should be available today (0 business days)
    And the response should accommodate the reappointment scenario

  @lead-time @wlto-order @same-isp
  Scenario: Search time slots for Working Line Takeover (WLTO) with same ISP
    Given I am searching appointment slots for a customer
    And the customer has a "WLTO" order type
    And the working line takeover is from the same ISP
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the response should contain "searchResult" as "success"
    And the available time slots should reflect appropriate lead time for WLTO same ISP scenario
    And the response should validate against the SearchTimeSlot schema

  @lead-time @wlto-order @different-isp
  Scenario: Search time slots for Working Line Takeover (WLTO) with different ISP
    Given I am searching appointment slots for a customer
    And the customer has a "WLTO" order type
    And the working line takeover is from a different ISP
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request with requested start date time
    Then the API should return HTTP status code 200
    And the response should contain "searchResult" as "success"
    And the available time slots should reflect appropriate lead time for WLTO different ISP scenario

  @lead-time @business-type @rfs1
  Scenario: Search time slots for Business customer with RFS1 classification
    Given I am searching appointment slots for a "Business" customer
    And the business classification is "RFS1"
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should meet RFS1 lead time requirements
    And the response should validate against the SearchTimeSlot schema

  @lead-time @business-type @rfs2
  Scenario: Search time slots for Business customer with RFS2 classification
    Given I am searching appointment slots for a "Business" customer
    And the business classification is "RFS2"
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should meet RFS2 lead time requirements
    And the response should validate against the SearchTimeSlot schema

  @lead-time @business-type @rfs1 @reappointment
  Scenario: Search time slots for Business RFS1 customer with reappointment
    Given I am searching appointment slots for a "Business" customer
    And the business classification is "RFS1"
    And the "reappointment" flag is set to true
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the available time slots should accommodate reappointment scenario
    And the first available slot should meet RFS1 reappointment lead time

  @lead-time @business-type @rfs2 @reappointment
  Scenario: Search time slots for Business RFS2 customer with reappointment
    Given I am searching appointment slots for a "Business" customer
    And the business classification is "RFS2"
    And the "reappointment" flag is set to true
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the available time slots should accommodate reappointment scenario
    And the first available slot should meet RFS2 reappointment lead time

  @lead-time @property-flag @wsod
  Scenario: Search time slots for property with WSOD flag
    Given I am searching appointment slots for a customer
    And the property has "WSOD" (Wayleave Sign Off Delay) flag
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should reflect WSOD property lead time requirements
    And the response should validate against the SearchTimeSlot schema

  @lead-time @property-flag @mod
  Scenario: Search time slots for property with MOD flag
    Given I am searching appointment slots for a customer
    And the property has "MOD" flag
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should reflect MOD property lead time requirements

  @lead-time @property-flag @in-ead
  Scenario: Search time slots for property with IN-EAD flag
    Given I am searching appointment slots for a customer
    And the property has "IN-EAD" (In-build Early Access Delivery) flag
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should reflect IN-EAD property lead time requirements

  @lead-time @property-flag @in-piaug
  Scenario: Search time slots for property with IN-PIAUG flag
    Given I am searching appointment slots for a customer
    And the property has "IN-PIAUG" flag
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should reflect IN-PIAUG property lead time requirements

  @lead-time @property-flag @sur
  Scenario: Search time slots for property with SUR flag
    Given I am searching appointment slots for a customer
    And the property has "SUR" (Survey Required) flag
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should reflect SUR property lead time requirements

  @lead-time @property-flag @mdu
  Scenario: Search time slots for property with MDU flag
    Given I am searching appointment slots for a customer
    And the property has "MDU" (Multi-Dwelling Unit) flag
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should reflect MDU property lead time requirements

  @lead-time @property-flag @dtl
  Scenario: Search time slots for property with DTL flag
    Given I am searching appointment slots for a customer
    And the property has "DTL" (Direct to Lead) flag
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should reflect DTL property lead time requirements

  @lead-time @property-flag @wsd
  Scenario: Search time slots for property with WSD flag
    Given I am searching appointment slots for a customer
    And the property has "WSD" (Wayleave Sign Delay) flag
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should reflect WSD property lead time requirements

  @lead-time @property-flag @od60
  Scenario: Search time slots for property with OD60 flag
    Given I am searching appointment slots for a customer
    And the property has "OD60" (Over 60 days) flag
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should reflect OD60 property lead time requirements

  @lead-time @network-readiness @standard
  Scenario: Search time slots for standard network readiness property
    Given I am searching appointment slots for a customer
    And the property has "Standard" network readiness
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should reflect standard network readiness lead time

  @lead-time @network-readiness @extended-standard
  Scenario: Search time slots for extended standard network readiness property
    Given I am searching appointment slots for a customer
    And the property has "Extended Standard" network readiness
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should reflect extended standard network readiness lead time

  @lead-time @network-readiness @non-standard
  Scenario: Search time slots for non-standard network readiness property
    Given I am searching appointment slots for a customer
    And the property has "Non-Standard" network readiness
    And I provide a valid geographic address reference
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should reflect non-standard network readiness lead time

  @lead-time @business-day-calculation
  Scenario Outline: Validate business day calculation excluding weekends and bank holidays
    Given I am searching appointment slots for a "<customerType>" customer
    And the customer has a "<orderType>" order type
    And the product type is "<productType>"
    And today is a weekday
    And I have a list of bank holidays configured
    When I submit a SearchTimeSlot request
    Then the API should return HTTP status code 200
    And the first available time slot should be at least <leadTimeDays> business days from current date
    And the calculation should exclude Saturdays
    And the calculation should exclude Sundays
    And the calculation should exclude all configured bank holidays
    And the available slot should fall on a weekday

    Examples:
      | customerType | orderType | productType | leadTimeDays |
      | Business     | New       | FTTP        | 10           |
      | Business     | Switch    | FTTP        | 5            |
      | Business     | Regrade   | FTTP        | 5            |
      | Residential  | New       | FTTP        | 5            |
      | Residential  | Switch    | FTTP        | 2            |
      | Residential  | Regrade   | FTTP        | 2            |
      | Business     | New       | FTTC        | 10           |
      | Residential  | New       | FTTC        | 5            |

  @schema-validation @request
  Scenario: Validate SearchTimeSlot request conforms to schema
    Given I have a valid SearchTimeSlot request payload
    And the request includes all mandatory fields:
      | Field                 | Type   |
      | @type                 | string |
      | requestedTimeSlot     | array  |
      | relatedParty          | object |
      | appointmentType       | string |
      | ispMigration          | boolean|
      | reappointment         | boolean|
      | relatedPlace          | object |
      | relatedEntity         | array  |
    When I validate the request against the SearchTimeSlot JSON schema
    Then the request should pass schema validation
    And all required fields should be present
    And all field types should match schema definitions

  @schema-validation @response
  Scenario: Validate SearchTimeSlot response conforms to schema
    Given I have submitted a valid SearchTimeSlot request
    When I receive the API response
    Then the response should validate against the SearchTimeSlot response schema
    And the response should include all mandatory fields:
      | Field                 | Type   |
      | @type                 | string |
      | relatedPlace          | object |
      | searchResult          | string |
      | relatedEntity         | array  |
      | searchDate            | string |
      | requestedTimeSlot     | array  |
      | availableTimeSlot     | array  |
    And each available time slot should have "startDateTime" and "endDateTime"
    And all date-time fields should be in ISO 8601 format
