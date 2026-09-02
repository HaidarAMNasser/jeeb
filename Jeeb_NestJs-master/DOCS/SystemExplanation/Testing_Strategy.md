# Testing Strategy

## Overview

This project adheres to a clean architecture principle where testing code is separated from the application source code. This separation ensures that the `src` directory remains focused on business logic while the `test` directory houses all verification logic.

## Testing Hierarchy

### 1. Unit Tests

Unit tests are designed to test individual components (Services, Controllers, Helpers) in isolation without external dependencies like databases or external APIs.

- **Location**: `test/unit` (Mirrors the `src` structure)
- **File Extension**: `*.spec.ts`
- **Framework**: [Jest](https://jestjs.io/)
- **Command**: `npm test`
- **Approach**:
  - **Mocking**: Dependencies are mocked to ensure isolation. For example, when testing a Service, the Repository is mocked.
  - **Scope**: Focuses on business logic, edge cases, and error handling within a single function/method.

### 2. End-to-End (E2E) Tests

End-to-End tests verify the system as a whole. They simulate real user interactions by making HTTP requests to the application and checking the responses.

- **Location**: `test/` (Root of the test directory)
- **File Extension**: `*.e2e-spec.ts`
- **Framework**: Jest + [Supertest](https://www.npmjs.com/package/supertest)
- **Command**: `npm run test:e2e`
- **Approach**:
  - **Integration**: Tests the full request lifecycle (Controller -> Service -> Database).
  - **Real Environment**: Often uses a test database to verify actual data persistence.

## Directory Structure

The project follows this structure for separation of concerns:

```plaintext
project-root/
├── src/                # Application Source Code
│   ├── modules/        # Feature Modules
│   └── ...
├── test/               # Testing Root Directory
│   ├── unit/           # Unit Tests Container
│   │   └── modules/    # Unit tests for modules (mirrors src)
│   │       ├── coupons/
│   │       │   ├── coupons.service.spec.ts
│   │       │   └── coupons.controller.spec.ts
│   │       └── discounts/
│   ├── app.e2e-spec.ts # E2E Test Files
│   └── jest-e2e.json   # E2E Configuration
└── package.json        # Contains Jest Configuration for Unit Tests
```

## Configuration

- **Unit Tests Config**: Located in `package.json` under `jest` key. Configured to look for `*.spec.ts` files inside `test/unit`.
- **E2E Tests Config**: Located in `test/jest-e2e.json`. Configured to look for `*.e2e-spec.ts` files inside `test`.
