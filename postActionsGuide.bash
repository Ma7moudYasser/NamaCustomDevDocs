
  ---
  Complete Guide to Post Actions in NaMa ERP - Remember Forever!

  Overview: The Four Pillars of GUI Actions

  NaMa ERP has 4 types of GUI annotations that control behavior on the frontend:

  | Annotation          | Purpose                          | Trigger                    | Return Type         |
  |---------------------|----------------------------------|----------------------------|---------------------|
  | @PostActor          | React to field changes           | User changes a field value | ListOfGenericValues |
  | @SearcherContext    | Filter dropdown/searcher         | User opens a lookup field  | DTOCriteria         |
  | @SuggestionProvider | Provide autocomplete suggestions | User types in a text field | SuggestionList      |
  | @GUIAction          | Execute a button action          | User clicks a button       | GUIActionResult     |

  ---
  Part 1: @ActionsClass - The Container

  Every post actions class MUST have this annotation to tell the system which entity types it handles:

  @ActionsClass(entityTypes = ACCEntities.LetterOfGuarantee)
  public class LetterOfGuaranteePostActions
  {
      // All your post actors, searcher contexts, etc. go here
  }

  Multiple Entity Types

  @ActionsClass(entityTypes = { ACCEntities.Invoice, ACCEntities.SalesInvoice, ACCEntities.PurchaseInvoice })
  public class CommonInvoicePostActions
  {
      // Shared logic for all invoice types
  }

  ---
  Part 2: @PostActor - The Field Change Reactor

  The Mental Model

  User changes field → System calls your method → You return fields to update

  Basic Structure

  @PostActor(value = IdsOfEntityName.fieldName)
  public ListOfGenericValues postFieldName(ActionContext actionContext)
  {
      ListOfGenericValues result = new ListOfGenericValues();

      // Get the value the user just entered
      EntityReferenceData newValue = actionContext.fieldValue();

      // Add fields to update
      result.addValue(IdsOfEntityName.otherField, calculatedValue);

      return result;
  }

  Annotation Attributes

  | Attribute       | Purpose                                  | Example                                           |
  |-----------------|------------------------------------------|---------------------------------------------------|
  | value           | Field(s) that trigger this post actor    | IdsOfInvoice.customer                             |
  | contextFields   | Additional fields needed for calculation | { IdsOfInvoice.currency, IdsOfInvoice.valueDate } |
  | sums            | Field to auto-sum from detail lines      | IdsOfInvoice.details_amount                       |
  | entityTypes     | Limit to specific entity types           | { ACCEntities.Invoice }                           |
  | excludeEntities | Exclude from specific entities           | { ACCEntities.CreditNote }                        |

  Example 1: Simple Field Copy

  @PostActor(value = IdsOfLetterOfGuarantee.lgtReq)
  public ListOfGenericValues postLGTReq(ActionContext actionContext)
  {
      ListOfGenericValues result = new ListOfGenericValues();

      // Get the selected request
      EntityReferenceData reqRef = actionContext.fieldValue();
      if (ObjectChecker.isEmptyOrNull(reqRef))
          return result;

      // Load the full DTO
      DTOLGTReq req = ActionContextUtils.getReference(actionContext, reqRef);

      // Copy fields from request to current entity
      result.addValue(IdsOfLetterOfGuarantee.bank, req.getBank());
      result.addValue(IdsOfLetterOfGuarantee.bankAccount, req.getBankAccount());
      result.addValue(IdsOfLetterOfGuarantee.values_fromDate, req.getValues().getFromDate());

      return result;
  }

  Example 2: With Context Fields (Calculation)

  @PostActor(value = IdsOfLGTReq.values_coveredAmount, 
             contextFields = { IdsOfLGTReq.values_lgtValue_amount })
  public ListOfGenericValues postCoveredAmount(ActionContext actionContext, BigDecimal totalAmount)
  {
      ListOfGenericValues result = new ListOfGenericValues();

      // Get the value user just entered
      BigDecimal coveredAmount = actionContext.fieldValue();

      // Calculate percentage
      BigDecimal percentage = NaMaMath.divide(coveredAmount, totalAmount,
              ActionContextUtils.getPercentageSacle()).multiply(BigDecimal.valueOf(100));

      result.addValue(IdsOfLGTReq.values_coveredPercentage, percentage);
      return result;
  }

  Example 3: Detail Line Post Actor

  @PostActor(value = IdsOfHOMaintenanceDoc.details_maintenanceItem)
  public ListOfGenericValues postMaintenanceItem(ActionContext actionContext)
  {
      ListOfGenericValues result = new ListOfGenericValues();

      // Get selected item in the grid row
      EntityReferenceData itemRef = actionContext.fieldValue();
      DTOHOMaintenanceItem item = ActionContextUtils.getReference(actionContext, itemRef);

      // Update other fields in the SAME ROW
      result.addValue(IdsOfHOMaintenanceDoc.details_uom, item.getUom());
      result.addValue(IdsOfHOMaintenanceDoc.details_price, item.getDefaultPrice());

      return result;
  }

  Example 4: Multiple Post Actors on Same Method

  @PostActors({
      @PostActor(value = IdsOfWorkPlan.details_fromDate, 
                 contextFields = { IdsOfWorkPlan.details_fromTime, IdsOfWorkPlan.details_toTime }),
      @PostActor(value = IdsOfWorkPlan.details_fromTime, 
                 contextFields = { IdsOfWorkPlan.details_fromDate, IdsOfWorkPlan.details_toTime }),
      @PostActor(value = IdsOfWorkPlan.details_toTime, 
                 contextFields = { IdsOfWorkPlan.details_fromDate, IdsOfWorkPlan.details_fromTime })
  })
  public ListOfGenericValues postDatesActions(ActionContext context, Date fromDate, Date fromTime, Date toTime)
  {
      ListOfGenericValues values = new ListOfGenericValues();
      Date netTime = calcNetTime(fromDate, fromTime, toTime);
      values.addValue(IdsOfWorkPlan.details_netTime, netTime);
      return values;
  }

  Example 5: With Sums (Auto-calculate totals)

  @PostActor(value = IdsOfInvoice.details_quantity, 
             contextFields = { IdsOfInvoice.details_unitPrice },
             sums = IdsOfInvoice.details_lineTotal)  // Will auto-sum this field
  public ListOfGenericValues postQuantity(ActionContext context, BigDecimal unitPrice, BigDecimal sum)
  {
      ListOfGenericValues result = new ListOfGenericValues();
      BigDecimal quantity = context.fieldValue();

      // Calculate line total
      BigDecimal lineTotal = quantity.multiply(unitPrice);
      result.addValue(IdsOfInvoice.details_lineTotal, lineTotal);

      // sum parameter contains the auto-calculated sum of all details_lineTotal
      result.addValue(IdsOfInvoice.totalAmount, sum.add(lineTotal));

      return result;
  }

  ---
  Part 3: @SearcherContext - The Filter Provider

  The Mental Model

  User opens dropdown → System calls your method → You return filter criteria

  Basic Structure

  @SearcherContext(fieldId = IdsOfEntityName.lookupField)
  public DTOCriteria filterLookupField(ActionContext actionContext)
  {
      return DTOCriteriaBuilder.create()
              .field(IdsOfTargetEntity.someField)
              .equal(someValue)
              .build();
  }

  Example 1: Simple Filter

  @SearcherContext(fieldId = IdsOfLetterOfGuarantee.lgtReq, 
                   entityTypes = ACCEntities.LetterOfGuarantee)
  public DTOCriteria filterLgtReq(ActionContext actionContext)
  {
      // Only show requests that haven't been converted yet
      return DTOCriteriaBuilder.create()
              .field(IdsOfLGTReq.turnedToLGT).isNull()
              .or()
              .field(IdsOfLGTReq.turnedToLGT).equal(Boolean.FALSE.toString())
              .build();
  }

  Example 2: Filter Based on Another Field

  @SearcherContext(fieldId = IdsOfLetterOfGuarantee.bank, 
                   contextFields = IdsOfLetterOfGuarantee.facilityLimit)
  public DTOCriteria filterBank(ActionContext actionContext, EntityReferenceData facilityLimitRef)
  {
      // Load the facility limit to get its bank
      DTOFacilityLimit limit = ActionContextUtils.getReference(actionContext, facilityLimitRef);

      if (limit == null || limit.getBank() == null)
          return null;  // No filter - show all banks

      // Only show the bank from the facility limit
      return DTOCriteriaBuilder.create()
              .field(CommonFieldIds.ID)
              .equal(limit.getBank().getId())
              .build();
  }

  DTOCriteriaBuilder Quick Reference

  // Equals
  .field("fieldId").equal(value)

  // Not equals
  .field("fieldId").notEqual(value)

  // Null checks
  .field("fieldId").isNull()
  .field("fieldId").isNotNull()

  // Comparisons
  .field("fieldId").greaterThan(value)
  .field("fieldId").lessThan(value)
  .field("fieldId").greaterThanOrEqual(value)
  .field("fieldId").lessThanOrEqual(value)

  // In list
  .field("fieldId").in(value1, value2, value3)

  // Like (contains)
  .field("fieldId").like("%searchText%")

  // Combining conditions
  .field("a").equal(1).and().field("b").equal(2)
  .field("a").equal(1).or().field("b").equal(2)

  // Nested groups
  .openParen().field("a").equal(1).or().field("b").equal(2).closeParen()
  .and().field("c").equal(3)

  ---
  Part 4: @SuggestionProvider - The Autocomplete Provider

  The Mental Model

  User types in text field → System calls your method → You return suggestions

  Basic Structure

  @SuggestionProvider(fieldId = IdsOfEntityName.textField)
  public SuggestionList suggestTextField(ActionContext actionContext)
  {
      SuggestionList list = new SuggestionList();
      list.addItem("Option 1");
      list.addItem("Option 2");
      return list;
  }

  Example 1: Static Suggestions

  @SuggestionProvider(fieldId = IdsOfLabTestResult.details_resultRange_fromRange)
  public SuggestionList suggestFromRange(ActionContext actionContext)
  {
      SuggestionList list = new SuggestionList();
      list.addItem("Positive+");
      list.addItem("Negative-");
      list.addItem("Normal");
      return list;
  }

  Example 2: Dynamic Suggestions Based on Another Field

  @SuggestionProvider(fieldId = IdsOfMnSrvNotice.dysfunctions_proposedSolution, 
                      contextFields = { IdsOfMnSrvNotice.dysfunctions_dysfunction })
  public SuggestionList suggestProposedSolutions(ActionContext context, EntityReferenceData dysfunctionRef)
  {
      SuggestionList list = new SuggestionList();

      // Load the dysfunction to get its proposed solutions
      DTOMnDysfunction dysfunction = ActionContextUtils.getReference(context, dysfunctionRef);
      if (ObjectChecker.isEmptyOrNull(dysfunction.getProposedSolutions()))
          return list;

      // Add solutions from the dysfunction
      list.addItems(dysfunction.getProposedSolutions().stream()
              .map(DTOMnDysfunctionProposedSolutionLine::getProposedSolution)
              .filter(ObjectChecker::isNotEmptyOrNull)
              .collect(Collectors.toList()));

      // Filter based on what user has typed so far
      return list.filter(context.fieldValueStr());
  }

  Example 3: Multiple Suggestion Providers

  @SuggestionProviders({
      @SuggestionProvider(fieldId = IdsOfOrder.spareParts_size, 
                          contextFields = IdsOfOrder.spareParts_sparePart),
      @SuggestionProvider(fieldId = IdsOfOrder.returnedParts_size, 
                          contextFields = IdsOfOrder.returnedParts_sparePart)
  })
  public SuggestionList suggestItemSize(ActionContext context, EntityReferenceData sparePart)
  {
      // Same logic for both fields
      return InvTransCommon.suggestPropertyListOfItem(sparePart, context.fieldValueStr());
  }

  ---
  Part 5: @GUIAction - The Button Handler

  The Mental Model

  User clicks button → System calls your method → You return result (navigate, update fields, show message)

  Basic Structure

  @GUIAction(id = "actionId", 
             contextFields = { IdsOfEntityName.field1, IdsOfEntityName.field2 })
  public GUIActionResult actionName(ActionContext context, Object field1Value, Object field2Value)
  {
      // Your logic here
      return new GUIActionResult().success(NaMaText.resource("operationSuccessful"));
  }

  Annotation Attributes

  | Attribute     | Purpose                              | Example                 |
  |---------------|--------------------------------------|-------------------------|
  | id            | Action ID (used in UI configuration) | "createInvoice"         |
  | contextFields | Fields to pass to the method         | { IdsOfOrder.customer } |
  | mustBeSaved   | Require entity to be saved first     | true                    |
  | entityTypes   | Limit to specific entities           | { ACCEntities.Order }   |
  | questions     | Show confirmation dialog fields      | { "quantity", "date" }  |

  Example 1: Create New Entity and Navigate

  @GUIAction(id = "createLetterOfGuarantee", 
             mustBeSaved = true,
             contextFields = { IdsOfLGTReq.bank, IdsOfLGTReq.bankAccount, IdsOfLGTReq.values_lgtValue_amount })
  public GUIActionResult createLetterOfGuarantee(ActionContext context, 
          EntityReferenceData bank, EntityReferenceData bankAccount, BigDecimal amount)
  {
      // Validation
      if (ObjectChecker.isEmptyOrNull(bank))
          return new GUIActionResult().failure(NaMaText.resource("bankRequired"));

      // Create new entity
      LetterOfGuaranteeWS ws = ServiceUtility.getServiceClient(ACCEntities.LetterOfGuarantee);
      DTOLetterOfGuarantee dto = ws.createNew(new CreateNewRequest(ACCEntities.LetterOfGuarantee)).getData();

      // Set values
      dto.setBank(bank);
      dto.setBankAccount(bankAccount);
      dto.getValues().getLgtValue().setAmount(amount);

      // Navigate to new record
      return new GUIActionResult().newRecord(FlatObjectUtilies.createFlatObject(dto));
  }

  Example 2: Update Fields Without Navigation

  @GUIAction(id = "calculateTotals", 
             contextFields = { IdsOfInvoice.details })
  public GUIActionResult calculateTotals(ActionContext context, List<DTOInvoiceLine> details)
  {
      BigDecimal total = BigDecimal.ZERO;
      for (DTOInvoiceLine line : details)
      {
          total = total.add(line.getLineTotal());
      }

      return new GUIActionResult()
              .addUpdatedValues(IdsOfInvoice.totalAmount, total)
              .addUpdatedValues(IdsOfInvoice.taxAmount, total.multiply(new BigDecimal("0.15")));
  }

  Example 3: Show Error/Success Message

  @GUIAction(id = "validateDocument", contextFields = { IdsOfDocument.status })
  public GUIActionResult validateDocument(ActionContext context, String status)
  {
      if ("Draft".equals(status))
      {
          return new GUIActionResult().failure(NaMaText.resource("cannotValidateDraft"));
      }
      return GUIActionResult.success();  // Shows "Operation Successful"
  }

  Example 4: Navigate to URL

  @GUIAction(id = "openReport", contextFields = { CommonFieldIds.ID })
  public GUIActionResult openReport(ActionContext context, String id)
  {
      String reportUrl = "/reports/invoice?id=" + id;
      return new GUIActionResult().internalUrl(reportUrl);
  }

  Example 5: Update Multiple Rows (Select All)

  @GUIAction(id = "selectAllLines", contextFields = { IdsOfWorkPlan.details })
  public GUIActionResult selectAllLines(ActionContext context, List<DTOWorkPlanLine> details)
  {
      GUIActionResult result = new GUIActionResult();

      for (int i = 0; i < details.size(); i++)
      {
          result.addUpdatedValuesAtRow(IdsOfWorkPlan.details_selected, true, i);
      }

      return result;
  }

  GUIActionResult Quick Reference

  // Success message
  new GUIActionResult().success(NaMaText.resource("operationSuccessful"))

  // Error message
  new GUIActionResult().failure(NaMaText.resource("errorMessage"))

  // Navigate to new record
  new GUIActionResult().newRecord(flatObject)

  // Navigate to new record in popup
  new GUIActionResult().newRecordInPopup(flatObject)

  // Update fields
  new GUIActionResult()
      .addUpdatedValues("fieldId1", value1)
      .addUpdatedValues("fieldId2", value2)

  // Update field at specific row
  new GUIActionResult().addUpdatedValuesAtRow("details_field", value, rowIndex)

  // Navigate to internal URL
  new GUIActionResult().internalUrl("/path/to/page")

  // Navigate to external URL
  new GUIActionResult().externalUrl("https://example.com")

  // Copy text to clipboard
  new GUIActionResult().textToCopy("text to copy")

  // Refresh the current view
  new GUIActionResult().refresh()

  ---
  Part 6: ActionContext - Your Information Hub

  Key Methods

  | Method               | Returns             | Purpose                                 |
  |----------------------|---------------------|-----------------------------------------|
  | fieldValue()         | <T>                 | The value user just entered (auto-cast) |
  | fieldValueStr()      | String              | The value as string                     |
  | getEntityType()      | String              | Current entity type                     |
  | getFieldId()         | String              | The field that triggered the action     |
  | getObjectIndex()     | Integer             | Row index (for detail lines)            |
  | getValueDate()       | Date                | Document's value date                   |
  | getBranch()          | EntityReferenceData | Current branch dimension                |
  | getDepartment()      | EntityReferenceData | Current department dimension            |
  | getEntityId()        | String              | Current entity's ID                     |
  | getEntityCode()      | String              | Current entity's code                   |
  | getCommittedBefore() | Boolean             | Was entity committed before?            |

  ActionContextUtils - Your Helper

  // Load a referenced entity (with caching!)
  DTOCustomer customer = ActionContextUtils.getReference(actionContext, customerRef);

  // Load module configuration
  DTOAccountingConfig config = ActionContextUtils.fetchModuleConfig(ModuleNames.ACCOUNTING, DTOAccountingConfig.class);

  // Get global precision settings
  int percentageScale = ActionContextUtils.getPercentageSacle();
  int currencyScale = ActionContextUtils.getCurrencyScale(currency);

  // Create a new entity
  DTOInvoice invoice = ActionContextUtils.createEntity(ACCEntities.Invoice);

  ---
  Part 7: Field ID Naming Conventions

  Header Fields

  IdsOfInvoice.customer           // Simple field
  IdsOfInvoice.values_amount      // Nested object field (values.amount)
  IdsOfInvoice.address_city       // Nested object field (address.city)

  Detail Line Fields

  IdsOfInvoice.details_item       // Field in detail collection
  IdsOfInvoice.details_quantity   // Field in detail collection
  IdsOfInvoice.details_price_net  // Nested field in detail (details[].price.net)

  Common Field IDs

  CommonFieldIds.ID               // Entity ID
  CommonFieldIds.CODE             // Entity code
  CommonFieldIds.VALUE_DATE       // Value date
  CommonFieldIds.BRANCH           // Branch dimension
  NotGeneratedFields.ref1         // Generic reference 1
  NotGeneratedFields.name1        // Name (Arabic)
  NotGeneratedFields.name2        // Name (English)

  ---
  Quick Reference Card

  Post Actor Template

  @PostActor(value = IdsOfXXX.changedField, contextFields = { IdsOfXXX.neededField })
  public ListOfGenericValues postChangedField(ActionContext ctx, TypeOfNeededField neededField)
  {
      ListOfGenericValues result = new ListOfGenericValues();
      TypeOfChangedField value = ctx.fieldValue();
      result.addValue(IdsOfXXX.fieldToUpdate, calculatedValue);
      return result;
  }

  Searcher Context Template

  @SearcherContext(fieldId = IdsOfXXX.lookupField, contextFields = IdsOfXXX.filterSource)
  public DTOCriteria filterLookupField(ActionContext ctx, TypeOfFilterSource source)
  {
      if (ObjectChecker.isEmptyOrNull(source))
          return null;
      return DTOCriteriaBuilder.create().field(IdsOfTarget.field).equal(source.getValue()).build();
  }

  GUI Action Template

  @GUIAction(id = "actionId", mustBeSaved = true, contextFields = { IdsOfXXX.field1 })
  public GUIActionResult actionName(ActionContext ctx, TypeOfField1 field1)
  {
      // Validation
      if (ObjectChecker.isEmptyOrNull(field1))
          return new GUIActionResult().failure(NaMaText.resource("fieldRequired"));

      // Logic
      // ...

      return GUIActionResult.success();
  }

  ---
  Memory Tricks

  1. @PostActor = "When field changes, update other fields" → Returns ListOfGenericValues
  2. @SearcherContext = "Filter what user can select" → Returns DTOCriteria
  3. @SuggestionProvider = "Suggest text options" → Returns SuggestionList
  4. @GUIAction = "Button clicked, do something" → Returns GUIActionResult
  5. contextFields = "Other fields I need to do my job"
  6. actionContext.fieldValue() = "What did the user just enter?"
  7. ActionContextUtils.getReference() = "Load the full DTO from a reference"
  8. details_xxx = "This is a detail line field"

