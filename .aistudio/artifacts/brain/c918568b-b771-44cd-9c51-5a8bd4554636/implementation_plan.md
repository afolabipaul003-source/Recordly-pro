# Recordly — Financial & Records Management Architecture

Recordly is an expandable financial management and record-keeping platform designed for community contribution groups, associations, event organizers, and small businesses. It unifies dues collection, business operations, and debt tracking into a single intuitive, mobile-first workspace with instant offline reliability and cloud synchronization.

---

### User Review & Critical Decisions

> [!IMPORTANT]
> The architectural blueprint below summarizes both the existing production capabilities and the next milestones of the Recordly platform. Review the core modules, data flow, and upcoming feature roadmap below.

- **Storage & Synchronization**: Hybrid offline-first architecture utilizing browser `localStorage` as an immediate local operational database with transparent fallback and Supabase authentication/cloud sync.
- **Authentication Modes**: Flexible sign-in supporting traditional email/password, passwordless 6-digit Gmail/Email OTP confirmation, mobile phone SMS OTP verification, and secure password recovery.
- **Universal Visibility & Privacy**: Personal progress links (`#/p/:id`) and public group comparison tables (`#/g/:id`) expose only designated contributor progress while keeping business sales, expenses, and debts strictly confidential.

---

### 1. Overview & Core Concept

- **What It Does**: Recordly gives individuals, associations, and small businesses complete visibility over their money: tracking what came in, what is due, what remains, and whether operating expenses leave a healthy net margin.
- **Target Personas**:
  1. *Contribution Organizers*: Managing community dues, alumni associations, thrift collections, and event levies.
  2. *Small Business Owners & Merchants*: Managing customers, recorded sales, credit/unpaid orders, operating expenses, and receipts.
  3. *Lenders & Individuals*: Keeping track of money lent to others (receivables) and debts owed to suppliers or creditors (payables).
- **Key Value**: Eliminates lost records and mental arithmetic by combining 4 financial management sections into one dashboard with automated balance calculations, printable receipts, and overdue alerts.

---

### 2. User Experience & Visual Design

- **Key User Flows**:
  - **Quick Entry Flow**: Users land on the dashboard to review high-level totals (Collected Cash, Owed to You, Debts Payable, Estimated Margin). 1-tap quick action buttons launch modals for New Contribution, Record Sale, Add Expense, or Track Debt.
  - **Contribution & Progress Flow**: Group admin sets title, optional description/bank transfer details, per-person target, and deadline. As payments are logged, real-time percentage progress bars update, and digital receipts can be printed or shared.
  - **Business Ledger Flow**: Log a sale to a saved customer or walk-in, specify line items and initial deposit, auto-categorize status (`Paid`, `Partial`, `Credit`), and collect balances over time.
  - **Debt Lifecycle Flow**: Log money owed to you or owed to others, track partial repayments, and receive alerts when due dates pass.
  - **Universal Search Flow**: Tap `🔍` in the header or press `/` to instantly search across contributions, member names, business sales, customer profiles, and debt balances.

- **Visual Identity & Theme**:
  - *Color Palette*:
    - Emerald Green (`--primary: #0f766e` / `#14b8a6`): Denoting verified collections, completed contributions, and healthy margins.
    - Indigo Blue (`--accent-blue: #2563eb`): Used for business sales and invoices.
    - Amber Gold (`--accent-amber: #d97706`): Used for pending balances and upcoming deadlines.
    - Rose Red (`--accent-red: #e11d48`): Used for overdue debts and expenses.
  - *Dark / Light Mode*: One-tap persistent theme switcher in the top navigation and settings tab supporting midnight dark posture (`#0b0f19`) and clean daylight posture (`#f4f6fb`).
  - *Typography*: Clean system sans-serif hierarchy with bold tabular figures for Nigerian Naira (`₦`) monetary values.
  - *Documents & Receipts*: Ink-friendly `@media print` styling that hides UI controls and renders official receipts with reference IDs, timestamps, and payment purposes.

---

### 3. Key Product Decisions & Trade-Offs

- **Decision 1: Client-Side Offline-First Storage with Cloud Sync Option**
  - *Chosen Approach*: Store records in indexed local memory (`localStorage`) and sync with Supabase when user authentication is active.
  - *Why*: Ensures zero-latency operations, uninterrupted offline usability on mobile networks, and immediate responsiveness without network failures blocking transactions.
  - *Alternatives Considered*: Pure server-side relational database only (rejected because network latency or temporary downtime would prevent shopkeepers or event organizers from recording payments).

- **Decision 2: Mobile-First Bottom Navigation Bar**
  - *Chosen Approach*: Persistent bottom bar with labeled icons for phones (`Dashboard`, `Contributions`, `Business`, `Debts`, `Reports`, `More`) that transforms into an elevated top bar on desktop viewports.
  - *Why*: Solves user feedback regarding complex desktop sidebars on mobile screens, keeping primary actions accessible within one-handed thumb reach.

- **Decision 3: Group Descriptions & Transparent Banking Instructions**
  - *Chosen Approach*: Dedicated description field editable by group administrators and displayed on both public group links (`#/g/:id`) and member personal links (`#/p/:id`).
  - *Why*: Enables group members visiting shared links to immediately see the purpose of the collection, rules, and bank account numbers for direct transfers.

---

### 4. Technical Architecture & Data Strategy

#### System Component Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Recordly Web Client                             │
│                                                                        │
│  ┌─────────────────────── Top Header & Controls ───────────────────┐  │
│  │ Brand | Universal Search (🔍) | Theme (🌙/☀️) | Bell | Auth Pill │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  ┌──────────────────────── Master Router ──────────────────────────┐  │
│  │  #/ (Dashboard)        #/contributions     #/business           │  │
│  │  #/debts               #/reports           #/notifications      │  │
│  │  #/p/:id (Member Link) #/g/:id (Group Link)                     │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  ┌────────────────────── Functional Modules ───────────────────────┐  │
│  │  [Contributions]     [Small Business]        [Debt Tracker]     │  │
│  │  • Targets & Dues    • Line Item Sales       • Receivables      │  │
│  │  • Member Rosters    • Expense Categories    • Payables         │  │
│  │  • Payment Histories • Customer Directory    • Repayments       │  │
│  │  • Official Receipts • Outstanding Credit    • Overdue Badges   │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  ┌──────────────────── Core Infrastructure ────────────────────────┐  │
│  │  • Offline-First Store (localStorage)                           │  │
│  │  • Supabase Client (Email OTP, SMS OTP, Password Recovery, RPC) │  │
│  │  • CSV Exporter & Print Engine (@media print)                   │  │
│  └─────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

#### Core Data Entities

1. **Contribution Record**:
   - `id`: Unique identifier (`rec_...`)
   - `title`: Name of collection / group
   - `description`: Admin explanation, purpose, and bank payment instructions
   - `target`: Target amount per person in ₦
   - `end_date`: Collection deadline
   - `show_table`: Boolean allowing public group comparison
   - `group_link`: Boolean enabling public group link
   - `people`: Array of members `{ id, name, phone, payments: [{ id, amount, paid_on, method, note }] }`

2. **Business Sale**:
   - `id`: Unique identifier (`sale_...`)
   - `customer_id` & `customer_name`: Buyer details
   - `items`: Line items `[{ name, qty, price }]`
   - `total`: Auto-calculated total `(qty * price)`
   - `amount_paid`: Immediate cash collected
   - `status`: `'paid'` | `'partial'` | `'unpaid'`
   - `payments`: Incremental payment installments

3. **Business Expense**:
   - `id`: Unique identifier (`exp_...`)
   - `category`: `Inventory`, `Transport`, `Rent`, `Utilities`, `Salaries`, `Marketing`, `Equipment`, `Other`
   - `description`: Expense purpose
   - `amount`: Cost in ₦
   - `date`: Expense date

4. **Debt Record**:
   - `id`: Unique identifier (`debt_...`)
   - `type`: `'receivable'` (owed to me) | `'payable'` (I owe)
   - `person_name` & `phone`: Debtor or creditor
   - `original_amount`: Principal debt in ₦
   - `due_date`: Repayment deadline
   - `repayments`: Array of payments `[{ id, amount, date, note }]`
