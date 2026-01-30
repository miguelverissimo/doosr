class AssignAllRolesToExistingUsers < ActiveRecord::Migration[8.1]
  def up
    all_roles = %w[day well lists notes journals checklists fixed_calendar accounting banking admin]

    User.where("roles = '{}' OR roles IS NULL").find_each do |user|
      user.update_column(:roles, all_roles)
    end
  end

  def down
    # No-op: cannot determine which roles users had before
  end
end
