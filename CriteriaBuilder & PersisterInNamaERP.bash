  Complete Guide: CriteriaBuilder & Persister in NamaERP

  Part 1: Your Query Explained

  Criteria criteria = CriteriaBuilder.create()
          .field(IdsOfRECollectDoc.details_installmentCode).equal(installmentCode)
          .and().field(IdsOfRECollectDoc.details_installmentDoc + ".id").equal(installmentDoc.getId())
          .and().idNotEqual(getId())
          .and().commitedBefore()
          .build();
  return Persister.countRecordsMatching(RECollectDoc.class, criteria, FilterOnDimensions.No) > 0;

  Step-by-Step Breakdown:

  | Part                                                              | SQL Equivalent                   | Purpose                             |
  |-------------------------------------------------------------------|----------------------------------|-------------------------------------|
  | CriteriaBuilder.create()                                          | SELECT * FROM RECollectDoc WHERE | Start building the query            |
  | .field("details.installmentCode").equal(installmentCode)          | details.installmentCode = ?      | Match installment code in details   |
  | .and()                                                            | AND                              | Chain conditions                    |
  | .field("details.installmentDoc.id").equal(installmentDoc.getId()) | installmentDocId = ?             | Match source document               |
  | .idNotEqual(getId())                                              | id != ?                          | Exclude current document            |
  | .commitedBefore()                                                 | commitedBefore = TRUE            | Only committed records              |
  | .build()                                                          | -                                | Finalize and create Criteria object |
  | Persister.countRecordsMatching(...)                               | SELECT COUNT(*)...               | Execute and get count               |

  Generated SQL (conceptually):

  SELECT COUNT(*) FROM RECollectDoc doc
  JOIN RECollectDocLine line ON line.parent_id = doc.id
  WHERE line.installmentCode = :installmentCode
    AND line.installmentDocId = :installmentDocId
    AND doc.id != :currentDocId
    AND doc.commitedBefore = TRUE

  ---
  Part 2: CriteriaBuilder Complete Reference

  2.1 Starting a Query

  // Method 1: Start with a field condition
  CriteriaBuilder.create().field("fieldName").equal(value)

  // Method 2: Start with dummy (for dynamic building)
  CriteriaBuilder.create().dummy()  // Always true, good for chaining

  2.2 Comparison Operators

  | Method                     | SQL         | Example                                      |
  |----------------------------|-------------|----------------------------------------------|
  | .equal(value)              | =           | .field("status").equal("ACTIVE")             |
  | .notEqual(value)           | !=          | .field("status").notEqual("DELETED")         |
  | .greaterThan(value)        | >           | .field("amount").greaterThan(100)            |
  | .greaterThanOrEqual(value) | >=          | .field("date").greaterThanOrEqual(startDate) |
  | .lessThan(value)           | <           | .field("amount").lessThan(1000)              |
  | .lessThanOrEqual(value)    | <=          | .field("date").lessThanOrEqual(endDate)      |
  | .between(v1, v2)           | BETWEEN     | .field("date").between(start, end)           |
  | .isNull()                  | IS NULL     | .field("deletedAt").isNull()                 |
  | .isNotNull()               | IS NOT NULL | .field("approvedBy").isNotNull()             |

  2.3 String Operators

  | Method             | SQL        | Example                                |
  |--------------------|------------|----------------------------------------|
  | .startsWith(value) | LIKE 'x%'  | .field("code").startsWith("SYS")       |
  | .endsWith(value)   | LIKE '%x'  | .field("email").endsWith("@gmail.com") |
  | .contains(value)   | LIKE '%x%' | .field("name").contains("Ahmed")       |

  2.4 Collection Operators

  // IN clause - check if field value is in a list
  List<String> statuses = Arrays.asList("ACTIVE", "PENDING");
  .field("status").in(statuses)

  // IN clause with IDs
  List<UniqueIDDF> ids = Arrays.asList(id1, id2, id3);
  .field(CommonFieldIds.ID).in(ids)

  2.5 Logical Operators

  // AND - chain conditions
  .field("status").equal("ACTIVE")
  .and()
  .field("type").equal("INVOICE")

  // OR - alternative conditions
  .field("status").equal("ACTIVE")
  .or()
  .field("status").equal("PENDING")

  // Brackets for grouping (A AND (B OR C))
  .field("type").equal("DOC")
  .and().openBraket()
      .field("status").equal("ACTIVE")
      .or()
      .field("status").equal("PENDING")
  .closeBraket()

  2.6 Special Built-in Conditions

  // Document committed status
  .commitedBefore()         // WHERE commitedBefore = TRUE
  .notCommitedBefore()      // WHERE commitedBefore = FALSE

  // ID conditions
  .idNotEqual(getId())      // WHERE id != :currentId
  .idEqual(someId)          // WHERE id = :someId

  // Activation status
  .activated()              // WHERE activated = TRUE (for MasterFiles)

  2.7 Nested Field Access

  // Access related entity fields using dot notation
  .field("customer.id").equal(customerId)           // FK reference by ID
  .field("customer.code").equal(customerCode)       // FK reference by code
  .field("site.building.id").equal(buildingId)      // Nested reference
  .field("details.installmentCode").equal(code)     // Collection field (JOINs automatically)
  .field("amount.currency.id").equal(currencyId)    // Embedded object field

  ---
  Part 3: Persister Complete Reference

  3.1 Main Methods

  | Method                                   | Purpose                    | Returns        |
  |------------------------------------------|----------------------------|----------------|
  | findByID(Class, id)                      | Find single record by ID   | Entity or null |
  | findFirstRecordMatching(Class, criteria) | Find first matching record | Entity or null |
  | listPageMatching(Class, params)          | List with pagination       | List           |
  | countRecordsMatching(Class, criteria)    | Count matching records     | long           |
  | save(entity)                             | Insert or update           | Result         |
  | saveAll(list)                            | Batch save                 | Result         |
  | delete(Class, criteria)                  | Delete matching records    | Result         |
  | deleteAll(list)                          | Batch delete               | Result         |
  | flush()                                  | Force DB sync              | void           |

  3.2 Find By ID

  // Simple find by ID
  Customer customer = Persister.findByID(Customer.class, customerId);

  // Find by EntityType and ID
  BaseEntity entity = Persister.findByID(EntityTypeDF.Customer(), customerId);

  3.3 Find First Record Matching

  // Find first matching record
  Criteria criteria = CriteriaBuilder.create()
      .field(IdsOfCustomer.email).equal("test@test.com")
      .build();

  Customer customer = Persister.findFirstRecordMatching(
      Customer.class,
      criteria,
      FilterOnDimensions.No  // or Yes for dimension filtering
  );

  3.4 List Page Matching (Most Powerful)

  // Method 1: Using ListPageMatchingParameters (Recommended)
  List<Customer> customers = Persister.listPageMatching(
      Customer.class,
      ListPageMatchingParameters.create()
          .criteria(criteria)
          .pageData(PageData.All())        // or PageData.of(page, size)
          .orderBy("name")                  // sort field
          .asc()                            // or .desc()
          .filterOnDimensions(FilterOnDimensions.No)
  );

  // Method 2: Simple overload
  List<Customer> customers = Persister.listPageMatching(
      Customer.class,
      PageData.All(),
      "name",              // order by field
      criteria,
      FilterOnDimensions.No
  );

  3.5 Count Records

  long count = Persister.countRecordsMatching(
      RECollectDoc.class,
      criteria,
      FilterOnDimensions.No
  );

  // Can also use EntityType
  long count = Persister.countRecordsMatching(
      EntityTypeDF.Customer(),
      criteria,
      FilterOnDimensions.No
  );

  3.6 FilterOnDimensions Options

  | Option                 | Purpose                                         |
  |------------------------|-------------------------------------------------|
  | FilterOnDimensions.Yes | Apply user dimension security (Branch, Company) |
  | FilterOnDimensions.No  | No dimension filtering (system-level queries)   |

  ---
  Part 4: Common Patterns & Recipes

  4.1 Check If Record Exists

  private boolean recordExists(TextDF code, UniqueIDDF excludeId)
  {
      Criteria criteria = CriteriaBuilder.create()
          .field("code").equal(code)
          .and().idNotEqual(excludeId)
          .and().commitedBefore()
          .build();
      return Persister.countRecordsMatching(MyEntity.class, criteria, FilterOnDimensions.No) > 0;
  }

  4.2 Find Latest Record

  MyEntity latest = Persister.findFirstRecordMatching(
      MyEntity.class,
      ListPageMatchingParameters.create()
          .criteria(CriteriaBuilder.create()
              .field("customer.id").equal(customerId)
              .and().commitedBefore()
              .build())
          .orderBy(NotGeneratedFields.valueDate)
          .desc()
          .pageData(PageData.One())
  );

  4.3 Date Range Query

  Criteria criteria = CriteriaBuilder.create()
      .field(NotGeneratedFields.valueDate).greaterThanOrEqual(fromDate)
      .and().field(NotGeneratedFields.valueDate).lessThanOrEqual(toDate)
      .and().commitedBefore()
      .build();

  4.4 Dynamic Criteria Building

  CriteriaBuilder.ExpressionBuilder builder = CriteriaBuilder.create().dummy();

  if (customer != null)
      builder = builder.and().field("customer.id").equal(customer.getId());

  if (fromDate != null)
      builder = builder.and().field("valueDate").greaterThanOrEqual(fromDate);

  if (toDate != null)
      builder = builder.and().field("valueDate").lessThanOrEqual(toDate);

  if (statuses != null && !statuses.isEmpty())
      builder = builder.and().field("status").in(statuses);

  Criteria criteria = builder.build();

  4.5 Query with OR Conditions

  // Find active OR pending documents
  Criteria criteria = CriteriaBuilder.create()
      .openBraket()
          .field("status").equal("ACTIVE")
          .or()
          .field("status").equal("PENDING")
      .closeBraket()
      .and().commitedBefore()
      .build();

  4.6 Query Detail Lines (Collections)

  // Query header by detail field - auto-joins with details table
  Criteria criteria = CriteriaBuilder.create()
      .field(IdsOfInvoice.details_itemCode).equal(itemCode)  // details.itemCode
      .and().field(IdsOfInvoice.details_quantity).greaterThan(0)
      .and().commitedBefore()
      .build();

  List<Invoice> invoices = Persister.listPageMatching(
      Invoice.class,
      ListPageMatchingParameters.create().criteria(criteria)
  );

  4.7 Full Validation Pattern (Your Use Case)

  private void validateNoDuplicateCollection(Result result)
  {
      HashSet<TextDF> processedCodes = new HashSet<>();

      for (int i = 0; i < fetchDetails().size(); i++)
      {
          MyDetailLine line = fetchDetails().get(i);
          TextDF code = line.getCode();

          // Check 1: Duplicate within same document
          if (ObjectChecker.isNotEmptyOrNull(code) && !processedCodes.add(code))
          {
              Result.createDetailFieldValidationFailure(
                  IdsOfMyDoc.details_code, i,
                  "Code {0} is repeated in this document", code
              ).addToAccumulatingResult(result);
              continue;
          }

          // Check 2: Already exists in other committed documents
          if (isCodeAlreadyUsed(code, line.getSourceDoc()))
          {
              Result.createDetailFieldValidationFailure(
                  IdsOfMyDoc.details_code, i,
                  "Code {0} is already used in another document", code
              ).addToAccumulatingResult(result);
          }
      }
  }

  private boolean isCodeAlreadyUsed(TextDF code, GenericReference sourceDoc)
  {
      if (ObjectChecker.isEmptyOrNull(code) || ObjectChecker.isEmptyOrNull(sourceDoc))
          return false;

      Criteria criteria = CriteriaBuilder.create()
          .field(IdsOfMyDoc.details_code).equal(code)
          .and().field(IdsOfMyDoc.details_sourceDoc + ".id").equal(sourceDoc.getId())
          .and().idNotEqual(getId())
          .and().commitedBefore()
          .build();

      return Persister.countRecordsMatching(MyDoc.class, criteria, FilterOnDimensions.No) > 0;
  }

  ---
  Part 5: Quick Reference Card

  CriteriaBuilder Chain Flow

  CriteriaBuilder.create()
      → .field("x") or .dummy()
      → .equal/notEqual/greaterThan/lessThan/in/isNull/startsWith/contains
      → .and() / .or()
      → .field("y")...
      → .build()

  Persister Quick Reference

  // COUNT
  Persister.countRecordsMatching(Class, criteria, FilterOnDimensions)

  // FIND ONE
  Persister.findByID(Class, id)
  Persister.findFirstRecordMatching(Class, criteria, FilterOnDimensions)

  // FIND MANY
  Persister.listPageMatching(Class, ListPageMatchingParameters.create()
      .criteria(criteria)
      .pageData(PageData.All() | PageData.One() | PageData.of(page, size))
      .orderBy("field").asc() | .desc()
      .filterOnDimensions(FilterOnDimensions.No | .Yes))

  // SAVE
  Persister.save(entity)
  Persister.saveAll(list)

  // DELETE
  Persister.delete(Class, criteria)
  Persister.deleteAll(list)

  Common Field IDs

  CommonFieldIds.ID           // "id"
  CommonFieldIds.CODE         // "code"
  CommonFieldIds.NAME         // "name"
  CommonFieldIds.GROUP        // "group"
  NotGeneratedFields.valueDate      // "valueDate"
  NotGeneratedFields.creationDate   // "creationDate"

  ---
  Part 6: Remember Forever Tips

  1. Always start with CriteriaBuilder.create()
  2. Use .dummy() for dynamic queries - acts as always-true placeholder
  3. Chain with .and() or .or() - required between conditions
  4. Access nested fields with dots: "customer.id", "details.code"
  5. Use IdsOf* constants - type-safe field references
  6. End with .build() - creates the final Criteria object
  7. commitedBefore() - for committed documents only
  8. idNotEqual(getId()) - exclude current record in validations
  9. FilterOnDimensions.No - for system validations
  10. PageData.All() - all records, PageData.One() - single record

  Would you like me to apply the fix to AbsRECollect.java now?
