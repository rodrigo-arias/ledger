# Roadmap - Ledger App

## Phase Summary

| Phase | Name | Status |
|-------|------|--------|
| 1 | Models + Setup | ✓ Done |
| 2 | Expenses | ✓ Done |
| 3 | Balance | ✓ Done |
| 4 | Payments & Closing | ✓ Done |
| 5 | Expense Groups | Pending |
| 6 | Extras | Pending |
| 7 | CloudKit Sync | Pending |

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

## Phase 5: Expense Groups

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

## Phase 6: Extras

### 6.1 Charts
- [ ] Expense history (timeline)
- [ ] Expense history by category
- [ ] Pie chart by category (current month)

### 6.2 UX Improvements
- [ ] Duplicate expense
- [ ] Dark mode verified
- [ ] iOS/macOS Widgets

### 6.3 Export
- [ ] Export to CSV
- [ ] Export to PDF (monthly summary)
- [ ] Annual summary

### 6.4 iOS Integrations
- [ ] Siri Shortcuts ("Add expense $X in category Y")

---

## Phase 7: CloudKit Sync

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

## Phase Dependencies

```
Phase 1 ─► Phase 2 ─► Phase 3 ─► Phase 4
                          │
                          ▼
                       Phase 5
                          │
                          ▼
                       Phase 6
                          │
                          ▼
                       Phase 7
```

- Phases 1-4: sequential (core functionality)
- Phase 5: requires phase 3 (needs expense selector)
- Phase 6: independent, can be done in parallel
- Phase 7: at the end (requires stable functionality)

---

## Technical Notes

### Stack
- SwiftUI + SwiftData
- iOS 17+ / macOS 14+
- CloudKit (phase 7)

### Architecture
- Local-first
- Immutable events (expenses, payments)
- Snapshots for closings
- Derived calculations (don't store totals)

### Conventions
- Default currency: ARS
- Locale: es_AR
- Optional dates in expenses
