● Now I have all the information. Let me provide you with a comprehensive guide:

  ---
  Complete Guide to validateBranchFacilityLimit - Remember Forever!

  The Function We're Analyzing

  private void validateBranchFacilityLimit(Result result)
  {
      // STEP 1: Group all lines by their parent code
      Map<TextDF, List<FacilityLimitLine>> linesByParent = CollectionsUtility.mapList(getDetails(), FacilityLimitLine::getParentCode);

      // STEP 2: Create a lookup map: facilityCode -> line
      Map<TextDF, FacilityLimitLine> linesByCode = getDetails().stream()
              .collect(Collectors.toMap(FacilityLimitLine::getFacilityCode, Function.identity(), (o, n) -> n));

      // STEP 3: For each parent, validate children total doesn't exceed parent limit
      for (Map.Entry<TextDF, FacilityLimitLine> p : linesByCode.entrySet())
      {
          FacilityLimitLine parent = p.getValue();
          DecimalDF totalOfChildren = DecimalDF.totalize(linesByParent.computeIfAbsent(parent.getFacilityCode(), k -> new ArrayList<>()),
                  FacilityLimitLine::getFacilityLimit);
          if(totalOfChildren.isGreaterThan(parent.getFacilityLimit()))
              Result.createFailureResult("Total limit for child lines of {0} is {1}, and can not exceed {2}",
                  parent.getFacilityCode(), totalOfChildren, parent.getFacilityLimit()).addToAccumulatingResult(result);
      }
  }

  ---
  Part 1: Function<T, R> - The Method Reference Magic

  What is it?

  Function<T, R> is a Java functional interface that takes an input of type T and returns an output of type R.

  The Mental Model - Think of it as a "Getter Extractor"

  Function<T, R> = "Give me a T, I'll give you an R"

  Method Reference Syntax

  ClassName::methodName

  This is shorthand for:
  (object) -> object.methodName()

  Examples to Remember Forever

  // These two are IDENTICAL:
  Function<FacilityLimitLine, TextDF> extractor1 = FacilityLimitLine::getParentCode;
  Function<FacilityLimitLine, TextDF> extractor2 = (line) -> line.getParentCode();

  // Using them:
  FacilityLimitLine line = new FacilityLimitLine();
  TextDF parentCode = extractor1.apply(line);  // Same as line.getParentCode()

  Real-World Analogy

  Think of Function as a vending machine slot:
  - You put in a FacilityLimitLine (the coin)
  - You get out a TextDF (the snack)

  // Different "vending machine slots" for different fields:
  Function<FacilityLimitLine, TextDF> getCode = FacilityLimitLine::getFacilityCode;
  Function<FacilityLimitLine, DecimalDF> getLimit = FacilityLimitLine::getFacilityLimit;
  Function<FacilityLimitLine, GenericReference> getContract = FacilityLimitLine::getProjContract;

  ---
  Part 2: Function.identity() - The "Do Nothing" Function

  What is it?

  Function.identity() returns a function that returns exactly what you give it.

  Function.identity() = (x) -> x

  Why Use It?

  In Collectors.toMap(), you need to specify:
  1. Key extractor: What to use as the map key
  2. Value extractor: What to use as the map value

  When the value IS the object itself, use Function.identity().

  Example in Our Code

  Map<TextDF, FacilityLimitLine> linesByCode = getDetails().stream()
      .collect(Collectors.toMap(
          FacilityLimitLine::getFacilityCode,  // KEY: the facility code
          Function.identity(),                  // VALUE: the line itself (not transformed)
          (o, n) -> n                           // MERGE: if duplicate key, keep new
      ));

  Mental Model

             INPUT                    OUTPUT
  ┌─────────────────────┐      ┌─────────────────────┐
  │  FacilityLimitLine  │ ───► │  FacilityLimitLine  │
  │     (same object)   │      │    (same object)    │
  └─────────────────────┘      └─────────────────────┘
           identity() = "Just give me back what I put in"

  Alternative (Without identity)

  // These are equivalent:
  .collect(Collectors.toMap(FacilityLimitLine::getFacilityCode, Function.identity()))
  .collect(Collectors.toMap(FacilityLimitLine::getFacilityCode, line -> line))

  ---
  Part 3: CollectionsUtility.mapList() - Group Items by Key

  What is it?

  Groups a list into a Map<Key, List<Items>> based on a key extractor.

  Source Code (Simplified)

  public static <K, T> Map<K, List<T>> mapList(List<T> list, Function<T, K> keyExtractor)
  {
      Map<K, List<T>> map = new HashMap<>();
      for (T item : list)
      {
          K key = keyExtractor.apply(item);
          // Get existing list or create new one
          List<T> bucket = map.computeIfAbsent(key, k -> new ArrayList<>());
          bucket.add(item);
      }
      return map;
  }

  Visual Example

  INPUT: List of FacilityLimitLines
  ┌──────────────────────────────────────┐
  │ Line1: parentCode="LG1", limit=1000  │
  │ Line2: parentCode="LG1", limit=500   │
  │ Line3: parentCode="LG2", limit=2000  │
  │ Line4: parentCode="LG1", limit=300   │
  └──────────────────────────────────────┘

  CALLING: CollectionsUtility.mapList(lines, FacilityLimitLine::getParentCode)

  OUTPUT: Map<TextDF, List<FacilityLimitLine>>
  ┌─────────────────────────────────────────────┐
  │ "LG1" → [Line1, Line2, Line4]               │
  │ "LG2" → [Line3]                             │
  └─────────────────────────────────────────────┘

  Real-World Analogy

  Think of it as sorting mail into mailboxes:
  - Each letter (line) has an address (parentCode)
  - You put each letter into the correct mailbox
  - Result: Each mailbox contains all letters for that address

  Common Use Cases

  // Group invoice lines by item
  Map<GenericReference, List<InvoiceLine>> linesByItem =
      CollectionsUtility.mapList(invoice.getLines(), InvoiceLine::getItem);

  // Group employees by department
  Map<Department, List<Employee>> empsByDept =
      CollectionsUtility.mapList(employees, Employee::getDepartment);

  // Group transactions by date
  Map<DateDF, List<Transaction>> txByDate =
      CollectionsUtility.mapList(transactions, Transaction::getTransactionDate);

  ---
  Part 4: DecimalDF.totalize() - Sum Up Values

  What is it?

  Sums up DecimalDF values extracted from a collection of objects.

  The Interface

  public interface Totalizer<T>
  {
      DecimalDF value(T line);
  }

  Method Signature

  public static <T, C extends Collection<T>> DecimalDF totalize(C lines, Totalizer<T> totalizer)

  How It Works

  DecimalDF total = zero();
  for (T line : lines)
  {
      if (line != null)
          total = total.add(totalizer.value(line));  // Extract and add
  }
  return total;

  Using Method Reference (The Magic!)

  Because Totalizer<T> is a functional interface (has only one method), you can use method references!

  // These are equivalent:
  DecimalDF total1 = DecimalDF.totalize(lines, FacilityLimitLine::getFacilityLimit);

  DecimalDF total2 = DecimalDF.totalize(lines, new DecimalDF.Totalizer<FacilityLimitLine>() {
      @Override
      public DecimalDF value(FacilityLimitLine line) {
          return line.getFacilityLimit();
      }
  });

  DecimalDF total3 = DecimalDF.totalize(lines, (line) -> line.getFacilityLimit());

  Visual Example

  INPUT: List of children lines
  ┌────────────────────────────┐
  │ Child1: facilityLimit=1000 │
  │ Child2: facilityLimit=500  │
  │ Child3: facilityLimit=300  │
  └────────────────────────────┘

  CALLING: DecimalDF.totalize(children, FacilityLimitLine::getFacilityLimit)

  PROCESS:
    0 + 1000 = 1000
    1000 + 500 = 1500
    1500 + 300 = 1800

  OUTPUT: DecimalDF(1800)

  Real-World Analogy

  Think of it as a calculator with a "what to add" instruction:
  - Give it a list of receipts
  - Tell it "add up the total field"
  - It returns the grand total

  ---
  Part 5: Map.computeIfAbsent() - Get or Create

  What is it?

  If the key exists, return its value. If not, create a new value, store it, and return it.

  Signature

  V computeIfAbsent(K key, Function<K, V> mappingFunction)

  In Our Code

  linesByParent.computeIfAbsent(parent.getFacilityCode(), k -> new ArrayList<>())

  This means:
  - Look for parent.getFacilityCode() in the map
  - If found: return the existing List<FacilityLimitLine>
  - If NOT found: create new ArrayList<>(), store it, and return it

  Why Use It?

  Prevents NullPointerException when a parent has no children:

  // WITHOUT computeIfAbsent - DANGEROUS!
  List<FacilityLimitLine> children = linesByParent.get(parentCode);
  // children might be NULL if no children exist!
  DecimalDF total = DecimalDF.totalize(children, ...); // CRASH!

  // WITH computeIfAbsent - SAFE!
  List<FacilityLimitLine> children = linesByParent.computeIfAbsent(parentCode, k -> new ArrayList<>());
  // children is NEVER null - worst case it's an empty list
  DecimalDF total = DecimalDF.totalize(children, ...); // Returns zero() for empty list

  ---
  Part 6: Collectors.toMap() with Merge Function

  Basic Form

  Collectors.toMap(keyExtractor, valueExtractor)

  With Merge Function (Handles Duplicates)

  Collectors.toMap(keyExtractor, valueExtractor, mergeFunction)

  In Our Code

  .collect(Collectors.toMap(
      FacilityLimitLine::getFacilityCode,  // Key extractor
      Function.identity(),                  // Value extractor  
      (o, n) -> n                           // Merge: old vs new → keep new
  ))

  The Merge Function (o, n) -> n

  - o = old value (already in map)
  - n = new value (trying to insert)
  - -> n = keep the new one

  Other Merge Options

  (o, n) -> o    // Keep old (first one wins)
  (o, n) -> n    // Keep new (last one wins)
  (o, n) -> { throw new IllegalStateException("Duplicate!"); }  // Crash on duplicate

  ---
  Complete Flow Diagram

  ┌─────────────────────────────────────────────────────────────────────────┐
  │                    validateBranchFacilityLimit                          │
  └─────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ STEP 1: Group children by parent                                        │
  │ CollectionsUtility.mapList(details, FacilityLimitLine::getParentCode)   │
  │                                                                         │
  │ Result: Map<TextDF, List<FacilityLimitLine>>                            │
  │   "LG1" → [child1, child2, child3]                                      │
  │   "LG2" → [child4]                                                      │
  └─────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ STEP 2: Create code→line lookup                                         │
  │ stream().collect(toMap(getFacilityCode, identity(), (o,n)->n))          │
  │                                                                         │
  │ Result: Map<TextDF, FacilityLimitLine>                                  │
  │   "LG1" → parentLine1                                                   │
  │   "LG2" → parentLine2                                                   │
  └─────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ STEP 3: For each parent, validate children total                        │
  │                                                                         │
  │ For parent "LG1" with limit 5000:                                       │
  │   children = linesByParent.computeIfAbsent("LG1", k -> [])              │
  │            = [child1, child2, child3]                                   │
  │                                                                         │
  │   totalOfChildren = DecimalDF.totalize(children, ::getFacilityLimit)    │
  │                   = 1000 + 2000 + 1500 = 4500                           │
  │                                                                         │
  │   if (4500 > 5000) → NO ERROR                                           │
  │   if (6000 > 5000) → ADD ERROR TO RESULT                                │
  └─────────────────────────────────────────────────────────────────────────┘

  ---
  Quick Reference Card (Print This!)

  | Concept                         | What it Does            | Example                          |
  |---------------------------------|-------------------------|----------------------------------|
  | Function<T,R>                   | Takes T, returns R      | FacilityLimitLine::getParentCode |
  | Function.identity()             | Returns input unchanged | line -> line                     |
  | CollectionsUtility.mapList()    | Groups list by key      | Map<Key, List<Item>>             |
  | DecimalDF.totalize()            | Sums extracted values   | total = sum(line.getX())         |
  | computeIfAbsent()               | Get or create default   | Returns [] if no children        |
  | Collectors.toMap(..., (o,n)->n) | List to Map, last wins  | Handle duplicate keys            |

  ---
  Memory Tricks

  1. Function::method = "Extract this field from each object"
  2. identity() = "I want the whole object, not just a field"
  3. mapList = "Sort into buckets by key"
  4. totalize = "Add up this field from all items"
  5. computeIfAbsent = "Get it, or make an empty one"
  6. (o,n)->n = "Old vs New? Keep New"
