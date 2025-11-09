# Development Rules & Guidelines

## 🏗️ Architecture Rules

### 1. Clean Architecture Principles
- **Separation of Concerns**: Each layer has a single responsibility
- **Dependency Inversion**: Inner layers don't depend on outer layers
- **Feature-Based Structure**: Group by features, not technical layers

### 2. Offline-First Implementation
- **Always Cache First**: Load from local cache before network
- **Queue Operations**: Store create/update operations when offline
- **Sync Strategy**: Background sync when connection is restored
- **Error Handling**: Graceful degradation when offline

### 3. State Management Rules
- **Minimal State**: Keep only necessary data in memory
- **Immutable Models**: Use immutable data structures
- **Single Source of Truth**: Repository pattern for data access

## 💻 Code Quality Standards

### 1. Dart/Flutter Best Practices
- **Null Safety**: Always use null-aware operators
- **Const Constructors**: Use const wherever possible
- **Widget Composition**: Prefer composition over inheritance
- **Extract Widgets**: Keep build methods small and readable

### 2. File Organization
```dart
// File structure example
import 'package:flutter/material.dart';  // Flutter imports first
import 'package:some_package/package.dart';  // Package imports second

import '../../../core/theme/app_theme.dart';  // Relative imports last
import '../widgets/moment_card.dart';

// Class implementation
```

### 3. Naming Conventions
- **Classes**: PascalCase (e.g., `MomentRepository`)
- **Variables/Methods**: camelCase (e.g., `getCurrentLocation`)
- **Files**: snake_case (e.g., `moment_detail_page.dart`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `API_BASE_URL`)

## 🎨 UI/UX Guidelines

### 1. Design Consistency
- **Theme System**: Use centralized theme configuration
- **Component Library**: Reusable widgets with consistent styling
- **Spacing System**: Use 8dp grid system (8, 16, 24, 32, etc.)
- **Typography Scale**: Consistent font sizes and weights

### 2. Animation Guidelines
- **Duration Standards**:
  - Micro interactions: 150-200ms
  - Page transitions: 300-400ms
  - Loading states: 500ms+
- **Easing**: Use spring physics for natural motion
- **Performance**: Avoid excessive animations, use Transform over layout changes

### 3. Accessibility
- **Semantic Labels**: Provide meaningful labels for screen readers
- **Touch Targets**: Minimum 44pt touch targets
- **Color Contrast**: Maintain WCAG AA standards
- **Focus Management**: Proper focus flow for keyboard navigation

## 📱 Platform Considerations

### 1. Cross-Platform Consistency
- **Material Design**: Primary design language for both platforms
- **Platform Adaptations**: Use platform-specific widgets when beneficial
- **Safe Areas**: Handle notches and safe areas properly
- **Keyboard Handling**: Proper keyboard avoidance and focus

### 2. Performance Rules
- **Image Optimization**: Use appropriate image formats and sizes
- **Memory Management**: Dispose of controllers and listeners
- **Build Optimization**: Use const constructors and avoid rebuilds
- **Bundle Size**: Keep dependencies minimal and necessary

## 🔒 Security & Privacy

### 1. Data Protection
- **API Keys**: Never commit secrets to version control
- **Environment Variables**: Use .env for sensitive configuration
- **Image Privacy**: Implement proper access controls for user content
- **Local Storage**: Encrypt sensitive local data

### 2. Supabase Integration
- **Row Level Security**: Implement RLS policies
- **API Rate Limiting**: Handle rate limits gracefully
- **Error Handling**: Don't expose internal errors to users
- **Offline Security**: Validate data integrity when syncing

## 🧪 Testing Strategy

### 1. Test Pyramid
- **Unit Tests**: Test business logic and utilities
- **Widget Tests**: Test UI components in isolation
- **Integration Tests**: Test feature flows end-to-end

### 2. Test Categories
- **Data Layer**: Repository and model tests
- **Presentation Layer**: Widget and page tests
- **Animation Tests**: Verify smooth motion and timing
- **Offline Tests**: Verify offline-first behavior

## 🚀 Deployment Guidelines

### 1. Version Management
- **Semantic Versioning**: Use semver for releases
- **Build Numbers**: Auto-increment for each build
- **Release Notes**: Document all user-facing changes

### 2. Platform Specifics
- **iOS**: Handle App Store requirements and guidelines
- **Android**: Follow Google Play policies
- **Permissions**: Request minimal necessary permissions
- **App Icons**: Provide all required icon sizes

## 🔧 Development Workflow

### 1. Git Practices
- **Feature Branches**: One branch per feature
- **Commit Messages**: Use conventional commit format
- **Code Reviews**: All code must be reviewed before merge
- **Clean History**: Use rebase for clean commit history

### 2. Code Quality Gates
- **Linting**: All code must pass dart analyze
- **Formatting**: Use dart format consistently
- **Tests**: Maintain test coverage above 80%
- **Performance**: Profile before optimizing

## 📊 Monitoring & Analytics

### 1. Error Tracking
- **Crash Reporting**: Implement comprehensive crash tracking
- **Error Boundaries**: Graceful error handling
- **User Feedback**: Easy way for users to report issues

### 2. Performance Monitoring
- **Frame Rate**: Monitor for 60fps consistency
- **Memory Usage**: Track memory leaks
- **Network Performance**: Monitor API response times
- **Battery Usage**: Optimize for battery efficiency
