#!/usr/bin/env ruby

def without_warnings
  original_verbosity = $VERBOSE
  $VERBOSE = nil
  result = yield
  $VERBOSE = original_verbosity
  result
end

Dir.chdir(File.join(__dir__, '..'))
readme = File.read('README.md')
# hide `warning: Insecure world writable dir {extra-container-src-dir}`
usage = without_warnings { `extra-container`.sub(/\A.*?Usage:\s*/m, '') }
updated = readme.sub(/(?<=^## Usage\n```\n).*?(?=^```)/m, usage)
current = File.read('README.md')
if current != updated
  File.write('README.md', updated)
  puts "Updated README.md"
end
