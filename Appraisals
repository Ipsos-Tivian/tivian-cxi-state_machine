appraise "default" do
end

# ActiveRecord integrations
if RUBY_VERSION < "1.9.2"
  appraise "active_record-2.0.0" do
    gem "sqlite3-ruby"
    gem "activerecord", "2.0.0"
  end
  
  appraise "active_record-2.0.5" do
    gem "sqlite3-ruby"
    gem "activerecord", "2.0.5"
  end
  
  appraise "active_record-2.1.0" do
    gem "sqlite3-ruby"
    gem "activerecord", "2.1.0"
  end
  
  appraise "active_record-2.1.2" do
    gem "sqlite3-ruby"
    gem "activerecord", "2.1.2"
  end
  
  appraise "active_record-2.2.3" do
    gem "sqlite3-ruby"
    gem "activerecord", "2.2.3"
  end
end

appraise "active_record-2.3.12" do
  gem "sqlite3-ruby"
  gem "activerecord", "2.3.12"
end

if RUBY_VERSION > "1.8.6"
  appraise "active_record-3.0.0" do
    gem "sqlite3-ruby"
    gem "activerecord", "3.0.0"
  end

  appraise "active_record-3.0.5" do
    gem "sqlite3-ruby"
    gem "activerecord", "3.0.5"
  end
end

# ActiveModel integrations
if RUBY_VERSION > "1.8.6"
  appraise "active_model-3.0.0" do
    gem "activemodel", "3.0.0"
  end

  appraise "active_model-3.0.5" do
    gem "activemodel", "3.0.5"
  end
end

# MongoMapper integrations
if RUBY_VERSION > "1.8.6" && RUBY_VERSION < "1.9.2"
  appraise "mongo_mapper-0.5.5" do
    gem "activesupport", "2.3.11"
    gem "mongo_mapper", "0.5.5"
  end
end

if RUBY_VERSION > "1.8.6"
  appraise "mongo_mapper-0.5.8" do
    gem "activesupport", "2.3.11"
    gem "mongo_mapper", "0.5.8"
  end

  appraise "mongo_mapper-0.6.0" do
    gem "activesupport", "2.3.11"
    gem "mongo_mapper", "0.6.0"
  end

  appraise "mongo_mapper-0.6.10" do
    gem "activesupport", "2.3.11"
    gem "mongo_mapper", "0.6.10"
  end

  appraise "mongo_mapper-0.7.0" do
    gem "activesupport", "2.3.11"
    gem "mongo_mapper", "0.7.0"
  end

  appraise "mongo_mapper-0.7.5" do
    gem "activesupport", "2.3.11"
    gem "mongo_mapper", "0.7.5"
  end

  appraise "mongo_mapper-0.8.0" do
    gem "activesupport", "2.3.11"
    gem "mongo", "1.0.1"
    gem "plucky", "0.3.0"
    gem "mongo_mapper", "0.8.0"
  end

  appraise "mongo_mapper-0.8.3" do
    gem "activesupport", "2.3.11"
    gem "mongo", "1.0.1"
    gem "plucky", "0.3.3"
    gem "mongo_mapper", "0.8.3"
  end

  appraise "mongo_mapper-0.8.4" do
    gem "activesupport", "2.3.11"
    gem "mongo_mapper", "0.8.4"
  end

  appraise "mongo_mapper-0.8.6" do
    gem "activesupport", "2.3.11"
    gem "mongo_mapper", "0.8.6"
  end

  appraise "mongo_mapper-0.9.0" do
    gem "mongo_mapper", "0.9.0"
  end
end
  
# Mongoid integrations
if RUBY_VERSION > "1.8.6"
  appraise "mongoid-2.0.0" do
    gem "mongoid", "2.0.0"
  end
  
  appraise "mongoid-2.1.4" do
    gem "mongoid", "2.1.4"
  end
end

# Sequel integrations
appraise "sequel-2.8.0" do
  gem "sqlite3-ruby"
  gem "sequel", "2.8.0"
end

appraise "sequel-2.11.0" do
  gem "sqlite3-ruby"
  gem "sequel", "2.11.0"
end

appraise "sequel-2.12.0" do
  gem "sqlite3-ruby"
  gem "sequel", "2.12.0"
end

appraise "sequel-3.0.0" do
  gem "sqlite3-ruby"
  gem "sequel", "3.0.0"
end

appraise "sequel-3.13.0" do
  gem "sqlite3-ruby"
  gem "sequel", "3.13.0"
end

appraise "sequel-3.14.0" do
  gem "sqlite3-ruby"
  gem "sequel", "3.14.0"
end

appraise "sequel-3.26.0" do
  gem "sqlite3-ruby"
  gem "sequel", "3.26.0"
end

# DataMapper
if RUBY_VERSION < "1.9.1"
  appraise "data_mapper-0.9.4" do
    gem "dm-core", "0.9.4"
    gem "dm-migrations", "0.9.4"
    gem "dm-validations", "0.9.4"
    gem "dm-observer", "0.9.4"
    gem "data_objects", "0.9.4"
    gem "do_sqlite3", "0.9.4"
  end

  appraise "data_mapper-0.9.7" do
    gem "dm-core", "0.9.7"
    gem "dm-migrations", "0.9.7"
    gem "dm-validations", "0.9.7"
    gem "dm-observer", "0.9.7"
    gem "data_objects", "0.9.7"
    gem "do_sqlite3", "0.9.7"
  end

  appraise "data_mapper-0.9.11" do
    gem "dm-core", "0.9.11"
    gem "dm-migrations", "0.9.11"
    gem "dm-validations", "0.9.11"
    gem "dm-observer", "0.9.11"
    gem "data_objects", "0.9.11"
    gem "do_sqlite3", "0.9.11"
  end

  appraise "data_mapper-0.10.2" do
    gem "dm-core", "0.10.2"
    gem "dm-migrations", "0.10.2"
    gem "dm-validations", "0.10.2"
    gem "dm-observer", "0.10.2"
    gem "data_objects", "0.10.2"
    gem "do_sqlite3", "0.10.2"
  end

  appraise "data_mapper-0.10.2" do
    gem "dm-core", "0.10.2"
    gem "dm-migrations", "0.10.2"
    gem "dm-validations", "0.10.2"
    gem "dm-observer", "0.10.2"
    gem "data_objects", "0.10.2"
    gem "do_sqlite3", "0.10.2"
  end
end

appraise "data_mapper-1.0.0" do
  gem "dm-core", "1.0.0"
  gem "dm-migrations", "1.0.0"
  gem "dm-validations", "1.0.0"
  gem "dm-observer", "1.0.0"
  gem "dm-transactions", "1.0.0"
  gem "dm-sqlite-adapter", "1.0.0"
end

appraise "data_mapper-1.0.1" do
  gem "dm-core", "1.0.1"
  gem "dm-migrations", "1.0.1"
  gem "dm-validations", "1.0.1"
  gem "dm-observer", "1.0.1"
  gem "dm-transactions", "1.0.1"
  gem "dm-sqlite-adapter", "1.0.1"
end

appraise "data_mapper-1.0.2" do
  gem "dm-core", "1.0.2"
  gem "dm-migrations", "1.0.2"
  gem "dm-validations", "1.0.2"
  gem "dm-observer", "1.0.2"
  gem "dm-transactions", "1.0.2"
  gem "dm-sqlite-adapter", "1.0.2"
end

appraise "data_mapper-1.1.0" do
  gem "dm-core", "1.1.0"
  gem "dm-migrations", "1.1.0"
  gem "dm-validations", "1.1.0"
  gem "dm-observer", "1.1.0"
  gem "dm-transactions", "1.1.0"
  gem "dm-sqlite-adapter", "1.1.0"
end
