# Modern Rails Full-Stack Curriculum for Backend Devs

## Prerequisites
- Rails 7.1+ (8.0 recommended for newest features)
- Ruby 3.2+
- Node.js/Yarn for asset pipeline

---

## PHASE 1: Hotwire Foundation (Week 1)

### 1.1 Turbo Drive, Frames, and Streams
**What you'll learn:** Replace full page reloads with partial updates, no React needed

**Best Resources:**
- [Turbo Handbook (Official)](https://turbo.hotwired.dev/handbook/introduction) - Read introduction through streams
- [Hotwire Demo Video by DHH](https://hotwired.dev/) - 20min overview of the full stack
- [GoRails: Turbo Frames](https://gorails.com/episodes/turbo-frames) - Free episode
- [GoRails: Turbo Streams](https://gorails.com/episodes/turbo-streams) - Free episode

**Practice Exercise:** Build a simple CRUD app where:
- Index uses Turbo Frames for inline editing
- Create/Update broadcasts changes via Turbo Streams
- Delete removes items without page reload

### 1.2 Stimulus JS Basics
**What you'll learn:** Sprinkle minimal JS for interactive components

**Best Resources:**
- [Stimulus Handbook (Official)](https://stimulus.hotwired.dev/handbook/introduction) - Read through "Working with External Resources"
- [Better Stimulus](https://www.betterstimulus.com/) - Practical patterns and examples
- [Stimulus Components](https://www.stimulus-components.com/) - Prebuilt components to learn from

**Practice Exercise:** Build these Stimulus controllers:
- Dropdown menu
- Modal dialog
- Form validation
- Auto-save draft

---

## PHASE 2: Authentication (Week 1-2)

### 2.1 Devise Setup
**Resources:**
- [Devise GitHub README](https://github.com/heartcombo/devise) - Official setup guide
- [GoRails: Devise from Scratch](https://gorails.com/episodes/devise-hotwire-turbo) - Turbo-compatible setup
- [Devise + Turbo GitHub](https://github.com/heartcombo/devise/wiki/How-To:-Upgrade-to-Devise-4.9.0-%5BHotwire-Turbo-integration%5D)

### 2.2 OmniAuth Integration
**Resources:**
- [OmniAuth README](https://github.com/omniauth/omniauth)
- [Devise + OmniAuth Guide](https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview) - Official wiki
- [GoRails: OAuth with Devise](https://gorails.com/episodes/omniauth-facebook-login) - Pattern applies to any provider

**Practice Exercise:** Set up:
- Email/password login with Devise
- Google OAuth
- GitHub OAuth
- Proper user model associations

---

## PHASE 3: Styling (Week 2)

### 3.1 Tailwind CSS in Rails
**Resources:**
- [Tailwind Rails Official](https://github.com/rails/tailwindcss-rails) - Setup via gem
- [Tailwind Docs](https://tailwindcss.com/docs) - Learn utility-first CSS
- [Tailwind UI Components (Free)](https://tailwindui.com/components) - Copy patterns from free tier

### 3.2 Component Libraries
**For Radix/shadcn in Rails:**

**Problem:** shadcn/ui is React-specific. Here's the Rails equivalent:

**Resources:**
- [PhlexUI](https://github.com/PhlexUI/phlex_ui) - shadcn-like components for Rails using Phlex
- [Phlex Documentation](https://www.phlex.fun/) - Learn the Ruby component system
- Alternative: [ViewComponent](https://viewcomponent.org/) + [LookBook](https://lookbook.build/)

**My Addition:** You'll need to choose:
- **Option A:** Use PhlexUI (closest to shadcn philosophy)
- **Option B:** Use ViewComponent + build your own from Tailwind UI
- **Option C:** Use [DaisyUI](https://daisyui.com/) (Tailwind plugin with components)

**Practice Exercise:** Build a component library with:
- Button variants
- Form inputs with errors
- Card layouts
- Alert/Toast notifications

---

## PHASE 4: Real-Time Features (Week 3)

### 4.1 Action Cable + Turbo Streams
**What you'll learn:** Broadcast database changes to all connected users

**Resources:**
- [Action Cable Overview](https://guides.rubyonrails.org/action_cable_overview.html) - Official Rails guide
- [Turbo Streams + Broadcasts](https://turbo.hotwired.dev/handbook/streams#broadcasting-turbo-streams-from-models) - Official pattern
- [GoRails: Real-time Updates](https://gorails.com/episodes/turbo-streams-and-action-cable) - Free
- [Hotwire Cookbook: Presence](https://philreynolds.dev/posts/hotwire-cookbook-building-a-real-time-presence-feature) - See who's online

**Practice Exercise:**
- Build a chat/comments section that updates live
- Add "user is typing..." indicator
- Show online/offline status
- Private channels vs broadcast channels

### 4.2 Background Jobs
**Resources:**
- [Solid Queue (Rails 8)](https://github.com/basecamp/solid_queue) - New default queue backend
- [Turbo Streams from Jobs](https://thoughtbot.com/blog/hotwire-reactive-rails-with-no-javascript) - Broadcast after processing

---

## PHASE 5: PWA Setup (Week 3-4)

### 5.1 Progressive Web App Basics
**Resources:**
- [PWA Builder Documentation](https://www.pwabuilder.com/docs) - Understand PWA fundamentals
- [Rails PWA Gem](https://github.com/jonhue/pwa) - Service worker + manifest helpers
- [Modern PWA Guide](https://web.dev/learn/pwa/) - Google's comprehensive guide

**My Addition:** You need to add gem 'pwa' to your Gemfile

Then create:
- manifest.json with app metadata
- Service worker for offline caching
- Install prompt handling with Stimulus

**Resources:**
- [Service Workers in Rails](https://rossta.net/blog/service-worker-on-rails.html) - Detailed guide
- [Installable Rails App Tutorial](https://dev.to/coorasse/rails-7-pwa-tutorial-2aac) - Step-by-step

**Practice Exercise:**
- Make app installable on iOS/Android
- Add offline fallback page
- Cache static assets
- Show install prompt

---

## PHASE 6: Deployment (Week 4)

### 6.1 Coolify Deployment
**Resources:**
- [Coolify Documentation](https://coolify.io/docs/) - Official setup
- [Rails on Coolify Guide](https://coolify.io/docs/knowledge-base/frameworks/rails) - Rails-specific
- [Kamal (Alternative)](https://kamal-deploy.org/) - DHH's Docker deployment tool

**My Addition:** You'll need:
- PostgreSQL database setup
- Redis for Action Cable
- Asset compilation strategy
- Environment variables management

**Deployment Checklist:**
Use a standard Rails Dockerfile and ensure: assets precompile, database migrations, Redis connection for Action Cable, and HTTPS/SSL for PWA

**Resources:**
- [Rails Docker Template](https://github.com/rails/rails/blob/main/Dockerfile) - Official Rails 8 Dockerfile
- [Production Rails Guide](https://guides.rubyonrails.org/configuring.html#configuring-for-production) - Official

---

## PHASE 7: Advanced Patterns (Ongoing)

### 7.1 Form Patterns
**Resources:**
- [Inline Editing](https://www.colby.so/posts/turbo-frames-in-practice-inline-editing) - Turbo Frames pattern
- [Multi-step Forms](https://thoughtbot.com/blog/building-a-multi-step-form-with-hotwire) - With Turbo
- [Dynamic Nested Forms](https://www.driftingruby.com/episodes/nested-forms-from-scratch-with-stimulusjs) - Stimulus pattern

### 7.2 Search & Filtering
**Resources:**
- [Ransack Gem](https://github.com/activerecord-hackery/ransack) - Search objects
- [Turbo-Powered Search](https://evilmartians.com/chronicles/hotwire-reactive-rails-with-no-javascript) - Live filtering
- [Pagy Gem](https://github.com/ddnexus/pagy) - Fast pagination

### 7.3 File Uploads
**Resources:**
- [Active Storage Guide](https://guides.rubyonrails.org/active_storage_overview.html) - Official
- [Direct Uploads + Turbo](https://evilmartians.com/chronicles/active-storage-meets-hotwire-or-how-to-upload-files-with-progress-bar) - With progress bars

---

## BONUS: Testing

**Resources:**
- [System Tests with Turbo](https://thoughtbot.com/blog/a-guide-to-system-testing-turbo-frames-with-ruby-on-rails) - Test real-time features
- [Capybara Docs](https://github.com/teamcapybara/capybara) - Browser testing

---

## MY ADDITIONS FOR YOUR STACK

### Essential Gems
Add these to your Gemfile:
- devise
- omniauth
- omniauth-google-oauth2
- omniauth-github
- omniauth-rails_csrf_protection
- tailwindcss-rails
- phlex-rails (for PhlexUI)
- phlex_ui
- pwa
- redis (for Action Cable)
- solid_queue (Rails 8 default)
- hotwire-livereload (development only)

### Project Structure
app/
├── components/        # Phlex components
├── javascript/
│   ├── controllers/   # Stimulus controllers
│   └── application.js
├── views/
│   └── layouts/
│       └── application.html.erb
└── channels/          # Action Cable channels

public/
├── manifest.json
└── service-worker.js

### Authentication Flow
1. Devise for base auth
2. OmniAuth callbacks in users/omniauth_callbacks_controller.rb
3. After login, redirect to Turbo stream for instant UI update

### Real-Time Pattern
In your models, use:
- after_create_commit { broadcast_prepend_to "posts" }
- after_update_commit { broadcast_replace_to "posts" }
- after_destroy_commit { broadcast_remove_to "posts" }

### PWA Requirements
- HTTPS in production (required for service workers)
- 512x512 PNG icon
- Theme color in manifest
- Service worker scope

---

## LEARNING PATH

**Week 1:**
- Day 1-2: Turbo fundamentals
- Day 3-4: Stimulus basics
- Day 5-7: Build practice CRUD app

**Week 2:**
- Day 1-3: Devise + OAuth setup
- Day 4-7: Tailwind + component library

**Week 3:**
- Day 1-4: Action Cable + real-time features
- Day 5-7: PWA implementation

**Week 4:**
- Day 1-3: Coolify deployment
- Day 4-7: Polish and advanced patterns

---

## VALIDATION PROJECT

Build a **Team Task Manager** with:
- Email + Google login
- Real-time task updates
- Private team channels
- Public roadmap view
- Installable PWA
- Styled with Tailwind components

This hits every requirement and proves you've mastered the stack.

---

## Key Philosophy

Rails is your full-stack framework. Hotwire lets you build "reactive" UIs without leaving Rails conventions. You're not fighting the framework—you're using it as designed in 2025.
