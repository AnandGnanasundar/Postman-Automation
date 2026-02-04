# TMF646 Appointment API - Automated Regression Testing

## Overview

This repository contains an automated testing suite for the TMF646 Appointment Management API, implementing comprehensive regression tests for appointment slot search and reservation workflows. The automation validates lead time calculations across multiple customer types (Business, Residential, FTTP, FTTC) and order types (New, Switch, Upgrade, Downgrade, ISP Migration) using Postman collections with advanced scripting capabilities.

## Problem Statement

Appointment slot availability varies significantly based on:
- Customer type (Business vs Residential)
- Product type (FTTP vs FTTC)
- Order type (New, Switch, Upgrade, Downgrade, ISP Migration)
- Lead time requirements
- Bank holidays and weekend scheduling

Manual testing of all possible customer-order-product combinations is time-prohibitive and error-prone. This automation ensures consistent regression coverage across all scenarios with every deployment to staging.

## Architecture

### API Workflow
```
SearchTimeSlot API → Extract Available Slots → Create Appointment API → Validate Reservation
```

### Key Components

1. **SearchTimeSlot API** - Queries available appointment slots based on:
   - Customer party type
   - Order type and product configuration
   - Geographic location (GeographicAddress)
   - Requested time window

2. **Appointment API** - Reserves appointment slots with:
   - Slot validation
   - Customer association
   - External identifier tracking
   - Status management

### Request Chaining

The automation implements sophisticated option chaining to extract data from SearchTimeSlot responses and inject into Appointment creation requests:

```javascript
// Extract first available slot from search response
const firstAvailableSlot = responseBody.availableTimeSlot[0];
pm.environment.set("firstAvailableStartDateTime", firstAvailableSlot.validFor.startDateTime);
pm.environment.set("firstAvailableEndDateTime", firstAvailableSlot.validFor.endDateTime);

// Use extracted slot in subsequent appointment creation
{
  "validFor": {
    "startDateTime": "{{firstAvailableStartDateTime}}",
    "endDateTime": "{{firstAvailableEndDateTime}}"
  }
}
```

## Test Coverage

### Lead Time Validation Matrix

| Customer Type | Order Type | Product Type | Validated Lead Time |
|--------------|------------|--------------|---------------------|
| Business | New Order | FTTP | 10 business days |
| Business | Switch Order | FTTP | 5 business days |
| Business | Upgrade Order | FTTP | 5 business days |
| Business | Downgrade Order | FTTP | 5 business days |
| Business | ISP Migration | FTTP | 0 business days |
| Residential | New Order | FTTP | 5 business days |
| Residential | Switch Order | FTTP | 2 business days |
| Residential | Upgrade Order | FTTP | 2 business days |
| Residential | Downgrade Order | FTTP | 2 business days |
| Residential | ISP Migration | FTTP | 0 business days |
| Business | New Order | FTTC | 10 business days |
| Residential | New Order | FTTC | 5 business days |

### Test Scenarios

1. **Valid Requests** - Comprehensive positive test scenarios
   - Lead time validation for all customer-order combinations
   - Business days calculation excluding weekends and bank holidays
   - Slot availability verification
   - Appointment reservation success

2. **Invalid Requests** - Negative test scenarios
   - Schema validation failures
   - Missing required fields
   - Invalid date formats
   - Authentication failures

3. **Edge Cases**
   - Weekend/bank holiday handling
   - Timezone considerations
   - Concurrent slot reservations
   - Expired time slots

## Technical Implementation

### Pre-Request Scripts

OAuth 2.0 token management with automatic refresh:

```javascript
const currentTime = Math.floor(Date.now() / 1000);
const tokenExpiration = pm.environment.get("tokenExpiration");

if (!tokenExpiration || currentTime >= tokenExpiration) {
    // Request new access token
    pm.sendRequest({
        url: `${pm.environment.get("authUrl")}/oauth/token`,
        method: 'POST',
        header: { 'Content-Type': 'application/json' },
        body: {
            mode: 'raw',
            raw: {
                'client_id': pm.environment.get("clientId"),
                'client_secret': pm.environment.get("clientSecret"),
                'audience': pm.environment.get("audience"),
                'grant_type': pm.environment.get("grantType")
            }
        }
    }, function (error, response) {
        const responseBody = response.json();
        pm.environment.set("accessToken", responseBody.access_token);
        pm.environment.set("tokenExpiration", currentTime + responseBody.expires_in);
    });
}
```

### Test Scripts

**Business Day Calculation** with bank holiday exclusion:

```javascript
function calculateBusinessDays(startDate, targetBusinessDays) {
    let currentDate = moment(startDate);
    let businessDaysAdded = 0;
    
    while (businessDaysAdded < targetBusinessDays) {
        currentDate.add(1, 'days');
        
        // Skip weekends
        if (currentDate.day() === 0 || currentDate.day() === 6) continue;
        
        // Skip bank holidays
        const isBankHoliday = bankHolidays.some(holiday => 
            moment(holiday).isSame(currentDate, 'day')
        );
        
        if (!isBankHoliday) businessDaysAdded++;
    }
    
    return currentDate;
}
```

**Lead Time Validation**:

```javascript
const expectedLeadTimeDays = {
    "Business_New_FTTP": 10,
    "Business_Switch_FTTP": 5,
    "Residential_New_FTTP": 5,
    "Residential_Switch_FTTP": 2,
    "ISPMigration": 0
};

const scenario = `${customerType}_${orderType}_${productType}`;
const expectedLeadTime = expectedLeadTimeDays[scenario];

const currentDate = moment();
const expectedMinimumDate = calculateBusinessDays(currentDate, expectedLeadTime);
const actualSlotDate = moment(firstAvailableStartDateTime);

pm.test(`Lead time validation: ${scenario} should be minimum ${expectedLeadTime} business days`, () => {
    pm.expect(actualSlotDate.isSameOrAfter(expectedMinimumDate)).to.be.true;
});
```

**Schema Validation**:

```javascript
const Ajv = require('ajv');
const ajv = new Ajv();

const requestSchema = JSON.parse(pm.collectionVariables.get("requestSchemaSearchTimeSlot"));
const responseSchema = JSON.parse(pm.collectionVariables.get("responseSchemaSearchTimeSlot"));

pm.test("Request schema validation", () => {
    const validate = ajv.compile(requestSchema);
    const valid = validate(requestBody);
    pm.expect(valid, JSON.stringify(validate.errors)).to.be.true;
});

pm.test("Response schema validation", () => {
    const validate = ajv.compile(responseSchema);
    const valid = validate(responseBody);
    pm.expect(valid, JSON.stringify(validate.errors)).to.be.true;
});
```

## Environment Configuration

### Required Variables

| Variable | Description | Type |
|----------|-------------|------|
| `baseUrl` | Base URL for TMF API endpoints | Secret |
| `authUrl` | OAuth 2.0 token endpoint | Secret |
| `clientId` | OAuth client identifier | Secret |
| `clientSecret` | OAuth client secret | Secret |
| `audience` | OAuth audience/resource identifier | Secret |
| `grantType` | OAuth grant type (client_credentials) | Secret |
| `accessToken` | Current OAuth access token (auto-managed) | Secret |
| `tokenExpiration` | Token expiration timestamp (auto-managed) | Secret |
| `bankHolidays` | Array of bank holiday dates in ISO 8601 format | Default |
| `firstAvailableStartDateTime` | Extracted slot start time (auto-managed) | Any |
| `firstAvailableEndDateTime` | Extracted slot end time (auto-managed) | Any |

### Sample Environment Setup

```json
{
  "baseUrl": "https://api.staging.example.com",
  "authUrl": "https://auth.staging.example.com",
  "clientId": "your-client-id",
  "clientSecret": "your-client-secret",
  "audience": "https://api.staging.example.com",
  "grantType": "client_credentials",
  "bankHolidays": "[\"2025-01-01\",\"2025-04-18\",\"2025-04-21\",\"2025-05-05\",\"2025-05-26\",\"2025-08-25\",\"2025-12-25\",\"2025-12-26\"]"
}
```

## Usage

### Prerequisites

- Postman Desktop or Newman CLI
- Valid OAuth credentials for staging environment
- Network access to staging API endpoints

### Running Tests in Postman

1. Import the collection file:
   ```
   TMF646_Appointment_External_-_v1_1-_Staging_postman_collection.json
   ```

2. Import the environment file:
   ```
   CityFibre_TMF_-_Staging_New_postman_environment.json
   ```

3. Configure environment variables (secrets must be populated)

4. Run the collection:
   - Select "API Automation" folder
   - Click "Run" to execute all test scenarios
   - Monitor test results in the Collection Runner

### Running Tests with Newman

```bash
# Install Newman
npm install -g newman

# Run collection with environment
newman run TMF646_Appointment_External_-_v1_1-_Staging_postman_collection.json \
  --environment CityFibre_TMF_-_Staging_New_postman_environment.json \
  --env-var "clientId=your-client-id" \
  --env-var "clientSecret=your-client-secret" \
  --reporters cli,json \
  --reporter-json-export results.json

# Run specific folder only
newman run TMF646_Appointment_External_-_v1_1-_Staging_postman_collection.json \
  --folder "LeadTimeValidation" \
  --environment CityFibre_TMF_-_Staging_New_postman_environment.json
```

### CI/CD Integration

```yaml
# Example GitHub Actions workflow
name: API Regression Tests

on:
  push:
    branches: [ staging ]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Newman
        run: npm install -g newman
        
      - name: Run Postman Collection
        env:
          CLIENT_ID: ${{ secrets.STAGING_CLIENT_ID }}
          CLIENT_SECRET: ${{ secrets.STAGING_CLIENT_SECRET }}
        run: |
          newman run TMF646_Appointment_External_-_v1_1-_Staging_postman_collection.json \
            --environment CityFibre_TMF_-_Staging_New_postman_environment.json \
            --env-var "clientId=$CLIENT_ID" \
            --env-var "clientSecret=$CLIENT_SECRET" \
            --reporters cli,junit \
            --reporter-junit-export results.xml
            
      - name: Publish Test Results
        uses: dorny/test-reporter@v1
        if: always()
        with:
          name: API Test Results
          path: results.xml
          reporter: java-junit
```

## API Endpoints

### SearchTimeSlot
```http
POST {{baseUrl}}/tmf-api/v5/appointmentManagement/v1/searchTimeSlot?Fields=id,name
Content-Type: application/json
Authorization: Bearer {{accessToken}}
```

**Request Body**:
```json
{
  "@type": "SearchTimeSlot",
  "requestedTimeSlot": [{
    "validFor": {
      "startDateTime": "2025-02-05T08:00:00.000Z"
    },
    "@type": "RequestedTimeSlot"
  }],
  "relatedParty": {
    "role": "Customer",
    "@type": "RelatedParty",
    "partyOrPartyRole": {
      "id": "BUS001",
      "name": "Business Customer",
      "@type": "PartyRef",
      "@referredType": "Business"
    }
  },
  "appointmentType": "Installation",
  "ispMigration": false,
  "reappointment": false,
  "relatedPlace": {
    "role": "InstallationAddress",
    "@type": "RelatedPlaceRefOrValue",
    "place": {
      "id": "GA001",
      "@type": "PlaceRef",
      "@referredType": "GeographicAddress"
    }
  },
  "relatedEntity": [{
    "role": "Product",
    "@type": "RelatedEntity",
    "entity": {
      "id": "FTTP_1000",
      "name": "FTTP 1000Mbps",
      "@type": "EntityRef",
      "@referredType": "Product"
    }
  }]
}
```

**Response (Success)**:
```json
{
  "@type": "SearchTimeSlot",
  "searchResult": "success",
  "searchDate": "2025-02-04T10:30:00.000Z",
  "availableTimeSlot": [
    {
      "@type": "AvailableTimeSlot",
      "validFor": {
        "startDateTime": "2025-02-20T08:00:00.000Z",
        "endDateTime": "2025-02-20T12:00:00.000Z"
      }
    }
  ]
}
```

### Appointment
```http
POST {{baseUrl}}/tmf-api/v5/appointmentManagement/v1/appointment
Content-Type: application/json
Authorization: Bearer {{accessToken}}
```

**Request Body**:
```json
{
  "@type": "Appointment",
  "category": "Installation",
  "description": "FTTP Installation Appointment",
  "validFor": {
    "startDateTime": "{{firstAvailableStartDateTime}}",
    "endDateTime": "{{firstAvailableEndDateTime}}"
  },
  "externalId": [{
    "@type": "ExternalIdentifier",
    "owner": "CityFibre",
    "externalIdentifierType": "OrderId",
    "id": "ORD-12345"
  }],
  "appointmentType": "Installation",
  "ispMigration": false,
  "reappointment": false
}
```

**Response (Success)**:
```json
{
  "@type": "Appointment",
  "id": "APT-67890",
  "status": "reserved",
  "creationDate": "2025-02-04T10:30:00.000Z",
  "validFor": {
    "startDateTime": "2025-02-20T08:00:00.000Z",
    "endDateTime": "2025-02-20T12:00:00.000Z"
  }
}
```

## Test Results Interpretation

### Success Criteria

- ✅ All HTTP status codes are 200/201 for valid requests
- ✅ Response schemas match expected structure (AJV validation)
- ✅ Lead time calculations meet minimum business day requirements
- ✅ Extracted slots successfully used in appointment creation
- ✅ No weekend or bank holiday appointments returned
- ✅ OAuth token refresh occurs automatically

### Common Failure Scenarios

| Failure | Possible Cause | Resolution |
|---------|---------------|------------|
| 401 Unauthorized | Expired/invalid token | Verify OAuth credentials in environment |
| 400 Bad Request | Schema validation failure | Check request payload against schema |
| Lead time validation fails | Bank holiday data outdated | Update `bankHolidays` environment variable |
| No available slots returned | Invalid geographic address | Verify `relatedPlace` entity exists |
| Appointment creation fails | Slot already reserved | Re-run SearchTimeSlot to get fresh slots |

## Dependencies

### Runtime Dependencies
- **Postman** >= 10.0 (for Collection Runner)
- **Newman** >= 6.0 (for CLI execution)
- **Node.js** >= 18.0 (for Newman)

### Test Script Libraries
- **AJV** 6.12.6 - JSON Schema validation
- **Moment.js** 2.29.4 - Date/time manipulation
- **Lodash** 4.17.21 - Utility functions (implicit in Postman)

## Contributing

1. Clone the repository
2. Create a feature branch (`feature/new-test-scenario`)
3. Add new test scenarios in appropriate folders
4. Update this README with new test coverage
5. Submit pull request with test results screenshot

## API Documentation

- [TMF646 Appointment Management API Specification](https://www.tmforum.org/resources/specification/tmf646-appointment-api-rest-specification-r19-5-0/)
- CityFibre Internal API Documentation: Contact API team for access

## License

Proprietary - CityFibre Limited

## Contact

For questions or issues with this automation suite:
- API Team: api-team@cityfibre.com
- QA Team: qa-automation@cityfibre.com

---

**Last Updated**: February 2025  
**Collection Version**: v1.1  
**API Version**: TMF646 v5
