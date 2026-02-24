● Here's a comprehensive guide to the POS module as a new developer:                                                                                                                                                                
   
  ---                                                                                                                                                                                                                               
  POS Module - Developer Guide                                                                                                                                                                                                    
                                                                                                                                                                                                                                    
  The POS system has two main parts that work together:                                                                                                                                                                             

  1. The Two Codebases

  ┌────────────────────┬──────────────────┬───────────────────────────────────────────────────────────┐
  │      Codebase      │     Location     │                          Purpose                          │
  ├────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ Standalone POS App │ pos/             │ Desktop JavaFX application that runs on each POS terminal │
  ├────────────────────┼──────────────────┼───────────────────────────────────────────────────────────┤
  │ ERP POS Module     │ modules/namapos/ │ Server-side module integrated into the ERP backend        │
  └────────────────────┴──────────────────┴───────────────────────────────────────────────────────────┘

  Think of it this way: the pos/ app is what the cashier sees and uses. The modules/namapos/ module is what the ERP server uses to store, process, and report on POS data.

  ---
  2. Standalone POS App (pos/)

  This is a JavaFX + Spring Boot desktop app. Here's the package structure:

  pos/src/main/java/com/namasoft/pos/
  ├── application/       ← Entry point + all UI screens
  │   ├── PosEntryPoint.java         ← Main class (Spring Boot + JavaFX hybrid)
  │   ├── LoginScreen.java           ← Login UI
  │   ├── POSNewSalesScreen.java     ← Main sales screen (invoices, returns)
  │   ├── POSNewShiftsScreen.java    ← Shift open/close
  │   ├── POSPaymentReciptScreen.java← Payment processing
  │   ├── POSReportsScreen.java      ← Reporting
  │   └── POSShiftInventoryScreen.java← Stock operations
  ├── controllers/       ← REST endpoints (for mobile POS integration)
  ├── domain/            ← Business entities (sales, payments, shifts)
  │   ├── AbsPOSSales.java           ← Base sales document
  │   ├── AbsPOSPayReceipt.java      ← Payment/receipt base
  │   └── details/                   ← Line items (sales lines, payment lines)
  ├── util/              ← Core utilities
  │   ├── POSDataReaderUtil.java     ← Pulls data FROM ERP server
  │   ├── POSDataWriterUtil.java     ← Pushes transactions TO ERP server
  │   ├── POSResourcesUtil.java      ← Cached master data (register, config)
  │   ├── POSPersister.java          ← Hibernate database operations
  │   ├── POSConfigurationUtil.java  ← POS configuration
  │   └── CoreWSClient.java          ← REST client for ERP backend
  ├── orm/               ← Database layer (Hibernate, migrations)
  └── Migrator/          ← 40+ database migration scripts

  Application Startup Flow

  POSMainForShade.main()
    → PosEntryPoint (JavaFX Application + Spring Boot)
      → Load nama.properties (DB connection, server URL, register code)
      → Test database connection
      → Run database migrations
      → Load master data from ERP (items, customers, prices)
      → Show LoginScreen
      → After login → POSNewSalesScreen (main screen)

  ---
  3. ERP POS Module (modules/namapos/)

  This follows the standard 5-layer architecture used by all ERP modules:

  modules/namapos/
  ├── namaposdsl/        ← Entity definitions (@NaMaEntity annotations)
  │                        Define fields, types, relationships here
  ├── namaposdomain/     ← Generated + hand-coded domain entities
  │                        Business logic, validations, calculations
  ├── namaposcontracts/  ← DTOs and service interfaces
  │                        What gets sent over the wire (REST/SOAP)
  ├── namaposservices/   ← Web service implementations
  │                        REST/SOAP endpoints served by the ERP server
  └── namaposgui/        ← UI post-actions for the ERP web interface
                           Customizes how POS entities look in the ERP UI

  ---
  4. How Data Flows (The Big Picture)

     POS Desktop App                          ERP Server
     ─────────────                          ──────────────

     Cashier scans item
     → POSNewSalesScreen
     → AbsPOSSales (domain entity)
     → POSPersister (save to local DB)
                       ──── REST API ────→  namaposservices (web services)
     POSDataWriterUtil                      → namaposdomain (business logic)
     (background sync)                      → Database (central ERP DB)
                                            → Accounting integration

                       ←── REST API ────
     POSDataReaderUtil                      Sends master data updates
     (pulls items, prices, customers)       (items, prices, customers)

  Key insight: The POS app has its own local database and works offline. It syncs with the ERP server in the background using POSDataReaderUtil (pull) and POSDataWriterUtil (push).

  ---
  5. Key Entities

  ┌───────────────────────────────────┬─────────────────────────────────────────────────────────────────┐
  │              Entity               │                           What It Is                            │
  ├───────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ NamaPOSRegister                   │ A physical POS terminal (its config, warehouse, receipt format) │
  ├───────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ POSShiftOpening / POSShiftClosing │ Opening/closing a cashier shift with cash counts                │
  ├───────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ NamaPOSSalesInvoice               │ A sales transaction (the main document)                         │
  ├───────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ NamaPOSSalesReturn                │ A return transaction                                            │
  ├───────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ NamaPOSSalesReplacement           │ Item exchange/replacement                                       │
  ├───────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ AbsPOSPaymentRecipt               │ Fund deposits and withdrawals                                   │
  ├───────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ POSSecurityProfile                │ User permissions (what a cashier can/can't do)                  │
  ├───────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ NamaPOSTable / NamaPOSHall        │ Restaurant table/hall management                                │
  └───────────────────────────────────┴─────────────────────────────────────────────────────────────────┘

  ---
  6. How Screens Work

  Screens use JavaFX with an MVC-like pattern:

  1. defineControllers() - Creates UI components (text fields, tables, buttons)
  2. createScene() - Lays out the components
  3. bindDataToUI() - Binds domain entity fields to UI controls (JavaFX bindings)
  4. Save flow - Validates → saves to local DB via POSPersister → queues for ERP sync

  The base class AbsPosSalesScreen provides common functionality for all sales-related screens.

  ---
  7. Configuration

  The POS app reads nama.properties at startup:
  pos-register-code=REG001         # Which register this terminal is
  pos-server-url=http://server/erp  # ERP server URL
  db-url=jdbc:sqlserver://...       # Local database connection
  db-user=sa
  db-password=***

  POSResourcesUtil caches master data (register info, POS config, users) so the app doesn't query constantly.

  ---
  8. Hardware Integration

  The POS app integrates with:
  - Cash drawers - CashDrawerUtil
  - Customer display poles - DisplayPoleConnectorUtil (serial port)
  - Fingerprint readers - FingerprintLoginHelper (Digital Persona)
  - Payment terminals - PGWUtil, NearPay
  - Barcode scanners - Via keyboard input + NamaPOSItemBarcodeParser

  ---
  9. Building & Running

  # Build the standalone POS app
  cd pos
  mvn clean install -DskipTests=true

  # Build the ERP POS module
  cd modules/namapos
  mvn clean install -DskipTests=true

  # Build the Go launcher (wraps the Java app)
  cd pos-launcher
  go build -o pos-launcher.exe

  ---
  10. Where to Start as a New Developer

  1. Read PosEntryPoint.java - understand the startup sequence
  2. Read POSNewSalesScreen.java - the main screen cashiers use
  3. Read AbsPOSSales.java - the core sales domain model
  4. Read POSDataReaderUtil / POSDataWriterUtil - how sync works
  5. Look at the DSL entities in namaposdsl/ - they define the data model
  6. Check POSResourcesUtil - understand what's cached and available

  Feel free to ask about any specific area you want to dive deeper into!