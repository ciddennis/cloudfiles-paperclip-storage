$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')

include_files = ["README*", "LICENSE", "Rakefile", "init.rb", "{lib,tasks,test,rails,generators,shoulda_macros}/**/*"].map do |glob|
  Dir[glob]
end.flatten
exclude_files = ["test/s3.yml", "test/debug.log", "test/paperclip.db", "test/doc", "test/doc/*", "test/pkg", "test/pkg/*", "test/tmp", "test/tmp/*"].map do |glob|
  Dir[glob]
end.flatten

spec = Gem::Specification.new do |s|
  s.name              = "paperclip_cloud_storage"
  s.version           = "0.1"
  s.author            = "Cid Dennis"
  s.email             = "cid.dennis@gmail.com"
  s.homepage          = "http://github.com/ciddennis/cloudfiles-paperclip-storage"
  s.description       = "Store Paperclip files on Rackspace CloudFiles"
  s.platform          = Gem::Platform::RUBY
  s.summary           = "Store Paperclip files on Rackspace CloudFiles"
  s.files             = include_files - exclude_files
  s.require_path      = "lib"
  s.test_files        = Dir["test/**/test_*.rb"]
  s.has_rdoc          = true
  s.extra_rdoc_files  = Dir["README*"]
  s.rdoc_options << '--line-numbers' << '--inline-source'
  s.requirements << "paperclip"
  s.requirements << "cloudfiles"
  s.add_dependency 'activerecord'
  s.add_dependency 'activesupport'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'sqlite3-ruby'
end
