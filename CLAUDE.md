# CLAUDE.md

This file provides guidance to Claude Code when working with Frappe/ERPNext in this repository.

---

## CRITICAL: Use MCP for ALL Document Operations

### Primary Method: frappe-erp MCP Tools

**ALWAYS use MCP tools for document CRUD operations:**

```
mcp__frappe-erp__get_document      - Read a document
mcp__frappe-erp__list_documents    - List/search documents
mcp__frappe-erp__create_document   - Create new document
mcp__frappe-erp__update_document   - Update existing document
mcp__frappe-erp__delete_document   - Delete a document
mcp__frappe-erp__get_doctype_info  - Get DocType schema/fields
```

### Example: Update a Workspace

```python
# CORRECT - Use MCP
mcp__frappe-erp__update_document(
    doctype="Workspace",
    name="Sales - Mythril",
    data={
        "type": "Workspace",  # Required field!
        "content": "[{\"id\":\"c1\",\"type\":\"chart\",\"data\":{\"chart_name\":\"Territory Wise Sales\",\"col\":12}}]"
    }
)

# WRONG - Direct SQL
# UPDATE tabWorkspace SET content='...' WHERE name='...'
```

### Before ANY Change: Research First

1. **Use `frappe-developer` agent** to understand DocType structure
2. **Use `mcp__frappe-erp__get_doctype_info`** to see required fields
3. **Use `mcp__frappe-erp__get_document`** to see current values
4. **Check existing working examples** in the database

---

## Frappe v16 Workspace Architecture

### Three Related DocTypes Required

| DocType | Purpose | Key Fields |
|---------|---------|------------|
| **Workspace** | Page content, layout | `type: "Workspace"` (REQUIRED), `content` (JSON), child tables |
| **Workspace Sidebar** | Navigation sidebar | `title`, child `Workspace Sidebar Item` |
| **Desktop Icon** | Shows on desktop | `link_type: "Workspace"`, `link_to`, `logo_url` |

### Workspace Required Fields

```python
{
    "type": "Workspace",      # REQUIRED - options: Workspace, Link, URL
    "label": "My Workspace",  # REQUIRED
    "title": "My Workspace",  # REQUIRED
    "public": 1,
    "content": "[]"           # JSON array of layout blocks
}
```

### Workspace Content Field Structure

The `content` field is a **JSON array** of layout blocks:

```json
[
    {"id": "c1", "type": "chart", "data": {"chart_name": "Territory Wise Sales", "col": 12}},
    {"id": "s1", "type": "spacer", "data": {"col": 12}},
    {"id": "sh1", "type": "shortcut", "data": {"shortcut_name": "Lead", "col": 4}},
    {"id": "sh2", "type": "shortcut", "data": {"shortcut_name": "Opportunity", "col": 4}},
    {"id": "card1", "type": "card", "data": {"card_name": "CRM", "col": 4}}
]
```

**Block types:** `chart`, `shortcut`, `card`, `spacer`, `header`, `number_card`, `quick_list`, `custom_block`

### Valid Frappe Icons

Only use icons that exist in Frappe's icon set:

| Use Case | Valid Icons |
|----------|-------------|
| Lead | `organization`, `users` |
| Opportunity | `sell`, `chart` |
| Customer | `customer` |
| Project | `projects` |
| Task | `list-todo` |
| Timesheet | `calendar-clock` |
| Home | `home` |
| Settings | `settings` |
| CRM | `crm` |

**Invalid icons:** `lead`, `user-plus`, `target`, `opportunity`, `user`

### Creating Workspaces

**Option 1: Via UI** (recommended)
- Go to `/app/workspace/new`
- Automatically creates Workspace, Sidebar, Desktop Icon

**Option 2: Via bench command**
```bash
bench --site sitename create-desktop-icons-and-sidebar
```

**Option 3: Via MCP**
```python
# 1. Create Workspace
mcp__frappe-erp__create_document(
    doctype="Workspace",
    data={
        "label": "My Workspace",
        "title": "My Workspace",
        "type": "Workspace",
        "module": "CRM",
        "icon": "crm",
        "public": 1,
        "content": "[]"
    }
)

# 2. Run sync command
ssh server "docker exec container bench --site site create-desktop-icons-and-sidebar"
```

### Custom Workspace Icons (Desktop)

For custom logo images on Desktop Icons:
- Use `logo_url` field (NOT `icon` field) for image URLs
- Example: `https://xxx.supabase.co/storage/v1/object/public/assets/logo.svg`

---

## NEVER DO These Things

1. **NEVER use direct SQL** for document manipulation
   - No `INSERT INTO`, `UPDATE`, `DELETE` on DocType tables
   - Exception: Read-only queries for debugging

2. **NEVER manually write malformed JSON** to content fields
   - Always validate JSON structure
   - Use MCP which handles escaping correctly

3. **NEVER guess icon names** - research valid icons first

4. **NEVER restart Docker containers** for cache clearing
   - Use `bench --site sitename clear-cache`
   - Container restart changes IPs and causes 502 errors

5. **NEVER run `bench build` in Docker production**
   - Docker images have pre-built assets with specific hashes
   - Running build creates mismatched hashes

6. **NEVER bypass document validation**
   - MCP tools properly trigger validate, on_update hooks
   - Direct SQL skips all hooks

---

## When Things Break

1. **STOP** - Don't keep trying random fixes
2. **Use `frappe-developer` agent** to research the correct approach
3. **Check DocType schema** with `mcp__frappe-erp__get_doctype_info`
4. **Look at working examples** with `mcp__frappe-erp__list_documents`
5. **Fix systematically** using MCP update

---

## Project Structure

### Docker Production (mythril.local)
```
/home/ec2-user/kraken-template/
├── docker-compose.yml
├── sites/                    # Shared volume
│   └── mythril.local/
└── apps/                     # Mounted app volumes
```

**SSH Access:**
```bash
ssh mythril-kraken "docker exec kraken-template-backend-1 bench --site mythril.local [command]"
```

### Development (kraken.localhost)
```
/workspace/development/
├── apps/
│   ├── frappe/
│   ├── erpnext/
│   └── kraken/
└── sites/
    └── kraken.localhost/
```

---

## Common MCP Patterns

### List documents with filters
```python
mcp__frappe-erp__list_documents(
    doctype="Workspace Sidebar Item",
    filters={"parent": "Sales - Mythril"},
    fields=["name", "label", "icon", "link_to"]
)
```

### Update child table items
```python
mcp__frappe-erp__update_document(
    doctype="Workspace Sidebar Item",
    name="item_id",
    data={"icon": "organization"}
)
```

### Check DocType required fields
```python
mcp__frappe-erp__get_doctype_info(doctype="Workspace")
# Returns fields with reqd=1 that must be provided
```

---

## Cache Management

```bash
# Clear Frappe cache (correct way)
docker exec container bench --site sitename clear-cache

# If Redis issues persist
docker exec redis-cache-container redis-cli FLUSHALL

# NEVER restart backend just for cache - causes 502 errors
```

---

## Sites

- **mythril.local**: Production site on Docker (arkangel.ca)
- **kraken.localhost**: Development site
- Admin: Administrator (check site_config.json for password)
