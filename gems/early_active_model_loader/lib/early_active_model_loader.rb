require "active_model"

module EarlyActiveModelLoader
  RAILS_APPLICATION_WAS_NIL_WHEN_LOADED = Rails.application.nil?

  class Model
    include ActiveModel::Model
  end
end
