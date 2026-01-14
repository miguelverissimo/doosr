# PRD: Journal Password Protection

## Introduction

Add global password protection to the journaling system, allowing users to secure all their journal entries behind a single password. Journal fragment content will be encrypted at rest in the database, providing true privacy even from database administrators. Users can unlock journals once per browser session, and recover access via a mnemonic seed phrase if they forget their password.

## Goals

- Allow users to set a global journal password that protects all their journals
- Encrypt `JournalFragment.content` at rest in the database using the user's password-derived key
- Persist unlock state per browser session (localStorage/cookie)
- Provide password recovery via a 12-word mnemonic seed phrase
- Show journal dates in lists but hide fragment counts and content when locked
- Maintain seamless UX for users who don't enable password protection

## User Stories

### US-001: Add journal encryption fields to user model
**Description:** As a developer, I need database fields to store journal password hash, encrypted seed phrase, and salt so the encryption system has persistent state.

**Acceptance Criteria:**
- [ ] Add migration with fields: `journal_password_digest` (string, nullable), `journal_encryption_salt` (string, nullable), `encrypted_seed_phrase` (text, nullable), `journal_protection_enabled` (boolean, default false)
- [ ] Migration runs successfully
- [ ] Typecheck passes

### US-002: Add encrypted content column to journal_fragments
**Description:** As a developer, I need to store encrypted content alongside or replacing the plaintext content field.

**Acceptance Criteria:**
- [ ] Add `encrypted_content` (text, nullable) column to journal_fragments
- [ ] Add `content_iv` (string, nullable) for initialization vector storage
- [ ] Existing `content` column remains for backward compatibility during migration
- [ ] Migration runs successfully
- [ ] Typecheck passes

### US-003: Create encryption service
**Description:** As a developer, I need a service to handle encryption/decryption of journal fragment content using AES-256-GCM.

**Acceptance Criteria:**
- [ ] Create `Journals::EncryptionService` with `encrypt(plaintext, key)` and `decrypt(ciphertext, iv, key)` methods
- [ ] Use AES-256-GCM for authenticated encryption
- [ ] Derive encryption key from password + user-specific salt using PBKDF2 or Argon2
- [ ] Service returns IV along with ciphertext
- [ ] Unit tests pass for encrypt/decrypt round-trip
- [ ] Typecheck passes

### US-004: Create mnemonic seed phrase service
**Description:** As a developer, I need a service to generate and validate BIP39-style mnemonic seed phrases for password recovery.

**Acceptance Criteria:**
- [ ] Create `Journals::MnemonicService` with `generate` and `validate(phrase)` methods
- [ ] Generate 12-word phrases from a standard word list
- [ ] Seed phrase can derive the same encryption key deterministically
- [ ] Unit tests pass
- [ ] Typecheck passes

### US-005: Enable journal protection settings page
**Description:** As a user, I want to enable journal protection and set my password from a settings page so I can secure my journals.

**Acceptance Criteria:**
- [ ] Add "Journal Protection" section to user settings (or dedicated route `/settings/journal_protection`)
- [ ] Form with password field and password confirmation field
- [ ] On submit: generate seed phrase, derive encryption key, encrypt seed phrase with password, save to user record
- [ ] Display seed phrase ONCE with clear warning to save it
- [ ] Checkbox to confirm user has saved the seed phrase before enabling
- [ ] Success toast on completion
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### US-006: Encrypt existing journal fragments on protection enable
**Description:** As a user, when I enable protection, my existing journal fragments should be encrypted with my new password.

**Acceptance Criteria:**
- [ ] Background job encrypts all user's existing `JournalFragment` records
- [ ] Each fragment's `content` is encrypted to `encrypted_content` with unique IV
- [ ] Original `content` field is cleared after successful encryption
- [ ] Progress indicator or notification when complete
- [ ] Typecheck passes

### US-007: Journal unlock dialog
**Description:** As a user, I want to enter my journal password to unlock journals for this browser session so I can view my entries.

**Acceptance Criteria:**
- [ ] When accessing any journal route while locked, show unlock dialog
- [ ] Password input field with submit button
- [ ] On correct password: derive key, store session token in localStorage, dismiss dialog
- [ ] On incorrect password: show error message, remain on dialog
- [ ] "Forgot password?" link navigates to recovery flow
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### US-008: Session unlock persistence
**Description:** As a user, I want my journal unlock to persist for my browser session so I don't have to re-enter password constantly.

**Acceptance Criteria:**
- [ ] Store encrypted session token in localStorage on successful unlock
- [ ] Token contains derived key encrypted with a session-specific secret
- [ ] Check token validity on each journal access
- [ ] Token invalidated on logout or browser close
- [ ] Stimulus controller manages unlock state client-side
- [ ] Typecheck passes

### US-009: Decrypt fragments on journal view
**Description:** As a user, when I view a journal while unlocked, I want to see my decrypted fragment content.

**Acceptance Criteria:**
- [ ] `JournalFragment#content` method checks if user has protection enabled
- [ ] If protected and unlocked: decrypt `encrypted_content` using session key
- [ ] If protected and locked: return placeholder or raise error
- [ ] If not protected: return `content` directly (backward compatible)
- [ ] Journal show page displays decrypted content normally
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### US-010: Encrypt new fragments on create
**Description:** As a user, when I create a new journal fragment while protection is enabled, it should be encrypted automatically.

**Acceptance Criteria:**
- [ ] `JournalFragment` before_save callback checks if user has protection enabled
- [ ] If enabled: encrypt content to `encrypted_content`, clear plaintext `content`
- [ ] Use encryption key from current session
- [ ] Fragment saves successfully with encrypted data
- [ ] Typecheck passes

### US-011: Show locked state in journal lists
**Description:** As a user, I want to see which journals exist (by date) but not see fragment counts or content previews when locked.

**Acceptance Criteria:**
- [ ] Journal index shows journal dates normally
- [ ] Fragment count badge hidden or shows lock icon when locked
- [ ] Journal link items in day view show lock icon instead of fragment count
- [ ] No content previews visible when locked
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### US-012: Password recovery via seed phrase
**Description:** As a user, if I forget my password, I want to recover access using my seed phrase so I don't lose my journals.

**Acceptance Criteria:**
- [ ] "Forgot password?" from unlock dialog navigates to recovery page
- [ ] Form accepts 12-word seed phrase input
- [ ] On valid phrase: derive original encryption key
- [ ] Prompt for new password and confirmation
- [ ] Re-encrypt seed phrase with new password, update password digest
- [ ] Re-encrypt all fragments with new password-derived key (background job)
- [ ] Success message and redirect to journals
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### US-013: Disable journal protection
**Description:** As a user, I want to disable journal protection and decrypt all my journals if I no longer want this feature.

**Acceptance Criteria:**
- [ ] Settings page shows "Disable Protection" button when enabled
- [ ] Requires current password confirmation
- [ ] Background job decrypts all fragments back to plaintext `content`
- [ ] Clears `journal_password_digest`, `encrypted_seed_phrase`, sets `journal_protection_enabled` to false
- [ ] Success toast on completion
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### US-014: Change journal password
**Description:** As a user, I want to change my journal password without losing access to my encrypted journals.

**Acceptance Criteria:**
- [ ] Settings page shows "Change Password" option when protection enabled
- [ ] Requires current password and new password with confirmation
- [ ] Re-encrypt seed phrase with new password
- [ ] Re-encrypt all fragments with new password-derived key (background job)
- [ ] Update password digest
- [ ] Invalidate existing session tokens
- [ ] Success toast on completion
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

## Functional Requirements

- FR-1: Add `journal_password_digest`, `journal_encryption_salt`, `encrypted_seed_phrase`, `journal_protection_enabled` columns to users table
- FR-2: Add `encrypted_content` and `content_iv` columns to journal_fragments table
- FR-3: Implement `Journals::EncryptionService` using AES-256-GCM with PBKDF2/Argon2 key derivation
- FR-4: Implement `Journals::MnemonicService` for 12-word seed phrase generation and validation
- FR-5: Create journal protection setup flow in settings with seed phrase display
- FR-6: Create journal unlock dialog that appears when accessing protected journals while locked
- FR-7: Store unlock session state in localStorage with encrypted session token
- FR-8: Automatically encrypt new journal fragments when protection is enabled
- FR-9: Decrypt journal fragments on read when user is unlocked
- FR-10: Show lock icon and hide fragment details in journal lists when locked
- FR-11: Implement password recovery flow using seed phrase
- FR-12: Implement password change flow with re-encryption
- FR-13: Implement protection disable flow with full decryption
- FR-14: Background jobs for bulk encryption/decryption operations using Solid Queue

## Non-Goals

- Per-journal passwords (all journals share one password)
- Biometric authentication (fingerprint, face ID)
- Hardware key support (YubiKey, etc.)
- Encryption of journal prompts or prompt templates
- Time-based auto-lock (user stays unlocked for entire browser session)
- Sharing encrypted journals with other users
- Export/import of encrypted journals

## Technical Considerations

- **Encryption**: Use Ruby's OpenSSL library for AES-256-GCM encryption
- **Key Derivation**: PBKDF2 with high iteration count (100,000+) or Argon2id if available via gem
- **Salt**: Unique per-user salt stored in `journal_encryption_salt`
- **IV**: Unique per-fragment IV stored in `content_iv` (required for GCM mode)
- **Session Storage**: Encrypted key stored in localStorage, validated server-side on each request
- **Background Jobs**: Use existing Solid Queue infrastructure for bulk encryption operations
- **Backward Compatibility**: Users without protection enabled continue using plaintext `content` field
- **Mnemonic Words**: Use BIP39 English word list (2048 words) for seed phrase generation

## Design Considerations

- Unlock dialog should use existing `RubyUI::Dialog` component
- Lock icon should use existing icon component pattern (`Components::Icon::Lock`)
- Seed phrase display should be prominent with copy button and clear warning styling
- Settings section should clearly indicate current protection status
- Recovery flow should feel secure but not intimidating

## Success Metrics

- Users can enable journal protection in under 2 minutes
- Unlock flow completes in under 3 seconds
- Zero plaintext content visible in database for protected journals
- Password recovery via seed phrase works 100% of the time
- No performance degradation on journal page loads (<100ms added latency)

## Open Questions

- Should we add a "view seed phrase again" option (requires password confirmation)?
- Should password have minimum complexity requirements?
- Should we rate-limit unlock attempts to prevent brute force?
- Should we notify users via email when protection is enabled/disabled?
- What happens to journal fragments if a background encryption job fails mid-way?
