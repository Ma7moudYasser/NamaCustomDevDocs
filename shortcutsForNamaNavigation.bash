● Essential IntelliJ IDEA Shortcuts for NamaERP Navigation

  File & Class Navigation

  | Shortcut         | Action           | Use Case                                     |
  |------------------|------------------|----------------------------------------------|
  | Ctrl+Shift+N     | Go to File       | Find any file by name (e.g., Customer.java)  |
  | Ctrl+N           | Go to Class      | Jump to any Java class directly              |
  | Ctrl+Shift+Alt+N | Go to Symbol     | Find methods, fields, or variables by name   |
  | Ctrl+E           | Recent Files     | Quick access to files you've been working on |
  | Ctrl+Shift+E     | Recent Locations | Jump to exact code locations you visited     |

  Code Navigation

  | Shortcut             | Action               | Use Case                                            |
  |----------------------|----------------------|-----------------------------------------------------|
  | Ctrl+B or Ctrl+Click | Go to Declaration    | Jump to where a class/method/field is defined       |
  | Ctrl+Alt+B           | Go to Implementation | Find implementations of interfaces/abstract methods |
  | Ctrl+U               | Go to Super Method   | Jump to parent class implementation                 |
  | Ctrl+F12             | File Structure       | See all methods/fields in current file              |
  | Alt+F7               | Find Usages          | Find everywhere a class/method/field is used        |
  | Ctrl+Shift+F7        | Highlight Usages     | Highlight usages in current file                    |

  Search & Find

  | Shortcut     | Action            | Use Case                                     |
  |--------------|-------------------|----------------------------------------------|
  | Shift+Shift  | Search Everywhere | Universal search for files, classes, actions |
  | Ctrl+Shift+F | Find in Path      | Search text across entire project            |
  | Ctrl+Shift+R | Replace in Path   | Search and replace across project            |
  | Ctrl+H       | Type Hierarchy    | See class inheritance hierarchy              |
  | Ctrl+Alt+H   | Call Hierarchy    | See what calls a method                      |

  Code Editing

  | Shortcut         | Action              | Use Case                   |
  |------------------|---------------------|----------------------------|
  | Alt+Enter        | Quick Fix           | Show suggestions and fixes |
  | Ctrl+Space       | Basic Completion    | Code completion            |
  | Ctrl+Shift+Space | Smart Completion    | Context-aware completion   |
  | Ctrl+P           | Parameter Info      | Show method parameters     |
  | Ctrl+Q           | Quick Documentation | View Javadoc popup         |

  Window & Tool Navigation

  | Shortcut   | Action              | Use Case                              |
  |------------|---------------------|---------------------------------------|
  | Alt+1      | Project Tool Window | Toggle project explorer               |
  | Alt+9      | Git Tool Window     | Toggle git panel                      |
  | Alt+Ctrl+L | Server Logs         | Show server logs (NamaERP specific)   |
  | Ctrl+Tab   | Switcher            | Switch between open files/tools       |
  | Escape     | Return to Editor    | Close any tool window, return to code |

  NamaERP-Specific Tips

  1. Finding Entity Classes: Use Ctrl+N and type the entity name (e.g., SalesInvoice)
  2. Finding DSL Definitions: Search for *Dsl.java files in the *dsl modules
  3. Finding Post Actions: Use Ctrl+Shift+F to search for PostActor or specific entity post actions
  4. Navigating Module Structure: Use Ctrl+Shift+N and type pom.xml to see all modules
  5. Finding Migrators: Search for classes extending MigratorBase

  Pro Tips

  - Bookmark Important Code: Ctrl+Shift+[0-9] to set bookmarks, Ctrl+[0-9] to jump to them
  - Navigate Back/Forward: Ctrl+Alt+Left/Right to go back/forward in navigation history
  - Compare with Clipboard: Ctrl+Shift+V shows clipboard history for pasting

  These shortcuts will significantly speed up navigation in the large NamaERP codebase with its 20+ modules.
