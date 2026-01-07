 Now I have the full picture. Let me explain everything in detail with examples you'll never forget.

  ---
  FacilityLimitSysEntry - Complete Breakdown

  What Is This Class? (The Big Picture)

  Think of a Facility Limit as a bank credit line. A company gets approved for 1,000,000 SAR from a bank. This class (FacilityLimitSysEntry) tracks every document that consumes from that credit line.

  Real-World Analogy:
  Imagine you have a credit card with a 10,000 SAR limit. Every time you buy something (a "transaction"), the bank records it. FacilityLimitSysEntry is like each of those transaction records - it says "On this date, this 
  purchase consumed 500 SAR from your limit."

  ---
  Part 1: The Class Definition & Annotations

  @Embeddable
  @XmlAccessorType(XmlAccessType.PROPERTY)
  @XmlRootElement
  @GenerateIDs
  public class FacilityLimitSysEntry extends GeneratedFacilityLimitSysEntry

  | Annotation       | What It Does                                                                    | Memory Trick                                                       |
  |------------------|---------------------------------------------------------------------------------|--------------------------------------------------------------------|
  | @Embeddable      | This is a JPA "value object" - it has its own table but no independent identity | Like a sticky note - it exists but is always attached to something |
  | @XmlAccessorType | Controls how XML serialization reads properties                                 | "Read my getters, not my fields"                                   |
  | @XmlRootElement  | Can be the root of an XML document                                              | "I can be the boss of an XML tree"                                 |
  | @GenerateIDs     | NaMa-specific: generates field ID constants                                     | Auto-generates IdsOfFacilityLimitSysEntry class                    |

  ---
  Part 2: The Fields (From DSL & Generated Class)

  GenericReference facilityLimit;    // Which credit line this belongs to
  GenericReference owner;            // Which document created this entry (LGTIssue, LoanIssue, LGTClosing)
  GenericReference targetFile;       // The Letter of Guarantee or Bank Loan being used
  DecimalDF amount;                  // How much was consumed
  GenericReference projContract;     // Optional: linked project contract
  GuaranteeType guaranteeType;       // Type of guarantee
  DateDF valueDate;                  // When the value is recorded
  DateTimeDF creationDate;           // When this entry was created

  Memory Example:
  FacilityLimit: "ABC Bank Credit Line - 1,000,000 SAR"
     └── Entry 1: owner=LGTIssue#123, targetFile=LetterOfGuarantee#456, amount=100,000
     └── Entry 2: owner=LGTIssue#124, targetFile=LetterOfGuarantee#457, amount=250,000
     └── Entry 3: owner=LoanIssue#001, targetFile=BankLoan#789, amount=300,000

     Total Consumed: 650,000 SAR
     Remaining: 350,000 SAR

  ---
  Part 3: The addEntry Method - The Heart of the Class

  public static void addEntry(FacilityLimitSysEntry entry, Result result)
  {
      // Step 1: Find all OLD entries for this owner document
      List<FacilityLimitSysEntry> oldEntries = findEntriesOfOwner(entry.getOwner());

      // Step 2: Track which facility limits are affected
      Set<GenericReference> affectedLimits = new HashSet<>();
      affectedLimits.add(entry.getFacilityLimit());
      oldEntries.stream().map(FacilityLimitSysEntry::getFacilityLimit).forEach(affectedLimits::add);

      // Step 3: Decide whether to CREATE new or REUSE old
      List<FacilityLimitSysEntry> newEntries = new ArrayList<>();
      if (oldEntries.isEmpty())
      {
          newEntries.add(entry);  // No old entries, just add new
      }
      else
      {
          FacilityLimitSysEntry reused = oldEntries.removeFirst();  // Take first old entry
          reused.copyFrom(entry);  // Copy new data into it
          newEntries.add(reused);
      }

      // Step 4: Save new, delete remaining old
      Persister.saveAll(newEntries).addToAccumulatingResult(result);
      Persister.deleteAll(oldEntries).addToAccumulatingResult(result);

      // Step 5: Recalculate remaining amounts
      recalcRemainingOfLimits(affectedLimits, result);
  }

  Why Reuse Instead of Delete+Create?

  Memory Trick - "The Hotel Room Strategy":
  Imagine a hotel. Instead of demolishing a room and building a new one when a guest checks out, you just clean it and let the next guest use it. The reused.copyFrom(entry) is like "cleaning the room" - same room ID, new 
  guest data.

  Benefits:
  1. Keeps database IDs stable (important for auditing)
  2. Fewer database operations
  3. Avoids foreign key issues

  Visual Flow:

  SCENARIO: LGTIssue#123 changes its facility limit from LimitA to LimitB

  BEFORE:
    LimitA: [Entry1(owner=LGTIssue#123, amount=100k)]
    LimitB: []

  addEntry() is called with new entry for LimitB...

  Step 1: oldEntries = [Entry1] (found because owner=LGTIssue#123)
  Step 2: affectedLimits = {LimitA, LimitB}
  Step 3: Reuse Entry1, copy new data (now points to LimitB)
  Step 4: Save Entry1 (now updated), delete nothing (oldEntries is empty after removeFirst)
  Step 5: Recalculate BOTH LimitA and LimitB

  AFTER:
    LimitA: [] (consumed = 0)
    LimitB: [Entry1(owner=LGTIssue#123, amount=100k)] (consumed = 100k)

  ---
  Part 4: The deleteEntriesOf Method

  public static void deleteEntriesOf(GenericReference owner, Result result)
  {
      List<FacilityLimitSysEntry> entries = findEntriesOfOwner(owner);
      Persister.deleteAll(entries).addToAccumulatingResult(result);
      recalcRemainingOfLimits(entries.stream().map(FacilityLimitSysEntry::getFacilityLimit).collect(Collectors.toSet()), result);
  }

  When is this called? When a document (LGTIssue, LoanIssue, LGTClosing) is deleted or cancelled.

  Memory Example - "Cancelling a Credit Card Purchase":
  Before: FacilityLimit has 100k consumed
  User deletes LGTIssue#123 (which had a 100k entry)
  deleteEntriesOf(LGTIssue#123) is called
  → Entry deleted
  → FacilityLimit recalculated: consumed = 0, remaining = full limit

  ---
  Part 5: The recalcRemainingOfLimits Method - The Calculator

  private static void recalcRemainingOfLimits(Set<GenericReference> limits, Result result)
  {
      Persister.flush();  // Ensure all DB changes are written first

      for (GenericReference limit : limits)
      {
          FacilityLimit facilityLimit = limit.toReal();  // Load the actual entity
          List<FacilityLimitSysEntry> entries = findEntriesOfLimit(facilityLimit);

          facilityLimit.resetConsumedAndRemaining();  // Reset to zero

          for (FacilityLimitSysEntry entry : entries)
          {
              // Find which line in the FacilityLimit matches this entry
              FacilityLimitLine lineForEntry = facilityLimit.findLineForEntry(entry);

              if (lineForEntry == null)
              {
                  // ERROR: Entry exists but no matching line in FacilityLimit
                  Result.createFailureResult("Could not find matching line...").addToAccumulatingResult(result);
                  continue;
              }

              // Add this entry's amount to the line's "used" total
              lineForEntry.setFacilityLimitUsed(
                  lineForEntry.getFacilityLimitUsed().plus(entry.getAmount())
              );
          }

          facilityLimit.updateRemainingAndValidate(result);  // Calculate remaining & validate
      }
  }

  Memory Trick - "The Accountant's Reconciliation":
  Every time something changes, the accountant (this method) throws away the old totals, looks at every transaction record, and adds them up fresh. This guarantees accuracy.

  Visual Flow:
  FacilityLimit (Total: 1,000,000)
  ├── Line 1: Letter of Guarantee (Limit: 500,000)
  ├── Line 2: Bank Loan (Limit: 500,000)

  Entries:
  - Entry A: targetFile=LetterOfGuarantee#1, amount=100,000
  - Entry B: targetFile=LetterOfGuarantee#2, amount=150,000
  - Entry C: targetFile=BankLoan#1, amount=200,000

  After recalcRemainingOfLimits():
  ├── Line 1: used=250,000, remaining=250,000
  ├── Line 2: used=200,000, remaining=300,000
  Total Remaining: 550,000

  ---
  Part 6: The copyFrom Method

  private void copyFrom(FacilityLimitSysEntry entry)
  {
      setOwner(entry.getOwner());
      setFacilityLimit(entry.getFacilityLimit());
      setFacilityLimit(entry.getTargetFile());    // BUG! Should be setTargetFile()
      setFacilityLimit(entry.getProjContract());  // BUG! Should be setProjContract()
  }

  ⚠️ Note: There appear to be bugs here - setFacilityLimit is called three times instead of using the correct setters.

  ---
  Part 7: The Query Methods

  // Find all entries belonging to a specific document
  private static List<FacilityLimitSysEntry> findEntriesOfOwner(GenericReference owner)
  {
      return Persister.listPageMatching(FacilityLimitSysEntry.class,
          ListPageMatchingParameters.create()
              .criteria(CriteriaBuilder.create()
                  .field(IdsOfFacilityLimitSysEntry.owner + ".id")
                  .equal(owner.getId())));
  }

  // Find all entries consuming from a specific facility limit
  public static List<FacilityLimitSysEntry> findEntriesOfLimit(FacilityLimit facilityLimit)
  {
      return Persister.listPageMatching(FacilityLimitSysEntry.class,
          ListPageMatchingParameters.create()
              .criteria(CriteriaBuilder.create()
                  .field(IdsOfFacilityLimitSysEntry.facilityLimit + ".id")
                  .equal(facilityLimit.getId())));
  }

  Memory Trick - "The Library Card Catalog":
  - findEntriesOfOwner: "Show me all books checked out by John" → All entries created by LGTIssue#123
  - findEntriesOfLimit: "Show me all books from the Science section" → All entries consuming from FacilityLimit#ABC

  ---
  Summary Diagram

  ┌─────────────────────────────────────────────────────────────────┐
  │                      FACILITY LIMIT                              │
  │                   (Bank Credit Line)                             │
  │                    Total: 1,000,000                              │
  ├─────────────────────────────────────────────────────────────────┤
  │  Line 1: LGT (500k)    │    Line 2: Loans (500k)                │
  ├─────────────────────────────────────────────────────────────────┤
                                ▲
                                │
           ┌────────────────────┼────────────────────┐
           │                    │                    │
      ┌────┴────┐         ┌────┴────┐         ┌────┴────┐
      │ Entry 1 │         │ Entry 2 │         │ Entry 3 │
      │ LGTIssue│         │LGTIssue │         │LoanIssue│
      │ 100,000 │         │ 150,000 │         │ 200,000 │
      └─────────┘         └─────────┘         └─────────┘
           │                    │                    │
           ▼                    ▼                    ▼
      ┌─────────┐         ┌─────────┐         ┌─────────┐
      │   LGT   │         │   LGT   │         │  Loan   │
      │  #456   │         │  #457   │         │  #789   │
      └─────────┘         └─────────┘         └─────────┘

  ---
  Key Takeaways to Remember Forever

  1. FacilityLimitSysEntry = Transaction Log - Records every consumption from a credit line
  2. One Owner = One Entry - Each document can only have one entry (reuse pattern)
  3. Always Recalculate - After any change, totals are rebuilt from scratch
  4. Affected Limits Tracking - When moving between limits, BOTH old and new are recalculated
  5. GenericReference - Allows linking to multiple entity types (polymorphic references)

> @..\..\mnt\c\dev\namaerp\modules\accounting\accountingdomain\src\main\java\com\namasoft\modules\accounting\domain\entities\ACCDefaultUI.java#L3250-3251 make it right