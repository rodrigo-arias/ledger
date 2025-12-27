# Roadmap - Ledger App

## Phase Summary

| Phase | Name | Status |
|-------|------|--------|
| 1 | Models + Setup | ✓ Done |
| 2 | Expenses | ✓ Done |
| 3 | Balance | ✓ Done |
| 4 | Payments & Closing | ✓ Done |
| 5 | CloudKit Sync | Pending |
| 6 | Expense Groups | Pending |
| 7 | Extras | Pending |
| 8 | Subscriptions | Pending |

---

## Phase 1: Models + Setup ✓

### Completed
- [x] `Household` model (root container)
- [x] `Person` model (2 members)
- [x] `Expense` model (amount, currency, category, payer)
- [x] `Category` model (6 default categories)
- [x] `MonthlyConfig` model (exchange rate, income)
- [x] `Payment` model (payments between people)
- [x] `MonthlyClose` model (closing snapshot)
- [x] `HouseholdSetupView` (onboarding)
- [x] SwiftData configured
- [x] iOS + macOS support

---

## Phase 2: Expenses ✓

### Completed
- [x] `ExpenseListView` - list with filters (by person)
- [x] Grouping by month or category
- [x] `AddExpenseView` - form with concept suggestions
- [x] `ExpenseDetailView` - edit/delete
- [x] `ExpenseRowView` - row with emoji, concept, amount
- [x] `MonthlyConfigView` - configure exchange rate and income
- [x] Multi-currency ARS/USD
- [x] Automatic USD→ARS conversion
- [x] Argentine formatting (. thousands, , decimals)
- [x] Contribution percentage calculated

---

## Phase 3: Balance ✓

### Completed
- [x] `MonthSelectorView` - global month/year selector
- [x] Integrate selector in `MainTabView`
- [x] Update `ExpenseListView` for variable month
- [x] `BalanceCalculator` - calculation logic
- [x] Complete `BalanceView` (summary, by person, by category, final balance)
- [x] Previous month carry-over with visual indicators
- [x] Fixed expenses with `isFixedExpense` toggle (category-independent)
- [x] Historical/closed months support
- [x] `MonthlyConfigView` (exchange rate, income, fixed expenses debtor)
- [x] Negative expenses support (refunds/credit notes)

---

## Phase 4: Payments & Closing ✓

### Completed
- [x] Simplified `Payment` model (amount, currency, date, monthlyClose)
- [x] `MonthlyClose` model with `isClosed` and `payments` relationship
- [x] `MonthCloseView` - register payments and close/reopen month
- [x] `PaymentFormView` - add/edit payment with suggestions
- [x] Integration in `BalanceView` (blue button, shows pending balance)
- [x] Block expense editing in closed months
- [x] Multi-currency support in payments (ARS/USD)

---

## Phase 5: CloudKit Sync

### Goals
- Sync between Apple devices
- Share Household between 2 users
- Offline-first

### Tasks
- [ ] Configure CloudKit container in Xcode
- [ ] Add container ID in entitlements
- [ ] Migrate models to CloudKit-compatible
- [ ] Implement CKShare for Household
- [ ] UI to invite other user
- [ ] UI to accept invitation
- [ ] Conflict handling (last-write-wins)
- [ ] Sync status indicator
- [ ] Testing with 2 devices

---

## Phase 6: Expense Groups

### Goals
- Create event summaries (vacations, trips, etc.)
- Select existing expenses
- View totals by currency

### ExpenseGroup Model
```
- name: String ("Summer Trip")
- expenses: [Expense]
- createdAt: Date
- household: Household
```

### Tasks
- [ ] Create `ExpenseGroup` model
- [ ] `ExpenseGroupListView` - list of groups
- [ ] `CreateExpenseGroupView` - create new
  - Group name
  - Multiple expense selector
- [ ] `ExpenseGroupDetailView` - view summary
  - List of included expenses
  - Total ARS
  - Total USD
  - By person
  - By category
- [ ] Allow adding/removing expenses from existing group
- [ ] An expense can belong to multiple groups

---

## Phase 7: Extras

### 7.1 Charts
- [ ] Expense history (timeline)
- [ ] Expense history by category
- [ ] Pie chart by category (current month)

### 7.2 UX Improvements
- [ ] Duplicate expense
- [ ] Dark mode verified
- [ ] iOS/macOS Widgets

### 7.3 Export
- [ ] Export to CSV
- [ ] Export to PDF (monthly summary)
- [ ] Annual summary

### 7.4 iOS Integrations
- [ ] Siri Shortcuts ("Add expense $X in category Y")

---

## Phase 8: Subscriptions

### Goals
- Track recurring subscriptions per user (separate from shared expenses)
- Calculate total monthly cost across all subscriptions
- View cost breakdown by category

### Subscription Model
```
- service: String ("Netflix", "Spotify")
- cost: Decimal
- currency: Currency (ARS/USD)
- periodicity: Periodicity (monthly/annual)
- renewalDate: Date
- category: Category
- person: Person
- household: Household
```

### Cost Calculation
- Monthly periodicity → monthly cost = cost
- Annual periodicity → monthly cost = cost / 12

### Tasks
- [ ] Create `Subscription` model
- [ ] Create `Periodicity` enum (monthly, annual)
- [ ] `SubscriptionListView` - list by user
- [ ] `AddSubscriptionView` - form
- [ ] `SubscriptionDetailView` - edit/delete
- [ ] Monthly cost summary view
- [ ] Cost by category chart
- [ ] Renewal date reminders (optional)

---

## Phase Dependencies

```
Phase 1 ─► Phase 2 ─► Phase 3 ─► Phase 4 ─► Phase 5
                                    │
                                    ├──► Phase 6
                                    ├──► Phase 7
                                    └──► Phase 8
```

- Phases 1-4: sequential (core functionality)
- Phase 5: CloudKit sync (priority - enables shared usage)
- Phase 6-8: independent, can be done in any order after phase 4

---

## Technical Notes

### Stack
- SwiftUI + SwiftData
- iOS 26+ / macOS 26+
- CloudKit (phase 5)

### Architecture
- Local-first
- Immutable events (expenses, payments)
- Snapshots for closings
- Derived calculations (don't store totals)

### Conventions
- Default currency: ARS
- Locale: es_AR
- Optional dates in expenses
