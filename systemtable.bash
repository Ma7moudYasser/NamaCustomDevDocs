  What is a System Table?

  A System Table (or LocalEntity) is an internal tracking table that the system uses automatically behind the scenes. Users don't interact with it directly - it stores calculated/derived data that supports other features.

  Think of it like: A ledger that automatically records entries when documents are saved.

  ---
  Line-by-Line Breakdown

  Line 9: @NaMaValueObject(localEntity = true)

  @NaMaValueObject(localEntity = true)
  | Part               | Meaning                                                                                               |
  |--------------------|-------------------------------------------------------------------------------------------------------|
  | @NaMaValueObject   | This is a value object (not a main entity like Customer or Invoice)                                   |
  | localEntity = true | This makes it a System Table - it gets its own database table but is managed by the system, not users |

  Without localEntity = true: The class would be embedded inside another entity (no separate table).

  With localEntity = true: Creates a standalone table (FacilityLimitSysEntry) that can be queried independently.

  ---
  Line 10: @RelatedTranslation

  @RelatedTranslation(id = "facilityLimitRelatedDocs", ar = "السندات المرتبطة بحد التسهيلات", en = "Facility Limit Related Docs")
  | Part | Meaning                                |
  |------|----------------------------------------|
  | id   | Unique identifier for this translation |
  | ar   | Arabic label                           |
  | en   | English label                          |

  This provides the display name when showing related documents in the UI.

  ---
  Line 11: extends LocalEntity

  public class FacilityLimitSysEntry extends LocalEntity
  LocalEntity is the base class for system tables. It provides:
  - Auto-generated ID
  - Basic persistence capabilities
  - No user-facing screens (unlike MasterFile or DocumentFile)

  ---
  Lines 13-22: The Fields

  GenericReference facilityLimit;        // Link to the FacilityLimit master file

  @NaMaField(allowedValues = { ACCEntities.LGTIssue, ACCEntities.LoanIssue, ACCEntities.LGTClosing })
  GenericReference owner;                // The document that created this entry
  - @NaMaField(allowedValues = {...}) restricts which entity types can be stored
  - owner can only reference: LGTIssue, LoanIssue, or LGTClosing documents

  @NaMaField(allowedValues = { ACCEntities.LetterOfGuarantee, ACCEntities.BankLoan })
  GenericReference targetFile;           // The master file being tracked (LGT or BankLoan)

  DecimalDF amount;                      // The consumed amount
  GenericReference projContract;         // Related project contract
  GuaranteeType guaranteeType;           // Type of guarantee
  DateDF valueDate;                      // Value date from the document
  DateTimeDF creationDate;               // When the entry was created

  ---
  How It Works in Practice

  ┌─────────────────────┐
  │   FacilityLimit     │  (Master File - user creates this)
  │   Limit: 1,000,000  │
  └─────────┬───────────┘
            │
            │ tracked by
            ▼
  ┌─────────────────────────────────────────────────────┐
  │         FacilityLimitSysEntry (System Table)        │
  ├─────────────────────────────────────────────────────┤
  │ owner: LGTIssue#123    │ amount: 200,000            │
  │ owner: LGTIssue#456    │ amount: 150,000            │
  │ owner: LoanIssue#789   │ amount: 300,000            │
  └─────────────────────────────────────────────────────┘
            │
            │ calculated from
            ▼
  ┌─────────────────────┐
  │   LGTIssue #123     │  (Document - user creates this)
  │   Value: 200,000    │
  └─────────────────────┘

  When user commits an LGTIssue:
  1. System automatically creates a FacilityLimitSysEntry
  2. Entry tracks how much of the facility limit is consumed
  3. FacilityLimit recalculates its remaining amount

  ---
  Comparison: Entity Types in NaMa

  | Type         | Base Class   | User Editable | Has Screen | Example                 |
  |--------------|--------------|---------------|------------|-------------------------|
  | Master File  | MasterFile   | ✅ Yes         | ✅ Yes      | Customer, FacilityLimit |
  | Document     | DocumentFile | ✅ Yes         | ✅ Yes      | LGTIssue, Invoice       |
  | Value Object | (embedded)   | ❌ No          | ❌ No       | Address, ContactInfo    |
  | System Table | LocalEntity  | ❌ No          | ❌ No       | FacilityLimitSysEntry   |

  ---
  When to Use System Tables

  Use a LocalEntity when you need to:
  1. Track consumed/used amounts (like facility limits)
  2. Store calculated data that needs to be queried
  3. Create audit trails for system operations
  4. Link multiple entities in a many-to-many relationship
