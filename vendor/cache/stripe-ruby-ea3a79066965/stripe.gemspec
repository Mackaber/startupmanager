# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "stripe"
  s.version = "1.24.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ross Boucher", "Greg Brockman"]
  s.date = "2015-08-12"
  s.description = "Stripe is the easiest way to accept payments online.  See https://stripe.com for details."
  s.email = ["boucher@stripe.com", "gdb@stripe.com"]
  s.executables = ["stripe-console"]
  s.files = [".gitignore", ".travis.yml", "CONTRIBUTORS", "Gemfile", "History.txt", "LICENSE", "README.rdoc", "Rakefile", "VERSION", "bin/stripe-console", "gemfiles/default-with-activesupport.gemfile", "gemfiles/json.gemfile", "gemfiles/yajl.gemfile", "lib/data/ca-certificates.crt", "lib/stripe.rb", "lib/stripe/account.rb", "lib/stripe/api_operations/create.rb", "lib/stripe/api_operations/delete.rb", "lib/stripe/api_operations/list.rb", "lib/stripe/api_operations/request.rb", "lib/stripe/api_operations/update.rb", "lib/stripe/api_resource.rb", "lib/stripe/application_fee.rb", "lib/stripe/application_fee_refund.rb", "lib/stripe/balance.rb", "lib/stripe/balance_transaction.rb", "lib/stripe/bank_account.rb", "lib/stripe/bitcoin_receiver.rb", "lib/stripe/bitcoin_transaction.rb", "lib/stripe/card.rb", "lib/stripe/charge.rb", "lib/stripe/coupon.rb", "lib/stripe/customer.rb", "lib/stripe/dispute.rb", "lib/stripe/errors/api_connection_error.rb", "lib/stripe/errors/api_error.rb", "lib/stripe/errors/authentication_error.rb", "lib/stripe/errors/card_error.rb", "lib/stripe/errors/invalid_request_error.rb", "lib/stripe/errors/stripe_error.rb", "lib/stripe/event.rb", "lib/stripe/file_upload.rb", "lib/stripe/invoice.rb", "lib/stripe/invoice_item.rb", "lib/stripe/list_object.rb", "lib/stripe/plan.rb", "lib/stripe/recipient.rb", "lib/stripe/refund.rb", "lib/stripe/reversal.rb", "lib/stripe/singleton_api_resource.rb", "lib/stripe/stripe_object.rb", "lib/stripe/subscription.rb", "lib/stripe/token.rb", "lib/stripe/transfer.rb", "lib/stripe/util.rb", "lib/stripe/version.rb", "stripe.gemspec", "test/stripe/account_test.rb", "test/stripe/api_resource_test.rb", "test/stripe/application_fee_refund_test.rb", "test/stripe/application_fee_test.rb", "test/stripe/balance_test.rb", "test/stripe/bitcoin_receiver_test.rb", "test/stripe/charge_test.rb", "test/stripe/coupon_test.rb", "test/stripe/customer_card_test.rb", "test/stripe/customer_test.rb", "test/stripe/dispute_test.rb", "test/stripe/file_upload_test.rb", "test/stripe/invoice_test.rb", "test/stripe/list_object_test.rb", "test/stripe/metadata_test.rb", "test/stripe/recipient_card_test.rb", "test/stripe/refund_test.rb", "test/stripe/reversal_test.rb", "test/stripe/stripe_object_test.rb", "test/stripe/subscription_test.rb", "test/stripe/transfer_test.rb", "test/stripe/util_test.rb", "test/test_data.rb", "test/test_helper.rb"]
  s.homepage = "https://stripe.com/api"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23.2"
  s.summary = "Ruby bindings for the Stripe API"
  s.test_files = ["test/stripe/account_test.rb", "test/stripe/api_resource_test.rb", "test/stripe/application_fee_refund_test.rb", "test/stripe/application_fee_test.rb", "test/stripe/balance_test.rb", "test/stripe/bitcoin_receiver_test.rb", "test/stripe/charge_test.rb", "test/stripe/coupon_test.rb", "test/stripe/customer_card_test.rb", "test/stripe/customer_test.rb", "test/stripe/dispute_test.rb", "test/stripe/file_upload_test.rb", "test/stripe/invoice_test.rb", "test/stripe/list_object_test.rb", "test/stripe/metadata_test.rb", "test/stripe/recipient_card_test.rb", "test/stripe/refund_test.rb", "test/stripe/reversal_test.rb", "test/stripe/stripe_object_test.rb", "test/stripe/subscription_test.rb", "test/stripe/transfer_test.rb", "test/stripe/util_test.rb", "test/test_data.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, ["~> 1.4"])
      s.add_runtime_dependency(%q<json>, ["~> 1.8.1"])
      s.add_development_dependency(%q<mocha>, ["~> 0.13.2"])
      s.add_development_dependency(%q<shoulda>, ["~> 3.4.0"])
      s.add_development_dependency(%q<test-unit>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<rest-client>, ["~> 1.4"])
      s.add_dependency(%q<json>, ["~> 1.8.1"])
      s.add_dependency(%q<mocha>, ["~> 0.13.2"])
      s.add_dependency(%q<shoulda>, ["~> 3.4.0"])
      s.add_dependency(%q<test-unit>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<rest-client>, ["~> 1.4"])
    s.add_dependency(%q<json>, ["~> 1.8.1"])
    s.add_dependency(%q<mocha>, ["~> 0.13.2"])
    s.add_dependency(%q<shoulda>, ["~> 3.4.0"])
    s.add_dependency(%q<test-unit>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
