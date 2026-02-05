# TMF646 Appointment API - BDD Feature Files

## Overview

This directory contains comprehensive Behavior-Driven Development (BDD) feature files for the TMF646 Appointment Management API automation. The feature files are written in Gherkin syntax and cover all test scenarios implemented in the Postman collection.

## Feature Files

### 1. search-timeslot-lead-time.feature
**Purpose**: Lead time validation and business day calculation for appointment slot searches

**Coverage**:
- Lead time validation for different customer types (Business, Residential)
- Lead time validation for different order types (New, Switch, Upgrade, Downgrade, ISP Migration, WLTO)
- Lead time validation for different product types (FTTP, FTTC)
- Business classification scenarios (RFS1, RFS2)
- Property flag scenarios (WSOD, MOD, IN-EAD, IN-PIAUG, SUR, MDU, DTL, WSD, OD60)
- Network readiness scenarios (Standard, Extended Standard, Non-Standard)
- Business day calculation excluding weekends and bank holidays
- Reappointment scenarios
- Schema validation for SearchTimeSlot requests and responses

**Key Scenarios**: 40+ scenarios covering comprehensive lead time matrix

**Tags**: 
- `@lead-time` - All lead time validation scenarios
- `@order-type` - Order type specific scenarios
- `@business`, `@residential` - Customer type tags
- `@fttp`, `@fttc` - Product type tags
- `@isp-migration` - ISP migration specific scenarios
- `@reappointment` - Reappointment scenarios
- `@property-flag` - Property flag scenarios
- `@network-readiness` - Network readiness scenarios
- `@business-day-calculation` - Business day logic validation
- `@schema-validation` - Schema validation scenarios

---

### 2. appointment-creation.feature
**Purpose**: Appointment creation, reservation, and negative test scenarios

**Coverage**:
- Successful appointment creation with request chaining
- Appointment creation with order type information
- Multiple external identifiers handling
- Related party associations
- Related entity (product) associations
- Geographic place reference handling
- ISP Migration appointment creation
- Reappointment creation
- Date-time format validation
- Schema validation for appointment requests and responses
- Negative scenarios:
  - Missing mandatory fields (400 Bad Request)
  - Invalid field types (400 Bad Request)
  - Invalid date formats (400 Bad Request)
  - Unavailable time slots (400 Bad Request)
  - Past date-time validation (400 Bad Request)
  - End before start validation (400 Bad Request)
  - Missing authentication (401 Unauthorized)
  - Invalid/expired token (401 Unauthorized)
  - Insufficient permissions (403 Forbidden)
- SearchTimeSlot negative scenarios (400, 401, 403)
- End-to-end integration workflow
- Automatic token refresh integration
- Data integrity and request chaining validation
- Performance validation

**Key Scenarios**: 50+ scenarios covering positive and negative flows

**Tags**:
- `@appointment-creation` - Appointment creation scenarios
- `@positive` - Positive test scenarios
- `@negative` - Negative test scenarios
- `@request-chaining` - Request chaining validation
- `@bad-request` - HTTP 400 scenarios
- `@unauthorized` - HTTP 401 scenarios
- `@forbidden` - HTTP 403 scenarios
- `@integration` - Integration test scenarios
- `@end-to-end` - Complete workflow scenarios
- `@data-integrity` - Data validation scenarios
- `@performance` - Performance test scenarios

---

### 3. authentication-security.feature
**Purpose**: OAuth 2.0 authentication, authorization, and security controls

**Coverage**:
- OAuth 2.0 token generation (client_credentials grant)
- Automatic token refresh mechanism
- Proactive token refresh before expiration
- Pre-request script token validation
- Authorization header handling (Bearer token)
- Missing authorization rejection (401)
- Invalid token format rejection (401)
- Expired token handling (401)
- Client permission validation
- Insufficient permissions rejection (403)
- Secure credential storage in environment variables
- Token lifecycle management
- Credential rotation support
- OAuth failure error handling
- Network timeout handling
- Multi-environment support (staging, production)
- Variable precedence (environment vs collection)
- Complete authentication flow integration
- Token reuse across multiple requests
- Concurrent request handling
- Token expiration tracking and monitoring
- Authentication metrics monitoring

**Key Scenarios**: 30+ scenarios covering complete authentication lifecycle

**Tags**:
- `@authentication` - Authentication scenarios
- `@oauth` - OAuth 2.0 specific scenarios
- `@authorization` - Authorization scenarios
- `@security` - Security control scenarios
- `@token-generation` - Token generation
- `@token-refresh` - Token refresh logic
- `@pre-request` - Pre-request script scenarios
- `@authorization-header` - Header handling
- `@error-handling` - Error handling scenarios
- `@environment-configuration` - Environment setup
- `@integration` - Integration scenarios
- `@monitoring` - Monitoring and metrics

---

## Feature File Statistics

| Feature File                        | Scenarios | Scenario Outlines | Total Test Cases |
|-------------------------------------|-----------|-------------------|------------------|
| search-timeslot-lead-time.feature   | 32        | 1 (8 examples)    | 40               |
| appointment-creation.feature        | 49        | 1 (5 examples)    | 54               |
| authentication-security.feature     | 28        | 0                 | 28               |
| **TOTAL**                           | **109**   | **2 (13 ex)**     | **122**          |

---

## Gherkin Syntax Elements Used

### Keywords
- **Feature**: High-level description of functionality
- **Background**: Common preconditions for all scenarios
- **Scenario**: Individual test case
- **Scenario Outline**: Parameterized test template
- **Given**: Preconditions and context
- **When**: Actions/operations
- **Then**: Expected outcomes and assertions
- **And**: Additional steps in the same category
- **Examples**: Data table for scenario outline

### Tags
Tags enable selective test execution:
```bash
# Run only lead time scenarios
cucumber --tags @lead-time

# Run business customer scenarios for FTTP
cucumber --tags "@business and @fttp"

# Run all negative test scenarios
cucumber --tags @negative

# Run integration tests only
cucumber --tags @integration

# Exclude performance tests from regular runs
cucumber --tags "not @performance"
```

---

## Mapping to Postman Collection

### Folder Structure Mapping

```
TMF646 Appointment External
├── API Automation
│   ├── searchTimeSlot
│   │   ├── Valid_Requests
│   │   │   └── LeadTimeValidation
│   │   │       ├── OrderTypes_LeadTime          → search-timeslot-lead-time.feature
│   │   │       ├── Business_LeadTime            → search-timeslot-lead-time.feature
│   │   │       ├── PropertyFlag_LeadTime        → search-timeslot-lead-time.feature
│   │   │       ├── NetworkReadiness_LeadTime    → search-timeslot-lead-time.feature
│   │   │       └── ISPMigration_LeadTime        → search-timeslot-lead-time.feature
│   │   └── Invalid_Requests                     → appointment-creation.feature (@negative)
│   └── appointment
│       ├── Valid_Requests                       → appointment-creation.feature (@positive)
│       └── Invalid_Requests                     → appointment-creation.feature (@negative)
└── Pre-request Scripts (OAuth)                  → authentication-security.feature
```

---

## Test Data Requirements

### Environment Variables (Staging)
```gherkin
Given the following environment variables are configured:
  | Variable      | Type    | Description                          |
  | baseUrl       | Secret  | Base API URL                         |
  | authUrl       | Secret  | OAuth token endpoint URL             |
  | clientId      | Secret  | OAuth client identifier              |
  | clientSecret  | Secret  | OAuth client secret                  |
  | audience      | Secret  | OAuth audience                       |
  | grantType     | Secret  | OAuth grant type (client_credentials)|
  | bankHolidays  | Default | JSON array of bank holiday dates     |
```

### Test Data Fixtures
```gherkin
Given the following test data is available:
  - Valid geographic addresses for different property types
  - Customer references (Business and Residential)
  - Product references (FTTP and FTTC)
  - Order type configurations
  - Property flag configurations
  - Network readiness classifications
```

---

## Usage with BDD Frameworks

### Cucumber (Java)
```java
@RunWith(Cucumber.class)
@CucumberOptions(
    features = "src/test/resources/features",
    glue = "com.client.stepdefinitions",
    tags = "@lead-time and not @wip",
    plugin = {"pretty", "html:target/cucumber-reports"}
)
public class TestRunner {
}
```

### Behave (Python)
```python
# Run all scenarios
behave features/

# Run with specific tags
behave --tags=@lead-time features/

# Run with tag expressions
behave --tags="@business and @fttp" features/

# Generate reports
behave -f html -o reports/behave-report.html features/
```

### SpecFlow (.NET)
```csharp
[Binding]
public class SearchTimeSlotSteps
{
    [Given(@"I am searching appointment slots for a ""(.*)"" customer")]
    public void GivenSearchingForCustomerType(string customerType)
    {
        // Implementation
    }
}
```

### Cucumber.js (JavaScript/TypeScript)
```javascript
const { Given, When, Then } = require('@cucumber/cucumber');

Given('I am an authenticated API consumer with valid OAuth credentials', async function() {
    // Implementation
});
```

---

## Step Definition Guidelines

### Reusable Steps
Create reusable step definitions for common operations:

```gherkin
# Customer setup steps
Given I am searching appointment slots for a {string} customer
Given the customer has a {string} order type
Given the product type is {string}

# API interaction steps
When I submit a SearchTimeSlot request
When I submit the CreateAppointment request
Then the API should return HTTP status code {int}

# Validation steps
Then the response should validate against the SearchTimeSlot schema
Then the first available time slot should be at least {int} business days from current date
And no time slots should fall on weekends or bank holidays
```

### Data Table Steps
```gherkin
When I create an Appointment request with the following details:
  | Field         | Value             |
  | category      | Installation      |
  | description   | FTTP Installation |
```

### Parameterized Steps
```gherkin
Scenario Outline: Lead time validation matrix
  Given I am searching for a "<customerType>" customer
  And the order type is "<orderType>"
  Then the lead time should be at least <leadTimeDays> business days
  
  Examples:
    | customerType | orderType | leadTimeDays |
    | Business     | New       | 10           |
    | Residential  | Switch    | 2            |
```

---

## Integration with CI/CD

### GitHub Actions Example
```yaml
name: BDD Test Execution

on: [push, pull_request]

jobs:
  cucumber-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Cucumber Tests
        run: |
          mvn test -Dcucumber.filter.tags="@lead-time"
      - name: Publish Results
        uses: cucumber/cucumber-reports-plugin@v1
```

### Jenkins Pipeline
```groovy
pipeline {
    agent any
    stages {
        stage('BDD Tests') {
            steps {
                sh 'behave --tags=@integration features/'
            }
        }
        stage('Publish Reports') {
            steps {
                cucumber reportTitle: 'BDD Test Results',
                         fileIncludePattern: '**/*.json'
            }
        }
    }
}
```

---

## Reporting

### Cucumber HTML Report
Generated reports include:
- Feature execution summary
- Scenario pass/fail status
- Step-by-step execution details
- Screenshots (if configured)
- Execution duration
- Tag-based filtering

### Allure Report
```bash
# Generate Allure report
allure generate allure-results --clean -o allure-report

# View report
allure serve allure-results
```

---

## Best Practices

### 1. Write Declarative Scenarios
```gherkin
# Good - Declarative
Given I am a Business customer with New order on FTTP
When I search for appointment slots
Then I should see slots at least 10 business days ahead

# Avoid - Imperative
Given I set customerType to "Business"
And I set orderType to "New"
And I set productType to "FTTP"
When I click search button
```

### 2. Use Background for Common Setup
```gherkin
Background:
  Given I am an authenticated API consumer
  And the appointment API is available
```

### 3. Tag Strategically
```gherkin
@smoke @critical @lead-time @business
Scenario: Business customer new order lead time
```

### 4. Keep Scenarios Independent
Each scenario should be runnable in isolation without depending on other scenarios.

### 5. Use Scenario Outlines for Data-Driven Tests
When testing the same logic with different data, use Scenario Outline with Examples.

---

## Maintenance

### Updating Feature Files
When API changes occur:
1. Update affected scenarios
2. Add new scenarios for new functionality
3. Deprecate obsolete scenarios with `@deprecated` tag
4. Update step definitions accordingly
5. Update this documentation

### Version Control
- Feature files are versioned alongside code
- Use meaningful commit messages
- Link commits to user stories/requirements
- Review feature file changes in pull requests

---

## Support

For questions or issues related to BDD feature files:
- **API Team**: api-team@client.com
- **QA Automation Team**: qa-automation@client.com
- **Documentation**: https://docs.client.com/api/tmf646

---

**Last Updated**: February 2025  
**Collection Version**: v1.1  
**TMF646 API Version**: v5  
**Feature File Format**: Gherkin v6
