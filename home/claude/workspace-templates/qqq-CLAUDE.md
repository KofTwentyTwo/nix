# QQQ — Project-Level CLAUDE.md

> Drop-in for `~/Git.Local/QRun-IO/qqq/CLAUDE.md`. This file holds the QQQ-specific architecture rules and Java-style guidance that previously lived in `~/.ai/3-rules.md` (sections 14-15) and `~/.ai/2-coding-style.md` (Java/QQQ patterns). Per the new user-level rules (`~/.ai/3-rules.md` section 16), QQQ-specific conventions live here so they apply only to this repo.

---

## What this is

QQQ is an open-source low-code application framework (AGPL) for engineers, maintained by Kingsrook, LLC under the QRun-IO GitHub org. It is multi-module Maven, Java 17+, with a meta-data-driven architecture.

## Tracker

- GitHub Issues for QQQ public work: `https://github.com/QRun-IO/qqq/issues`
- Internal Jira (Kingsrook private work): `<URL>` if applicable
- Commit references: `(#45)` in subject or `Closes #45` in body for GitHub-tracked work

## Build / test / run

```bash
mvn clean install                     # full build + tests
mvn test                              # unit tests
mvn verify                            # unit + integration tests
mvn test -Dtest=ClassName             # single test class
mvn checkstyle:check                  # style enforcement
mvn dependency:tree                   # transitive dep map
```

## Architecture Principles (BINDING)

### Core defines interfaces; implementations register

The fundamental QQQ pattern: **`qqq-backend-core` defines interfaces; qbits/modules provide implementations.**

MUST NOT:
- Have core know about specific implementations (even reflectively).
- Use reflection to call implementation-specific classes from core.
- Create "helper" classes in core that reach out to optional modules.

MUST:
- Define interfaces in `qqq-backend-core`.
- Have implementations register themselves with core on startup.
- Allow multiple implementations to coexist.
- Use dependency injection or service registration patterns.

### Reflection is a last resort

Prefer interfaces with registration, SPI via `ServiceLoader`, or direct dependencies.

### Module dependency direction

Dependencies flow **toward** core, never away. Core MUST NOT depend on qbits, even reflectively.

### Interface + Registry Pattern

When core needs optional functionality from a qbit:

1. Define interface in core (e.g., `QSessionStoreProviderInterface`).
2. Create singleton registry in core (e.g., `QSessionStoreRegistry`).
3. QBit implements interface and registers on startup.
4. Core uses registry with graceful fallback.

Existing registries: `SpaNotFoundHandlerRegistry`, `QSessionStoreRegistry`.

---

## Specialized QQQ Patterns

### MetaDataProducers
- One meta-data object per class.
- Include `public static final String NAME` constant.
- Use `lowerCaseFirstCamelStyle` for NAME values.
- Class name format: `{Name}{Type}MetaDataProducer`.
- Place in appropriate metadata subpackage.

### RecordEntities
- Create for almost all tables in QQQ core/apps.
- Use `@QMetaDataProducingEntity` annotation when appropriate.
- Include `TABLE_NAME` constant.
- Follow fluent-style setter pattern (`.withX()`).
- Use wrapper types for all fields (`Integer`, `Boolean`, `Long`).

### Processes
- Name with verb + noun phrase (e.g., `cancelOrderProcess`).
- Implement appropriate step interfaces (`Transform`, `Validation`, etc.).
- Use MetaDataProducer pattern for process definitions.

### QInstanceValidator
- ALL new metadata additions MUST have corresponding validation in `QInstanceValidator`.
- Validate: name consistency, required fields, code references.

### Testing Patterns
- `BaseTest` handles cleanup: no need for `@AfterEach` tearDown.
- `BaseTest`'s `baseBeforeEach`/`baseAfterEach` clear `QContext` and reset `MemoryRecordStore`.

### Functional Interfaces
- Use existing interfaces from `com.kingsrook.qqq.backend.core.utils.lambdas`.
- MUST NOT create private functional interfaces when existing ones work.

### Multi-Auth Support
- QQQ supports multiple authentication modules via `AuthScope`.
- Operations like logout SHOULD iterate over ALL registered auth modules.

### V1 Middleware Endpoint Specs (qqq-middleware-javalin)

Each v1 API endpoint requires 5 artifacts following this pattern:

```
specs/v1/YourSpecV1.java               # defineBasicOperation, defineRequestParameters, buildInput, handleOutput
specs/v1/responses/YourResponseV1.java # implements YourOutputInterface + ToSchema
executors/YourExecutor.java            # extends AbstractMiddlewareExecutor, calls QQQ core actions
executors/io/YourInput.java            # extends AbstractMiddlewareInput, request POJO
executors/io/YourOutputInterface.java  # extends AbstractMiddlewareOutputInterface, setter interface
```

- Register in `MiddlewareVersionV1.java` static block.
- Binary streaming endpoints (export, download) override `handleOutput()` instead of using JSON.
- Permission checks go in executors via `PermissionsHelper.checkTablePermissionThrowing()`.
- Always set `QInputSource.USER` on core action inputs.
- For async work (export), use `QContext.capture()` before spawning threads, `QContext.init()` + `QContext.clear()` inside.

---

## Java Style (QQQ)

### Formatting
- **Indentation:** 3 spaces (enforced by Checkstyle).
- **Braces:** opening brace on next line.
- **Line length:** no hard limit; use fluent-style breaks.
- **Blank lines:** max 1 inside method bodies; 3 between methods.

### Primitives
- **Always use wrapper types** (`Integer`, `Boolean`, `Long`) over primitives.
- Exception: performance-critical loops only after profiling.
- Reason: database values can be null; consistency matters.

### Comparisons
```java
// Use .equals() for numbers
if (count.equals(10)) { ... }                    // ✓

// Use Objects.equals() for null-safety
if (Objects.equals(value1, value2)) { ... }      // ✓

// Avoid == for objects
if (count == 10) { ... }                         // ✗ Integer caching
```

### Fluent Style
```java
Order order = new Order()
   .withCustomerId(customerId)
   .withOrderDate(LocalDate.now())
   .withStatus(OrderStatus.PENDING);
```

### Imports

Order (Checkstyle enforces):
1. `javax.*`
2. `java.*`
3. Third-party
4. Static imports

```java
import javax.sql.DataSource;

import java.time.LocalDate;
import java.util.List;

import com.kingsrook.qqq.backend.core.model.actions.tables.query.QQueryFilter;
import org.junit.jupiter.api.Test;

import static com.kingsrook.qqq.backend.core.logging.LogPair.logPair;
import static org.assertj.core.api.Assertions.assertThat;
```

No wildcard imports.

### Boolean Conventions

For nullable Boolean fields, use `BooleanUtils.isTrue()`:

```java
import org.apache.commons.lang3.BooleanUtils;

// Correct
if (BooleanUtils.isTrue(handler.getEnabled())) { ... }

// Wrong (verbose, error-prone)
if (Boolean.TRUE.equals(handler.getEnabled()) || handler.getEnabled() == null) { ... }
```

Convention: `enabled == null` is treated as `false` (disabled by default).

### Naming
- **QQQ Fields:** `lowerCaseFirstCamelStyle` — `firstName`, `orderDate`.
- **QQQ MetaData Names:** `lowerCaseFirstCamelStyle` — `cancelOrderProcess`, `orderTable`.

---

## Comment Style (QQQ Flower-Box)

### Class-level Javadoc

```java
/*******************************************************************************
 ** Transform step for process that evaluates orders.
 **
 ** This step performs validation and scoring of orders based on business rules
 ** defined in the OrderEvaluationRules table.
 *******************************************************************************/
public class EvaluateOrdersTransformStep implements AbstractTransformStep
{
   // ...
}
```

### Method-level Javadoc

```java
/*******************************************************************************
 ** Execute the order evaluation logic for a single record.
 **
 ** @param record the order record to evaluate
 ** @return the evaluation score (0-100)
 ** @throws QException if evaluation rules cannot be loaded
 *******************************************************************************/
public Integer evaluateOrder(QRecord record) throws QException
{
   // ...
}
```

### Inline (within method body)

```java
/////////////////////////////////////////////////////////////////////////
// preload all data that will be needed for optimizations.             //
// note - if we ever "optimize" this to only load the ones needed,     //
// we'd then need to re-fetch/update/clear/etc something               //
/////////////////////////////////////////////////////////////////////////
preloadOrderData(runBackendStepInput);
```

### Fluent Setter Javadoc

```java
/*******************************************************************************
 ** Fluent setter for customerId
 **
 ** @param customerId the customer who placed this order
 *******************************************************************************/
public Order withCustomerId(Integer customerId)
{
   this.customerId = customerId;
   return (this);
}
```

### Don't
- No HTML in Javadoc (read in IDE, not rendered).
- No `/* ... */` style within method bodies — use flower-box.
- No zombie code without explanation.
- No emojis anywhere.

---

## Logging (QQQ uses QLogger)

```java
private static final QLogger LOG = QLogger.getLogger(OrderService.class);

// Info — normal operations
LOG.info("Processing order", logPair("orderId", orderId), logPair("customerId", customerId));

// Warn — recoverable issues (95% of error logging)
// CRITICAL: exception comes BEFORE logPairs
LOG.warn("Failed to send notification", e, logPair("orderId", orderId));   // ✓
LOG.warn("Failed to send notification", logPair("orderId", orderId), e);   // ✗

// Error — critical failures (5%)
LOG.error("Database connection failed", e);
```

Always use LogPair for structured logging — no string concatenation. Never `System.out.println`, `System.err.println`, or `e.printStackTrace()`.

---

## Test Coverage

- 70% instruction coverage minimum.
- 90% class coverage minimum.
- Enforced by Maven Jacoco plugin.
- Test naming: `test{MethodName}_{scenario}_{expectedOutcome}`.

---

## Reference

- **Authoritative style:** `~/Git.Local/QRun-IO/qqq/CODE_STYLE.md`
- **Contributing:** `~/Git.Local/QRun-IO/qqq/CONTRIBUTING.md`
- **Checkstyle config:** `~/Git.Local/QRun-IO/qqq/checkstyle/config.xml`
