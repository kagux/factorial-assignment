# Bicycle E-commerce Website Requirements

## Overview
You're tasked with building a website that allows Marcus, a bicycle shop owner, to sell his bicycles online. Marcus owns a growing business and wants to expand to e-commerce. While bicycles are his main product, he anticipates selling other sports-related items in the future (skis, surfboards, roller skates, etc.), so the platform should be extensible.

## Key Feature: Bicycle Customization
Marcus's business thrives on full bicycle customization. Customers can select various options for different bicycle parts.

### Example Parts and Options
- **Frame type:** Full-suspension, diamond, step-through
- **Frame finish:** Matte, shiny
- **Wheels:** Road wheels, mountain wheels, fat bike wheels
- **Rim color:** Red, black, blue
- **Chain:** Single-speed chain, 8-speed chain

### Constraint Management
Some combinations are prohibited due to physical constraints:
- If "mountain wheels" are selected, only full-suspension frames are available
- If "fat bike wheels" are selected, red rim color is unavailable

### Inventory Management
Marcus needs to mark items as "temporarily out of stock" to prevent orders he can't fulfill.

### Price Calculation
The price is calculated by adding individual part prices, with contextual rules:

**Standard calculation example:**
- Full suspension: 130 EUR
- Shiny frame: 30 EUR
- Road wheels: 80 EUR
- Blue rim color: 20 EUR
- Single-speed chain: 43 EUR
- **Total price:** 303 EUR

**Contextual pricing:**
Some options' prices depend on others. For example, frame finish pricing varies by frame type:
- Matte finish on full-suspension frame: 50 EUR
- Matte finish on diamond frame: 35 EUR

## Code Exercise Requirements

### 1. Data Model
Define a data model that supports the application. Include table/document specifications with fields, associations, and entity meanings.

### 2. Main User Actions
Detail the primary actions users would take on this e-commerce website.

### 3. Product Page
- How would you design the UI?
- How would you determine which options are available?
- How would you calculate price based on customer selections?

### 4. Add to Cart Action
- What happens when customers click "add to cart"?
- What data is persisted in the database?

### 5. Administrative Workflows
Describe the main workflows for Marcus to manage his store:

#### Product Creation
- What information is required to create a new product?
- How does the database change?

#### Adding Part Options
- How can Marcus add a new rim color?
- Describe the UI and database changes.

#### Price Management
- How can Marcus change part prices or specify combination pricing?
- How do the UI and database handle this?

## Deliverables
Provide the core model of the solution: classes/functions/modules in your preferred language that describe the main entity relationships, along with supporting materials (database schemas, diagrams, etc.).

Keep the solution lightweight—no need to use web frameworks or provide a finished application. The goal is to see how you model and code the domain logic.

For unspecified system details, use your best judgment.
