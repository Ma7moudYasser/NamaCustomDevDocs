● Now let me explain this code with a clear example:

  Explanation of getMoveReturnDateToFirstWorkday() logic (lines 669-683)

  This feature ensures that the return date (the day the employee comes back to work) is moved to the first actual working day after the vacation ends, skipping any consecutive holidays or weekends.

  Example Scenario

  Let's say:
  - Start Date: December 1st (Sunday)
  - Vacation Period: 5 days
  - Vacation Type: Has moveReturnDateToFirstWorkday = true

  After calculating the basic return date:
  - Basic calculation gives December 6th (Friday) as the return date

  But what if December 6th, 7th, and 8th are:
  - Dec 6 (Fri) - Weekend
  - Dec 7 (Sat) - Weekend
  - Dec 8 (Sun) - Holiday (National Day)

  What the code does step by step:

  // Line 671-673: Get the calculated end date and find all holidays/weekends 
  // in the next 20 days that come AFTER the end date
  DateDF end = specificDate;  // Dec 6
  List<DateDF> holidaysAndWeekends = calcDaysNotIncludedInVacation(...)
      .filter(d -> d.isAfter(end))  // Only dates after Dec 6
      .sorted();  // [Dec 7, Dec 8]

  // Line 674-680: Find consecutive non-working days
  DateDF previous = end;  // Dec 6
  for (DateDF d : holidaysAndWeekends) {
      // Check if this day is consecutive (difference <= 1 day)
      if (d.minusInDays(previous).isGreaterThan(1))
          break;  // Gap found, stop
      previous = d;  // Move forward
  }
  // After loop: previous = Dec 8 (last consecutive non-working day)

  // Line 681-682: If we found consecutive non-working days, move return date
  if (previous.isAfter(end))  // Dec 8 > Dec 6? Yes!
      specificDate = previous.nextDay();  // Return date = Dec 9

  Result:

  Instead of returning on December 6th (a weekend), the employee returns on December 9th (Monday), the first actual working day.

  Visual Timeline:

  Dec 1  2  3  4  5  | 6  7  8  | 9
  [----VACATION----] | [SKIP!]  | RETURN
  Sun Mo Tu We Th    | Fr Sa Su | Mo
                     | WE WE HD | ← First workday

  Why this is useful:

  If an employee's vacation ends on a Friday but the weekend follows, it doesn't make sense to mark Friday as the return day - they would actually return on Monday. This setting automatically adjusts for that.