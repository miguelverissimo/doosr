class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def can_destroy?
    self.class.reflect_on_all_associations.all? do |assoc|
      dependent_option = assoc.options[:dependent]
      if dependent_option == :restrict || dependent_option == :restrict_with_error
        # If restricted, check if association is empty
        (assoc.macro == :has_one && self.send(assoc.name).nil?) ||
          (assoc.macro == :has_many && self.send(assoc.name).empty?)
      else
        # If not restricted, it's OK
        true
      end
    end
  end
end
