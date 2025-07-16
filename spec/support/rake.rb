require 'rake'

RSpec.shared_context 'rake', :shared_context => :metadata do
  let(:rake)      { Rake::Application.new }
  let(:task_name) { self.class.top_level_description }
  subject         { rake[task_name] }

  before do
    Rake.application = rake
    load File.join(Rails.root, 'Rakefile')
  end
end