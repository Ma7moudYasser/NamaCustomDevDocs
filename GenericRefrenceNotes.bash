  GenericReference - The Ultimate Guide You'll Never Forget

  The Problem It Solves

  Imagine you're building a "Comments" system. A comment can be attached to:
  - A Customer
  - An Invoice
  - A Product
  - A Purchase Order
  - ...and 50 other entity types

  Without GenericReference, you'd need:
  public class Comment {
      Customer customer;           // null if comment is on Invoice
      Invoice invoice;             // null if comment is on Customer
      Product product;             // null if comment is on Invoice
      PurchaseOrder purchaseOrder; // null if comment is on Customer
      // ... 50 more fields, 49 always null!
  }

  With GenericReference:
  public class Comment {
      GenericReference target;  // Can point to ANY entity!
  }

  ---
  The Real-World Analogy: A Universal Remote Control 🎮

  Think of GenericReference as a universal remote control:

  | Regular Reference                | GenericReference                                        |
  |----------------------------------|---------------------------------------------------------|
  | TV remote - only works with TV   | Universal remote - works with TV, AC, DVD, Sound System |
  | Bank bank; - only points to Bank | GenericReference ref; - points to ANY entity            |

  ---
  How It Works Internally

  A GenericReference stores 4 pieces of information:

  ┌─────────────────────────────────────────────────────────────┐
  │                    GenericReference                          │
  ├─────────────────────────────────────────────────────────────┤
  │  id         = "ABC123"          (the unique ID)             │
  │  entityType = "Customer"        (what KIND of entity)       │
  │  code       = "CUST-001"        (display code)              │
  │  actualCode = "CUST-001"        (original code)             │
  └─────────────────────────────────────────────────────────────┘

  Database columns generated:
  -- For field: GenericReference owner;
  ownerEntityType VARCHAR(50)   -- "LGTIssue" or "LoanIssue" or "LGTClosing"
  ownerId         BINARY(16)    -- The actual ID
  ownerCode       VARCHAR(50)   -- Display code
  ownerActualCode VARCHAR(50)   -- Original code

  ---
  Three Types of GenericReference Usage

  Type 1: Unrestricted (Wild Card) - Can Point to ANYTHING

  // In FacilityLimit.java
  GenericReference ref6;
  GenericReference ref7;

  Use Case: Flexible "custom fields" that customers can configure to link to any entity they want.

  Memory Trick: Like a blank sticky note - write whatever you want!

  ---
  Type 2: Restricted (Constrained) - Limited Options

  // In FacilityLimitSysEntry.java
  @NaMaField(allowedValues = { ACCEntities.LGTIssue, ACCEntities.LoanIssue, ACCEntities.LGTClosing })
  GenericReference owner;

  What this means: The owner field can ONLY hold:
  - LGTIssue (Letter of Guarantee Issue)
  - LoanIssue (Loan Issue)
  - LGTClosing (Letter of Guarantee Closing)

  Memory Trick: Like a parking spot marked "Compact Cars Only" - limited options!

  Visual Example:
  owner field can be:
     ✅ LGTIssue#123
     ✅ LoanIssue#456
     ✅ LGTClosing#789
     ❌ Customer#001      (NOT ALLOWED)
     ❌ Invoice#002       (NOT ALLOWED)

  ---
  Type 3: Typed Reference (Specific Entity)

  // In FacilityLimit.java
  Bank bank;  // This is NOT a GenericReference

  What this means: The bank field can ONLY hold a Bank entity. Period.

  Memory Trick: Like a key that only fits one lock!

  ---
  When to Use Which?

  | Scenario                                       | Use                           | Example                                                 |
  |------------------------------------------------|-------------------------------|---------------------------------------------------------|
  | Field always links to ONE specific entity type | Direct Reference              | Bank bank;                                              |
  | Field links to a FEW known entity types        | Restricted GenericReference   | @NaMaField(allowedValues={...}) GenericReference owner; |
  | Field can link to ANYTHING (user configurable) | Unrestricted GenericReference | GenericReference ref6;                                  |

  ---
  FacilityLimitSysEntry - A Perfect Example

  public class FacilityLimitSysEntry {

      // TYPE 1: Unrestricted - could be anything
      GenericReference facilityLimit;
      GenericReference projContract;

      // TYPE 2: Restricted - only specific documents can "own" this entry
      @NaMaField(allowedValues = { LGTIssue, LoanIssue, LGTClosing })
      GenericReference owner;

      // TYPE 2: Restricted - only specific "files" can be targeted
      @NaMaField(allowedValues = { LetterOfGuarantee, BankLoan })
      GenericReference targetFile;
  }

  Real Data Example:
  FacilityLimitSysEntry Record:
  ┌──────────────────────────────────────────────────────────────┐
  │ facilityLimit = FacilityLimit#FL-001                         │
  │ owner         = LGTIssue#LGT-2024-001    ← The document that │
  │                                             created this     │
  │ targetFile    = LetterOfGuarantee#LG-001 ← The LG being used│
  │ amount        = 100,000                                      │
  │ projContract  = ProjectContract#PC-005   ← Optional link    │
  └──────────────────────────────────────────────────────────────┘

  ---
  How to Use GenericReference in Code

  Creating a GenericReference:

  // From an entity
  GenericReference ref = GenericReference.create(customer);

  // From ID and type
  GenericReference ref = GenericReference.create("ABC123", "Customer");

  Reading the actual entity:

  GenericReference ownerRef = entry.getOwner();

  // Get the actual entity (could be LGTIssue, LoanIssue, or LGTClosing)
  BaseEntity owner = ownerRef.toReal();

  // Check what type it is
  if (ownerRef.getEntityType().equals("LGTIssue")) {
      LGTIssue lgtIssue = (LGTIssue) owner;
      // do something with LGT Issue
  }

  Querying:

  // Find all entries where owner is a specific document
  CriteriaBuilder.create()
      .field("owner.id").equal(someDocument.getId())
      .field("owner.entityType").equal("LGTIssue")

  ---
  The Memory Palace 🏰

  Picture a hotel with different room types:

  | Room Type                                                     | Analogy                       | Java Field                      |
  |---------------------------------------------------------------|-------------------------------|---------------------------------|
  | Suite 101 - Only VIPs                                         | Direct Reference              | Bank bank;                      |
  | Conference Room - Only employees from Marketing, Sales, or HR | Restricted GenericReference   | @NaMaField(allowedValues={...}) |
  | Public Lobby - Anyone can enter                               | Unrestricted GenericReference | GenericReference ref;           |

  ---
  Summary Table

  | Aspect       | Direct Reference | Restricted GenericReference                         | Unrestricted GenericReference  |
  |--------------|------------------|-----------------------------------------------------|--------------------------------|
  | Declaration  | Bank bank;       | @NaMaField(allowedValues={A,B}) GenericReference x; | GenericReference x;            |
  | Can point to | Only Bank        | Only A or B                                         | Anything                       |
  | Type safety  | Compile-time     | Runtime                                             | None                           |
  | Use when     | Always same type | Known limited types                                 | User-configurable              |
  | DB columns   | 1 (foreign key)  | 4 (id, type, code, actualCode)                      | 4 (id, type, code, actualCode) |

  ---
  Golden Rules to Remember Forever

  1. GenericReference = Polymorphic Foreign Key - One field, many possible targets
  2. Use allowedValues to restrict - Don't leave it wide open unless needed
  3. 4 columns in database - entityType, id, code, actualCode
  4. Call .toReal() to get actual entity - Returns the real object
  5. Check .getEntityType() before casting - Know what you're dealing with