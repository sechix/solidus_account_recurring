# -*- encoding: utf-8 -*-
# stub: solidus_multi_domain 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'solidus_account_recurring'
  s.version     = '1.0.0'
  s.summary     = 'Solidus extension to manage recurring payments/subscriptions using Stripe Payment Gateway.'
  s.description = s.summary
  s.required_ruby_version = '>= 2.0.0'

  s.author    = 'Mehdi Rejraji'
  s.email     = 'mehdi.rejraji@gmail.com'
  s.homepage  = 'http://github.com/ridem'

  s.files     = Dir['LICENSE', 'README.md', 'app/**/*', 'config/**/*', 'lib/**/*', 'db/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'solidus_core', ['< 3', '>= 1.1.0.pre']
  s.add_dependency 'stripe' 
  s.add_dependency 'stripe_tester'

  s.add_development_dependency 'rspec-rails',  '~> 3.2'
end
