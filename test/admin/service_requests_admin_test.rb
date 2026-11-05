require "test_helper"

class ServiceRequestsAdminTest < ActiveSupport::TestCase
  test "service request tabs have distinct ids (one per kind plus All)" do
    Rails.application.reload_routes!
    resource = ActiveAdmin.application.namespaces[:admin].resource_for(ServiceRequest)
    ids = resource.scopes.map(&:id)

    assert_equal ["all", *ServiceRequest::KINDS.keys], ids
  end
end
