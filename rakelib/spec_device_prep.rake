desc 'Prepare spec/fixtures/device.conf to use the current path'
task :spec_device_prep do
  contents = File.readlines 'spec/fixtures/_device.conf'
  contents.map!{|x| x.sub('PREFIX',Dir.pwd)}
  contents.reject!{|x| x =~ /^#.*\bsed/ }
  File.open('spec/fixtures/device.conf','w'){|f| f.puts contents }
  puts "Wrote file '#{File.expand_path('spec/fixtures/device.conf')}' to match current path"
end
