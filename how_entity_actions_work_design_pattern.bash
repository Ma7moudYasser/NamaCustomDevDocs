  How the Entity Flow System Works

  1. The Core Concept

  The Entity Flow system is NamaERP's implementation of the Strategy + Observer pattern. It allows you to attach custom behavior (actions) to entity lifecycle events without modifying the entity's Java code. Think of it as a
  configurable event system:

  - An EntityFlow is a configuration record (stored in the database) that says: "When entity X does Y, run action Z"
  - An EntityAction is a Java class that implements the actual behavior
  - An EntityTargetAction is the lifecycle event (when to trigger)

  2. The Architecture (3 Layers)

  ┌─────────────────────────────────────────────────────┐
  │  EntityFlow (Database Record)                       │
  │  ┌───────────────┬──────────────┬─────────────────┐ │
  │  │ Entity Type   │ Target Action│ Criteria/Dims   │ │
  │  │ (e.g. Invoice)│ (e.g. Post  │ (when to apply) │ │
  │  │               │   Commit)   │                 │ │
  │  ├───────────────┴──────────────┴─────────────────┤ │
  │  │ Details (EntityActionLine[])                   │ │
  │  │ ┌────────────┬────────┬────────┬─────────────┐ │ │
  │  │ │ClassName   │ Param1 │ Param2 │ TargetAction│ │ │
  │  │ │ (Java class│ ...    │ ...    │ (override)  │ │ │
  │  │ │  to run)   │        │        │             │ │ │
  │  │ └────────────┴────────┴────────┴─────────────┘ │ │
  │  └────────────────────────────────────────────────┘ │
  └─────────────────────────────────────────────────────┘
           │
           │ runEntityActions(EntityTargetAction)
           ▼
  ┌─────────────────────────────────────────────────────┐
  │  BaseEntity.java (The Engine)                       │
  │                                                     │
  │  1. EntityFlowSearchUtil.fetchEntityFlow(type, act) │
  │  2. For each flow: checkIfFlowApplicable()          │
  │  3. filterAndSortApplicableActionLines()            │
  │  4. For each line:                                  │
  │     a. Instantiate class from ClassName             │
  │     b. actor.beforeCall(flow, line)                 │
  │     c. actor.validateParameters(...)                │
  │     d. actor.doAction(entity, param1..param15)      │
  └─────────────────────────────────────────────────────┘
           │
           ▼
  ┌─────────────────────────────────────────────────────┐
  │  EntityAction<T> Interface (The Contract)           │
  │                                                     │
  │  + doAction(T object, LongTextDF... params): Result │
  │  + validateParameters(...): Result                  │
  │  + describe(): String                               │
  │  + columnNames(): List<String>   ← parameter labels │
  │  + beforeCall(flow, line)        ← pre-hook         │
  │  + shouldPreventSimultaneousRuns(): boolean          │
  └─────────────────────────────────────────────────────┘

  3. Entity Lifecycle — The Full Execution Order

  SAVE (Commit) Flow:

  BaseEntity.preCommit()
    ├── commonPreCommitValidations()          ← system checks
    ├── isValidForNew() / isValidForEdit()    ← entity-specific validation
    ├── userPreCommitValidation()             ← EntityFlows: ValidateOnSave
    ├── preCommitAction()                     ← entity-specific pre-commit
    └── applyEffects()                        ← inventory, accounting, etc.

  BaseEntity.commit()                         ← actual DB write

  BaseEntity.postCommit()
    ├── commonPostCommitAction()              ← system: update EntitySystemEntry
    ├── postCommitAction()                    ← entity-specific post-commit
    └── userPostCommitAction()                ← EntityFlows: PostCommit
                                                (EAGenerateEntityFromEntityAction runs here)

  DELETE Flow (after our fix):

  BaseEntity.preDelete()
    ├── userPrePreDeleteValidation()          ← EntityFlows: PreValidateOnDelete
    ├── runEntityActions(ActionOnDelete)       ← ✅ NEW: EntityFlows: ActionOnDelete
    │                                           (DeleteRelatedEntityAction runs here)
    ├── commonPreDeleteValidations()          ← system: check related docs in EntitySystemEntry
    │                                           (DocumentFile: "Record cannot be deleted, X Created from this record")
    ├── isValidForDelete()                    ← entity-specific validation
    ├── userPreDeleteValidation()             ← EntityFlows: ValidateOnDelete
    └── preDeleteAction()                     ← entity-specific pre-delete

  BaseEntity.delete()                         ← actual DB delete

  BaseEntity.postDelete()
    ├── commonPostDeleteAction()              ← system cleanup
    ├── postDeleteAction()                    ← entity-specific cleanup
    └── userPostDeleteAction()                ← EntityFlows: PostDelete

  4. Design Patterns Used

  Pattern 1 — Strategy Pattern (EntityAction interface)
  Each action class is a strategy. The system doesn't know what the action does — it just calls doAction(). Examples:
  - EAGenerateEntityFromEntityAction — creates a new document from a source
  - DeleteRelatedEntityAction — deletes a related document
  - EAAutomaticGenerateEntityFromEntityAction — auto-generates without user intervention

  Pattern 2 — Observer/Event Pattern (EntityTargetAction enum)
  Entity lifecycle events act as observable events. Entity flows "subscribe" to events:
  ValidateOnSave  → fires before save
  PostCommit      → fires after save
  ActionOnDelete  → fires before delete validation (NEW)
  ValidateOnDelete→ fires during delete validation
  PostDelete      → fires after delete

  Pattern 3 — Chain of Responsibility (preDelete(), preCommit())
  Each step in the lifecycle returns a Result. If any step fails, the chain stops:
  this.userPrePreDeleteValidation().addToAccumulatingResult(result);
  if (result.failed()) return result;  // ← stop chain
  this.runEntityActions(EntityTargetAction.ActionOnDelete()).addToAccumulatingResult(result);
  if (result.failed()) return result;  // ← stop chain
  this.commonPreDeleteValidations().addToAccumulatingResult(result);
  if (result.failed()) return result;  // ← stop chain

  Pattern 4 — Template Method (BaseEntity → DocumentFile → concrete entity)
  BaseEntity.preDelete() defines the skeleton. Subclasses override specific steps:
  - DocumentFile overrides commonPreDeleteValidations() to add the related-doc check
  - Concrete entities override isValidForDelete() for entity-specific rules

  Pattern 5 — Applicability Filter (checkIfFlowApplicable())
  Before running a flow, the system checks if it applies to THIS specific record:
  - Criteria match (field conditions)
  - Dimension match (legal entity, branch, sector, department)
  - Book/Term match (for documents)
  - Apply-when SQL query
  - Do-not-apply-when SQL query

  5. Key Classes and Their Roles

  ┌──────────────────────┬──────────────────────────────────────────────────────────┬────────────────────────────────────────────────────────┐
  │        Class         │                           File                           │                          Role                          │
  ├──────────────────────┼──────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
  │ EntityAction<T>      │ infra/domain-base/.../entity/base/EntityAction.java      │ Interface all actions implement                        │
  ├──────────────────────┼──────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
  │ EntityTargetAction   │ infra/domain-base/.../primitives/EntityTargetAction.java │ Enum of lifecycle events                               │
  ├──────────────────────┼──────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
  │ BaseEntity           │ infra/domain-base/.../entity/base/BaseEntity.java        │ The engine — runs flows at lifecycle points            │
  ├──────────────────────┼──────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
  │ DocumentFile         │ infra/domain-base/.../entity/base/DocumentFile.java      │ Adds document-specific validations (related doc check) │
  ├──────────────────────┼──────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
  │ EntityFlow           │ (database entity)                                        │ The configuration record                               │
  ├──────────────────────┼──────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
  │ EntityActionLine     │ (database entity)                                        │ One action line within a flow (className + params)     │
  ├──────────────────────┼──────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
  │ EntityFlowSearchUtil │ (utility)                                                │ Fetches applicable flows from cache/DB                 │
  ├──────────────────────┼──────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────┤
  │ EntityMediator       │ infra/domain-base/.../entity/base/EntityMediator.java    │ Orchestrates full entity CRUD operations               │
  └──────────────────────┴──────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────┘

  6. How DeleteRelatedEntityAction + EAGenerateEntityFromEntityAction Work Together

  These are a pair — one creates, one cleans up:

  EAGenerateEntityFromEntityAction (on PostCommit):
    1. Takes: target type, field mapping SQL, options
    2. Creates a new entity of target type
    3. Maps fields from source → target using SQL
    4. Commits the target entity
    5. System auto-creates EntitySystemEntry record:
       { fromId: source.id, targetType: "CreditNote", targetId: target.id }

  DeleteRelatedEntityAction (on ActionOnDelete):
    1. Takes: target type name, finder SQL
    2. Executes finder SQL to locate the target entity
    3. Calls EntityMediator.deleteEntityFromBusinessAction(target)
    4. Target is deleted BEFORE commonPreDeleteValidations checks

  7. Simple Example — Try It

  Scenario: You have a PurchaseOrder that should auto-create a GoodsReceivedNote on save, and auto-delete it when the PO is deleted.

  Entity Flow Configuration (in the EntityFlow screen):

  Entity Flow Record:
    Name: "Auto Generate GRN from PO"
    Entity Type: PurchaseOrder

    Details (2 lines):

    Line 1 — Create on save:
      ClassName:     com.namasoft.infor.domainbase.util.actions.EAGenerateEntityFromEntityAction
      Target Action: PostCommit
      Parameter 1:   GoodsReceivedNote                          ← target type
      Parameter 2:   select '{code}' as code, '{id}' as ref5Id  ← field mapping SQL
      Parameter 3:   (empty or additional mapping)
      Parameter 4:   (options)

    Line 2 — Delete on delete:
      ClassName:     com.namasoft.infor.domainbase.util.actions.DeleteRelatedEntityAction
      Target Action: ActionOnDelete                              ← ✅ Use the new action type
      Parameter 1:   GoodsReceivedNote                           ← target type
      Parameter 2:   select id from GoodsReceivedNote where ref5Id={id}  ← finder SQL

  What happens when user saves PO-001:
  1. PO-001.preCommit()        → validations pass
  2. PO-001.commit()           → PO saved to DB
  3. PO-001.postCommit()       → runs PostCommit entity flows
     → EAGenerateEntityFromEntityAction runs
     → Creates GRN-001 with ref5Id = PO-001.id
     → EntitySystemEntry created: { fromId: PO-001.id, targetType: GRN }

  What happens when user deletes PO-001 (BEFORE our fix):
  1. preDelete()
  2. userPrePreDeleteValidation()  → PreValidateOnDelete flows → OK
  3. commonPreDeleteValidations()  → Finds EntitySystemEntry → ❌ BLOCKED!
     "Record cannot be deleted, GoodsReceivedNote-GRN-001 Created from this record"
  4. DeleteRelatedEntityAction NEVER RUNS (it was on PostDelete)

  What happens when user deletes PO-001 (AFTER our fix):
  1. preDelete()
  2. userPrePreDeleteValidation()     → PreValidateOnDelete flows → OK
  3. runEntityActions(ActionOnDelete)  → ✅ DeleteRelatedEntityAction runs!
     → Finds GRN-001 via SQL
     → Deletes GRN-001 (and its EntitySystemEntry)
  4. commonPreDeleteValidations()     → No related docs found → OK ✅
  5. isValidForDelete()               → OK
  6. delete()                         → PO-001 deleted
  7. postDelete()                     → cleanup
  All in one transaction — if step 5 fails, GRN-001 deletion rolls back too.

  8. How filterAndSortApplicableActionLines Works

  This is the method that decides which lines in an EntityFlow run for a given event:

  // BaseEntity.java:722-735
  for (EntityActionLine line : entityFlow.getDetails()) {
      if (line is active
          AND (line.targetAction is empty              ← runs for ANY event
               OR line.targetAction == currentAction   ← matches this event
               OR line.targetAction == Automatic))     ← always runs
          → include this line
  }
  sort by methodOrder  // controls execution order within a flow

  This means one EntityFlow record can have multiple lines for different events — e.g., Line 1 runs on PostCommit (create), Line 2 runs on ActionOnDelete (delete).