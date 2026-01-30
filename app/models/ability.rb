class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user

    user.roles.each do |role|
      can :access, role.to_sym
    end
  end
end
