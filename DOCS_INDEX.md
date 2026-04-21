# Moments App - Documentation Index

Welcome to the Moments app documentation! This index will help you navigate all planning and technical documents.

---

## 📚 Quick Start Guide

**New to the project?** Read in this order:
1. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - High-level overview
2. [README.md](README.md) - Setup instructions
3. [PLAN.md](PLAN.md) - Development roadmap
4. [CHECKLIST.md](CHECKLIST.md) - Start implementing
**Ready to code?** You need:
- [RULES.md](RULES.md) - Coding standards
- [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) - Implementation details
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Database reference

**Working with AI?** Check:
- [AGENTS.md](AGENTS.md) - AI agent integration guide

---

## 🆕 New Docs (2026-03-15)

### PowerSync
- [docs/powersync/sync-streams-primer.md](docs/powersync/sync-streams-primer.md)
- [docs/powersync/sync-streams-for-current-schema.md](docs/powersync/sync-streams-for-current-schema.md)
- [docs/powersync/offline-first-domain-rollout.md](docs/powersync/offline-first-domain-rollout.md)
- [docs/powersync/chat-quick-win.md](docs/powersync/chat-quick-win.md)

### Product
- [docs/product/memory-lane-redesign-playbook.md](docs/product/memory-lane-redesign-playbook.md)
- [docs/product/new-social-diary-features.md](docs/product/new-social-diary-features.md)
- [docs/product/stories-strategy.md](docs/product/stories-strategy.md)

---

## 📖 Document Reference

### 1. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
**Purpose:** High-level project overview  
**Read When:** First time exploring the project  
**Contains:**
- What we've accomplished
- Project vision
- Architecture overview
- Timeline and phases
- Success metrics

**Best For:** Understanding the big picture

---

### 2. [README.md](README.md)
**Purpose:** Getting started guide  
**Read When:** Setting up development environment  
**Contains:**
- Project description
- Installation steps
- Environment setup
- Key packages
- Running the app

**Best For:** First-time setup

---

### 3. [PLAN.md](PLAN.md)
**Purpose:** Comprehensive development plan  
**Read When:** Planning work or understanding features  
**Contains:**
- Core features breakdown
- Technical architecture
- 5-phase implementation plan
- Challenges and solutions
- Future enhancements

**Best For:** Strategic planning and feature design

---

### 4. [RULES.md](RULES.md)
**Purpose:** Coding standards and best practices  
**Read When:** Before writing any code  
**Contains:**
- Code style guidelines
- Architecture rules
- Performance optimization
- Error handling patterns
- Testing requirements
- Git workflow

**Best For:** Ensuring code quality and consistency

---

### 5. [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md)
**Purpose:** Detailed technical specifications  
**Read When:** Implementing specific features  
**Contains:**
- Core functions and logic flows
- UI component specifications
- State management patterns
- Animation specifications
- Data models with Brick
- Performance optimization

**Best For:** Implementation details and code examples

---

### 6. [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)
**Purpose:** Database and API reference  
**Read When:** Working with data or backend  
**Contains:**
- Complete SQL schema
- Table definitions
- RLS policies
- Storage bucket setup
- API endpoint examples
- Dart model definitions
- Migration scripts

**Best For:** Database operations and Supabase integration

---

### 7. [AGENTS.md](AGENTS.md)
**Purpose:** AI agent integration guide  
**Read When:** Using AI assistants or MCP servers  
**Contains:**
- Project context for AI
- MCP server usage (Dart & Supabase)
- Common workflows
- File structure reference
- Troubleshooting guide
- Decision trees for agents

**Best For:** AI-assisted development

---

### 8. [CHECKLIST.md](CHECKLIST.md)
**Purpose:** Step-by-step implementation guide  
**Read When:** Daily development work  
**Contains:**
- 13 implementation phases
- 200+ actionable tasks
- Progress tracking
- Daily workflow
- Testing checklist

**Best For:** Task tracking and progress monitoring

---

## 🎯 Use Cases

### "I'm starting development today"
1. Read [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
2. Follow [README.md](README.md) setup
3. Review [RULES.md](RULES.md)
4. Start [CHECKLIST.md](CHECKLIST.md) Phase 1

### "I need to implement the map feature"
1. Review Map section in [PLAN.md](PLAN.md)
2. Check Map specifications in [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md)
3. Follow Map tasks in [CHECKLIST.md](CHECKLIST.md)
4. Reference [RULES.md](RULES.md) for coding standards

### "I need to set up the database"
1. Open [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)
2. Use Supabase MCP (see [AGENTS.md](AGENTS.md))
3. Run migration scripts
4. Configure RLS policies
5. Update [CHECKLIST.md](CHECKLIST.md)

### "I'm getting an error"
1. Check [AGENTS.md](AGENTS.md) troubleshooting section
2. Review relevant section in [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md)
3. Verify against [RULES.md](RULES.md) patterns
4. Check [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) if data-related

### "I'm working with an AI assistant"
1. Share [AGENTS.md](AGENTS.md) with the AI
2. Reference [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) for details
3. Point to [RULES.md](RULES.md) for standards
4. Use [CHECKLIST.md](CHECKLIST.md) for context

### "I'm reviewing code"
1. Check against [RULES.md](RULES.md)
2. Verify architecture in [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md)
3. Ensure data models match [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)
4. Confirm task completion in [CHECKLIST.md](CHECKLIST.md)

---

## 📊 Document Matrix

| Document | Planning | Setup | Implementation | Reference | AI Integration |
|----------|----------|-------|----------------|-----------|----------------|
| PROJECT_SUMMARY | ✅ | ✅ | - | - | - |
| README | - | ✅ | - | ✅ | - |
| PLAN | ✅ | - | ✅ | - | - |
| RULES | - | - | ✅ | ✅ | - |
| TECHNICAL_SPEC | ✅ | - | ✅ | ✅ | - |
| DATABASE_SCHEMA | ✅ | ✅ | ✅ | ✅ | - |
| AGENTS | - | - | - | ✅ | ✅ |
| CHECKLIST | - | ✅ | ✅ | - | - |

---

## 🔍 Quick Reference

### Architecture
- **Overview:** [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md#architecture-overview)
- **Details:** [PLAN.md](PLAN.md#technical-architecture)
- **Implementation:** [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md)

### Database
- **Schema:** [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md#supabase-database-schema)
- **Models:** [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md#data-models)
- **Setup:** [CHECKLIST.md](CHECKLIST.md#environment-setup)

### UI/UX
- **Design System:** [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md#design-system)
- **Components:** [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md#ui-component-specifications)
- **Animations:** [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md#animation-system)

### Features
- **Map View:** [PLAN.md](PLAN.md#1-map-view-main-screen)
- **Moment Details:** [PLAN.md](PLAN.md#2-moment-detail-page)
- **Create Moment:** [PLAN.md](PLAN.md#3-add-moment-page)

### Standards
- **Code Style:** [RULES.md](RULES.md#code-style--standards)
- **Architecture Rules:** [RULES.md](RULES.md#architecture-rules)
- **Testing:** [RULES.md](RULES.md#testing-requirements)

### MCP Servers
- **Dart MCP:** [AGENTS.md](AGENTS.md#1-dart-mcp-server)
- **Supabase MCP:** [AGENTS.md](AGENTS.md#2-supabase-mcp-server)
- **Workflows:** [AGENTS.md](AGENTS.md#agent-workflow-guidelines)

---

## 🎨 Visual Guide

```
Moments App Documentation
│
├── 📄 PROJECT_SUMMARY.md ────────► Start here for overview
│
├── 📖 README.md ─────────────────► Setup & installation
│
├── 🗺️ PLAN.md ──────────────────► Features & roadmap
│   ├── Core Features
│   ├── Architecture
│   └── Timeline
│
├── 📏 RULES.md ──────────────────► Coding standards
│   ├── Style Guide
│   ├── Best Practices
│   └── Anti-Patterns
│
├── 🔧 TECHNICAL_SPEC.md ─────────► Implementation details
│   ├── Functions & Logic
│   ├── UI Components
│   └── Data Models
│
├── 🗄️ DATABASE_SCHEMA.md ────────► Database reference
│   ├── Tables
│   ├── RLS Policies
│   └── API Examples
│
├── 🤖 AGENTS.md ─────────────────► AI integration
│   ├── MCP Servers
│   ├── Workflows
│   └── Troubleshooting
│
└── ✅ CHECKLIST.md ──────────────► Task tracking
    ├── Phase 1-13
    ├── Daily Tasks
    └── Progress Tracking
```

---

## 📱 Mobile Quick Links

For quick mobile reference:

**Setup:** [README](README.md)  
**Tasks:** [CHECKLIST](CHECKLIST.md)  
**Standards:** [RULES](RULES.md)  
**Reference:** [TECHNICAL_SPEC](TECHNICAL_SPEC.md)  

---

## 💡 Pro Tips

1. **Bookmark this index** - Fastest way to find what you need
2. **Start with PROJECT_SUMMARY** - Best overview
3. **Keep CHECKLIST open** - Track daily progress
4. **Reference RULES often** - Maintain quality
5. **Use AGENTS for AI help** - Maximize automation

---

## 🔄 Document Updates

All documents are living and will be updated as the project evolves. When updating:

1. Update the relevant document
2. Update this index if structure changes
3. Update PROJECT_SUMMARY if major changes
4. Update CHECKLIST if new tasks added

---

## 📞 Need Help?

**Can't find something?**
- Use your IDE's search across all .md files
- Check this index for the right document
- Look at the Quick Reference section above

**Still stuck?**
- Review PROJECT_SUMMARY for context
- Check AGENTS.md for troubleshooting
- Consult TECHNICAL_SPEC for implementation details

---

**Happy Coding! 🚀**

*Last Updated: November 8, 2025*

