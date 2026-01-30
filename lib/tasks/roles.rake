namespace :roles do
  desc "Grant all roles to a user by email. Usage: bin/rails roles:grant_all[user@example.com]"
  task :grant_all, [ :email ] => :environment do |_t, args|
    abort "Usage: bin/rails roles:grant_all[user@example.com]" if args[:email].blank?

    user = User.find_by(email: args[:email])
    abort "User not found: #{args[:email]}" unless user

    user.update!(roles: User::AVAILABLE_ROLES)
    puts "Granted all roles to #{user.email}: #{user.roles.join(', ')}"
  end
end
