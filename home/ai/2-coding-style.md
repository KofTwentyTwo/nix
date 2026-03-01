# Coding Style Guide

> **Single source of truth** for how to write code. Behavioral mandates (MUST/MUST NOT) live in `3-rules.md`. Tuning knobs live in `4-preferences.yaml`. This file is a reference guide only.

This document consolidates coding standards for all languages used in the QQQ project and personal development workflows. For Java-specific QQQ conventions, always reference `/Users/james.maes/Git.Local/QRun-IO/qqq/CODE_STYLE.md` as the authoritative source.

## General Principles

### Code Philosophy
1. **Write for maintainability:** Code is read far more often than written
2. **Be explicit over clever:** Clarity trumps brevity
3. **Follow established patterns:** Consistency is a feature
4. **Document the "why":** Comments should explain reasoning, not just what
5. **Test appropriately:** Unit tests for logic, integration tests for interactions
6. **Automate quality:** Use tooling (Checkstyle, linters) to enforce standards

### Engineering Standards
- **DRY (Don't Repeat Yourself):** Extract common logic, but don't over-abstract
- **YAGNI (You Aren't Gonna Need It):** Don't build for hypothetical futures
- **KISS (Keep It Simple):** Simple solutions are easier to maintain
- **Separation of Concerns:** Each module/class should have a single responsibility
- **Fail Fast:** Validate early, provide clear error messages

---

## Naming Conventions

### General Rules
- **Prefer verbose over abbreviated:** `customerOrderNumber` over `custOrdNum`
- **Be descriptive:** Names should reveal intent
- **Avoid Hungarian notation:** Don't prefix with type abbreviations (~~`strName`~~)
- **Use domain language:** Match business terminology where applicable

### Language-Specific Naming

#### Java
- **Classes:** `PascalCase` - `OrderService`, `CustomerEntity`
- **Methods:** `camelCase` - `processOrder()`, `getCustomerById()`
- **Variables:** `camelCase` - `orderTotal`, `customerList`
- **Constants:** `UPPER_SNAKE_CASE` - `MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT`
- **Packages:** `lowercase.dotted` - `com.kingsrook.qqq.backend.core`
- **QQQ Fields:** `lowerCaseFirstCamelStyle` - `firstName`, `orderDate`
- **QQQ MetaData Names:** `lowerCaseFirstCamelStyle` - `cancelOrderProcess`, `orderTable`

#### Nix
- **Attributes:** `camelCase` - `homeDirectory`, `userName`
- **Packages:** `kebab-case` - `qqq-dev-tools`, `nix-darwin`
- **Files:** `kebab-case.nix` - `home-manager.nix`, `user-config.nix`

#### Shell (Bash/Zsh)
- **Variables:** `UPPER_SNAKE_CASE` - `USER_HOME`, `LOG_FILE`
- **Functions:** `snake_case` - `check_dependencies()`, `load_config()`
- **Files:** `kebab-case.sh` - `install-deps.sh`, `check-updates.sh`

#### Rust
- **Types/Structs:** `PascalCase` - `OrderProcessor`, `ConfigLoader`
- **Functions:** `snake_case` - `process_order()`, `load_config()`
- **Variables:** `snake_case` - `order_total`, `customer_list`
- **Constants:** `UPPER_SNAKE_CASE` - `MAX_CONNECTIONS`, `DEFAULT_PORT`

#### Python
- **Classes:** `PascalCase` - `DataProcessor`, `ConfigManager`
- **Functions:** `snake_case` - `process_data()`, `load_config()`
- **Variables:** `snake_case` - `user_name`, `order_list`
- **Constants:** `UPPER_SNAKE_CASE` - `MAX_RETRIES`, `API_URL`
- **Private:** `_leading_underscore` - `_internal_method()`

---

## File & Project Structure

### Java (Maven Multi-Module)
```
project/
├── pom.xml                          # Parent POM
├── module-name/
│   ├── pom.xml                      # Module POM
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/
│   │   │   │   └── com/kingsrook/qqq/module/
│   │   │   │       ├── metadata/    # MetaDataProducers
│   │   │   │       ├── model/       # RecordEntities
│   │   │   │       ├── actions/     # Action implementations
│   │   │   │       └── ...
│   │   │   └── resources/
│   │   └── test/
│   │       ├── java/                # Unit tests mirror main structure
│   │       └── resources/
```

### Nix Configuration
```
~/config/nix/
├── flake.nix                        # Main flake definition
├── flake.lock                       # Locked dependencies
├── home/
│   ├── default.nix                  # Home Manager entry point
│   ├── module-name/
│   │   ├── default.nix              # Module definition
│   │   ├── config/                  # Configuration files
│   │   └── scripts/                 # Helper scripts
```

---

## Comments & Documentation Standards

### Java Comments (QQQ Style)

#### Class-Level Javadoc (Flower Box)
```java
/*******************************************************************************
 ** Transform step for process that evaluates orders.
 ** 
 ** This step performs validation and scoring of orders based on business rules
 ** defined in the OrderEvaluationRules table. Results are stored in the 
 ** orderScore field and used downstream for prioritization.
 *******************************************************************************/
public class EvaluateOrdersTransformStep implements AbstractTransformStep
{
   // ... implementation
}
```

**Key Features:**
- Line 1: `/*` + 78 stars
- Content lines: ` **` prefix, ` */` suffix (aligned at column 80)
- Last line: ` ` + 78 stars + `*/`
- No blank line after the comment

#### Method-Level Javadoc
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

#### Inline Comments (Flower Box)
```java
/////////////////////////////////////////////////////////////////////////
// preload all data that will be needed for optimizations.             //
// note - if we ever "optimize" this to only load the ones needed ("on //
// this page"), we'd then need to re-fetch/update/clear/etc something  //
/////////////////////////////////////////////////////////////////////////
preloadOrderData(runBackendStepInput);
```

**Key Features:**
- First/last lines: all `/` characters
- Content lines: `//` prefix, `//` suffix (right-padded to equal length)
- Used within method bodies
- Explain complex logic, architectural decisions, or non-obvious choices

#### What NOT to Do
- ❌ No "zombie code" (commented-out code without explanation)
- ❌ No obvious comments ("increment i" for `i++`)
- ❌ No HTML in Javadoc (we read in IDE, not as rendered HTML)
- ❌ Don't use `/* ... */` style within method bodies (use flower boxes)

### Nix Comments
```nix
# Single-line comments for brief explanations
homeDirectory = "/Users/${username}";

# Multi-line comments for complex logic
# This path is used across multiple modules and must remain
# consistent with the systemd service configuration
qqqDevTools = "${homeDirectory}/Git.Local/QRun-IO/qqq/qqq-dev-tools";
```

### Shell Comments
```bash
#!/usr/bin/env bash
# Script: check-updates.sh
# Purpose: Check for available Homebrew and Nix updates
# Usage: ./check-updates.sh

# Configuration
LOG_FILE="${HOME}/.local/log/updates.log"

# Main logic
check_brew_updates() {
   # Check for outdated Homebrew packages
   # Returns: 0 if updates available, 1 otherwise
   brew outdated --quiet
}
```

---

## Error Handling

### Java
```java
// Prefer specific exceptions
throw new QUserFacingException("Order #" + orderId + " not found");

// Use try-with-resources for resource management
try (Connection conn = dataSource.getConnection())
{
   // ...
}
catch (SQLException e)
{
   LOG.error("Database error processing order", logPair("orderId", orderId), e);
   throw new QException("Failed to process order", e);
}

// Validate early
if (order == null)
{
   throw new QException("Order cannot be null");
}
```

### Rust
```rust
// Use Result<T, E> for recoverable errors
fn process_order(id: OrderId) -> Result<Order, ProcessError> {
    let order = load_order(id)?;
    validate_order(&order)?;
    Ok(order)
}

// Use Option<T> for optional values
fn find_customer(id: CustomerId) -> Option<Customer> {
    // ...
}

// Provide context with context() or with_context()
load_config()
    .context("Failed to load application configuration")?;
```

### Python
```python
# Use specific exceptions
raise ValueError(f"Invalid order ID: {order_id}")

# Use context managers
with open(config_path, 'r') as f:
    config = json.load(f)

# Use Optional for type hints
from typing import Optional

def find_customer(id: str) -> Optional[Customer]:
    # ...
```

---

## Logging Conventions

### Java (QLogger)
```java
private static final QLogger LOG = QLogger.getLogger(OrderService.class);

// Info level - normal operations
LOG.info("Processing order", logPair("orderId", orderId), logPair("customerId", customerId));

// Debug level - detailed flow information
LOG.debug("Order validation passed", logPair("orderId", orderId), logPair("validations", validationCount));

// Warn level - recoverable issues (95% of error logging)
// CRITICAL: Exception comes BEFORE logPairs, not after!
LOG.warn("Failed to send notification", e, logPair("orderId", orderId));  // ✓ Correct
LOG.warn("Failed to send notification", logPair("orderId", orderId), e);  // ❌ WRONG - exception won't log properly

// Error level - critical failures (5% of error logging)
LOG.error("Database connection failed", e);

// Always use LogPair for structured logging (enables JSON in log aggregator)
// Avoid: LOG.info("Processing order " + orderId); // ❌ String concatenation
// Prefer: LOG.info("Processing order", logPair("orderId", orderId)); // ✓
```

**Log Levels:**
- **TRACE:** Extremely detailed flow (rarely used)
- **DEBUG:** Detailed diagnostic information
- **INFO:** Normal application flow
- **WARN:** Recoverable issues requiring attention (95% of problems)
- **ERROR:** Critical failures requiring immediate action (5% of problems)

**Never Use:**
- ❌ `System.out.println()`
- ❌ `System.err.println()`
- ❌ `e.printStackTrace()`

---

## Boolean Conventions

### Nullable Boolean Checks
Use `BooleanUtils.isTrue()` for nullable Boolean fields instead of complex null-safe comparisons:
```java
// CORRECT - use BooleanUtils.isTrue()
import org.apache.commons.lang3.BooleanUtils;
if (BooleanUtils.isTrue(handler.getEnabled())) { ... }

// WRONG - verbose and error-prone
if (Boolean.TRUE.equals(handler.getEnabled()) || handler.getEnabled() == null) { ... }
```

**Convention:** `enabled == null` should be treated as `false` (disabled by default).

---

## Git Commit Message Standards

### Format (Conventional Commits)
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- **feat:** New feature
- **fix:** Bug fix
- **docs:** Documentation changes
- **style:** Code style changes (formatting, no logic change)
- **refactor:** Code refactoring (no feature change)
- **test:** Adding or updating tests
- **chore:** Build process, dependencies, tooling

### Examples
```
feat(javalin): add support for multiple SPAs

Implement RouteProviderMetaData extension to support multiple isolated
single-page applications within a single Javalin instance. Each SPA can
have its own route prefix and static file location.

Closes #123
```

```
fix(backend-core): handle null values in RecordEntity serialization

Added null checks in the toJSON() method to prevent NullPointerException
when serializing entities with unset optional fields.
```

```
docs(wiki): update MetaDataProducer naming conventions

Clarified naming standards for MetaDataProducer classes and added
examples for each meta-data type.
```

### Signing Commits
All commits must be GPG-signed. The signing key is configured in the user's global git config and MUST NOT be hardcoded in documentation or scripts.

---

## Language-Specific Guidelines

### Java

#### Formatting
- **Indentation:** 3 spaces (enforced by Checkstyle)
- **Braces:** Opening brace on next line
  ```java
  if (condition)
  {
     // code
  }
  ```
- **Line Length:** No hard limit, but be reasonable (use fluent-style breaks)
- **Blank Lines:** 
  - Maximum 1 blank line within method bodies
  - 3 blank lines between methods
  - 3 blank lines between classes in same file (avoid if possible)

#### Primitive Types
- **Always use wrapper types** (`Integer`, `Boolean`, `Long`) over primitives (`int`, `boolean`, `long`)
- Exception: Performance-critical loops (only after profiling)
- Reason: Database values can be null; consistency is key

#### Comparisons
```java
// Use .equals() for numbers
if (count.equals(10)) { ... }  // ✓

// Use Objects.equals() for null-safety
if (Objects.equals(value1, value2)) { ... }  // ✓

// Avoid == for objects
if (count == 10) { ... }  // ❌ Can fail due to Integer caching
```

#### Fluent Style
```java
// Prefer fluent style
Order order = new Order()
   .withCustomerId(customerId)
   .withOrderDate(LocalDate.now())
   .withStatus(OrderStatus.PENDING);

// Avoid setter chains
Order order = new Order();  // ❌
order.setCustomerId(customerId);
order.setOrderDate(LocalDate.now());
order.setStatus(OrderStatus.PENDING);
```

#### Imports
```java
// Import order (Checkstyle enforces):
// 1. javax.*
// 2. java.*
// 3. Third-party
// 4. Static imports

import javax.sql.DataSource;

import java.time.LocalDate;
import java.util.List;

import com.kingsrook.qqq.backend.core.model.actions.tables.query.QQueryFilter;
import org.junit.jupiter.api.Test;

import static com.kingsrook.qqq.backend.core.logging.LogPair.logPair;
import static org.assertj.core.api.Assertions.assertThat;

// Never use wildcard imports
import java.util.*;  // ❌
```

#### Method Length
- Balance between 1000-line methods and 100 10-line methods
- Target: 20-50 line methods for most code
- Extract when complexity grows, not just for extraction's sake

#### QQQ-Specific Patterns

**MetaDataProducers:**
```java
/*******************************************************************************
 ** MetaData producer for the Order table.
 *******************************************************************************/
public class OrderTableMetaDataProducer implements MetaDataProducerInterface<QTableMetaData>
{
   public static final String NAME = "order";  // lowerCaseFirstCamelStyle

   @Override
   public QTableMetaData produce(QInstance qInstance) throws QException
   {
      return new QTableMetaData()
         .withName(NAME)
         .withRecordClass(Order.class)
         .withPrimaryKeyField("id")
         .withFields(List.of(
            // ... fields
         ));
   }
}
```

**RecordEntities:**
```java
/*******************************************************************************
 ** Record entity for the Order table.
 *******************************************************************************/
@QMetaDataProducingEntity
public class Order extends QRecord
{
   public static final String TABLE_NAME = "order";

   private Integer id;
   private Integer customerId;
   private LocalDate orderDate;
   private String status;

   // Fluent-style setters
   public Order withId(Integer id) { this.id = id; return this; }
   public Order withCustomerId(Integer customerId) { this.customerId = customerId; return this; }
   // ... more withers
   
   // Getters
   public Integer getId() { return id; }
   public Integer getCustomerId() { return customerId; }
   // ... more getters
}
```

**Fluent Setter Javadoc:**
Include `@param` descriptions in fluent setter Javadoc:
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

**V1 Middleware Endpoint Specs (qqq-middleware-javalin):**
Each v1 API endpoint requires 5 artifacts following this pattern:
```
specs/v1/YourSpecV1.java              <- defineBasicOperation, defineRequestParameters, buildInput, handleOutput
specs/v1/responses/YourResponseV1.java <- implements YourOutputInterface + ToSchema
executors/YourExecutor.java            <- extends AbstractMiddlewareExecutor, calls QQQ core actions
executors/io/YourInput.java            <- extends AbstractMiddlewareInput, request POJO
executors/io/YourOutputInterface.java  <- extends AbstractMiddlewareOutputInterface, setter interface
```
- Register in `MiddlewareVersionV1.java` static block
- Binary streaming endpoints (export, download) override `handleOutput()` instead of using JSON
- Permission checks go in executors via `PermissionsHelper.checkTablePermissionThrowing()`
- Always set `QInputSource.USER` on core action inputs
- For async work (export), use `QContext.capture()` before spawning threads, `QContext.init()` + `QContext.clear()` inside

---

### Rust

#### Formatting
- Use `rustfmt` (default configuration)
- 4-space indentation
- 100-character line length (soft limit)

#### Conventions
```rust
// Use descriptive error types
#[derive(Debug, thiserror::Error)]
pub enum OrderError {
    #[error("Order not found: {0}")]
    NotFound(OrderId),
    
    #[error("Invalid status transition from {from} to {to}")]
    InvalidTransition { from: Status, to: Status },
}

// Prefer impl blocks over scattered implementations
impl Order {
    pub fn new(customer_id: CustomerId) -> Self {
        // ...
    }
    
    pub fn add_item(&mut self, item: OrderItem) -> Result<(), OrderError> {
        // ...
    }
}

// Use builder pattern for complex construction
Order::builder()
    .customer_id(customer_id)
    .order_date(Utc::now())
    .build()?;
```

---

### Python

#### Formatting
- Follow PEP 8
- 4-space indentation
- 88-character line length (Black formatter default)

#### Conventions
```python
# Type hints for public APIs
def process_order(order_id: str, items: List[OrderItem]) -> Order:
    """Process an order with the given items.
    
    Args:
        order_id: Unique identifier for the order
        items: List of items to include in the order
        
    Returns:
        The processed Order object
        
    Raises:
        ValueError: If order_id is invalid or items is empty
    """
    if not items:
        raise ValueError("Order must contain at least one item")
    
    # ...

# Use dataclasses for simple data structures
from dataclasses import dataclass

@dataclass
class Order:
    id: str
    customer_id: str
    items: List[OrderItem]
    total: Decimal
```

---

### Shell (Bash/Zsh)

#### Best Practices
```bash
#!/usr/bin/env bash
# Always use explicit shebang

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Use descriptive variable names in UPPER_SNAKE_CASE
LOG_DIR="${HOME}/.local/log"
CONFIG_FILE="${HOME}/.config/app/config.yaml"

# Quote variable expansions
echo "Processing file: ${FILE_PATH}"

# Use [[ ]] for conditionals (bash/zsh)
if [[ -f "${CONFIG_FILE}" ]]; then
    source "${CONFIG_FILE}"
fi

# Use functions for reusable logic
check_dependencies() {
    local required_cmd="$1"
    if ! command -v "${required_cmd}" &> /dev/null; then
        echo "Error: ${required_cmd} is required but not installed"
        return 1
    fi
}

# Provide usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
EOF
}
```

---

### Nix

#### Style
```nix
# Use descriptive attribute names (camelCase)
{ config, pkgs, lib, ... }:

let
  # Define local variables in let-in blocks
  homeDir = config.home.homeDirectory;
  userName = "james.maes";
in
{
  # Use set notation for clarity
  home = {
    username = userName;
    homeDirectory = homeDir;
    
    # Group related settings
    sessionVariables = {
      EDITOR = "vi";
      PAGER = "less -FR";
    };
    
    # Use lists for packages
    packages = with pkgs; [
      curl
      wget
      htop
    ];
  };
  
  # Use home.file for generated files
  home.file.".ai/profile.md".text = ''
    # Profile content here
  '';
  
  # Use home.file.source for existing files
  home.file.".ai/preferences.yaml".source = ./preferences.yaml;
}
```

---

## Testing Standards

### Java (JUnit)
```java
/*******************************************************************************
 ** Test class for OrderService.
 *******************************************************************************/
class OrderServiceTest
{
   private OrderService orderService;
   private MockOrderRepository orderRepository;

   @BeforeEach
   void setUp()
   {
      orderRepository = new MockOrderRepository();
      orderService = new OrderService(orderRepository);
   }

   /*******************************************************************************
    ** Test that a valid order is processed successfully.
    *******************************************************************************/
   @Test
   void testProcessOrder_validOrder_succeeds() throws QException
   {
      // Arrange
      Order order = new Order()
         .withCustomerId(1)
         .withStatus("PENDING");
      
      // Act
      Order result = orderService.processOrder(order);
      
      // Assert
      assertThat(result.getStatus()).isEqualTo("PROCESSED");
      assertThat(result.getProcessedDate()).isNotNull();
   }

   /*******************************************************************************
    ** Test that processing an order with invalid status throws exception.
    *******************************************************************************/
   @Test
   void testProcessOrder_invalidStatus_throwsException()
   {
      // Arrange
      Order order = new Order()
         .withCustomerId(1)
         .withStatus("INVALID");
      
      // Act & Assert
      assertThatThrownBy(() -> orderService.processOrder(order))
         .isInstanceOf(QException.class)
         .hasMessageContaining("Invalid status");
   }
}
```

**Test Naming:** `test{MethodName}_{scenario}_{expectedOutcome}`

**Coverage Requirements:**
- 70% instruction coverage minimum
- 90% class coverage minimum
- Enforced by Maven Jacoco plugin

---

This style guide should be used in conjunction with:
- **QQQ-specific:** `/Users/james.maes/Git.Local/QRun-IO/qqq/CODE_STYLE.md`
- **Contribution guidelines:** `/Users/james.maes/Git.Local/QRun-IO/qqq/CONTRIBUTING.md`
- **Checkstyle config:** `/Users/james.maes/Git.Local/QRun-IO/qqq/checkstyle/config.xml`


